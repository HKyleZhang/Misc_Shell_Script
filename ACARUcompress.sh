#!/bin/bash

export TAB=$'\t'

usage='Usage:
[-a] Specify the file name.
[-t] Number of threads.
[-h] Display usage.'

# R code 1
subset='library(dplyr)
dd <- read.csv("FILE_TO_BE_SUBSET")

DNA_column <- c(12,13,14,19,23)
DNA_subset <- dd[dd$Sample.type == "Extracted DNA", DNA_column]
DNA_subset$ID <- paste(DNA_subset$Ind, DNA_subset$Year, sep="_")
DNA_subset$Rack_newDNA_western <- as.numeric(as.roman(toupper(DNA_subset$Rack_newDNA)))
DNA_subset$Rack_Box <- paste(DNA_subset$Rack_newDNA_western, DNA_subset$Box_newDNA, sep="_")
DNA_subset <- DNA_subset[,c(8,3,6)]
write.table(DNA_subset, "DNA_DIRECTORY/DNA.subset", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")

Blood_column <- c(8,9,10,19,23)
Blood_subset <- dd[(dd$Sample.type == "Blood sample" | dd$Missing.from.box. == "Missing"), Blood_column]
Blood_subset$ID <- paste(Blood_subset$Ind, Blood_subset$Year, sep="_")
Blood_subset$Rack_newBlood_western <- as.numeric(as.roman(toupper(Blood_subset$Rack_newBlood)))
Blood_subset$Rack_Box <- paste(Blood_subset$Rack_newBlood_western, Blood_subset$Box_newBlood, sep="_")
Blood_subset <- Blood_subset[,c(8,3,6)]
write.table(Blood_subset, "BLOOD_DIRECTORY/Blood.subset", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")

newdd <- Blood_subset %>% full_join(DNA_subset, by = "ID")
write.table(newdd, "Full_join.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
write.csv(newdd, "Full_join.csv", row.names = FALSE)'

# Function 1
number_format() {
  if [[ "${1}" -lt 10 ]]; then
    echo "0${1}"
  else
    echo "${1}"
  fi
}
export -f number_format

# Function 2
parser() {
  line=${1}
  rack=$(echo "${line}" | cut -d "_" -f 1)
  rack=$(number_format ${rack})
  box=$(echo "${line}" | cut -d $'\t' -f 1 | cut -d "_" -f 2)
  box=$(number_format ${box})
  position=$(echo "${line}" | cut -d $'\t' -f 3)
  ID=$(echo "${line}" | cut -d $'\t' -f 4)
  echo -e "${position}\t${ID}" >>${2}/${rack}_${box}
}
export -f parser

display_usage=0
while getopts "a:t:h" opt; do
  case ${opt} in
  a) input=${OPTARG} ;;
  t) thread=${OPTARG} ;;
  h) display_usage=1 ;;
  esac
done

# Check if the specified file exist
if [[ "${display_usage}" -eq 1 ]]; then
  echo "${usage}"
  exit
else
  if [[ -z "${input}" ]]; then
    echo -e "Message: Please specify the file"
    exit
  else
    input_file=$(basename "${input}")
    export dir=$(dirname "${input}")
    if [[ ! -e "${dir}/${input_file}" ]]; then
      echo -e "Message: The file does NOT exist!\nNothing will be run."
      exit
    fi
  fi
fi

# If number of thread isn't specified
# detect the number of processors
if [[ -z "${thread}" ]]; then
  thread=$(nproc --all)
fi

# 1. Subset the dataset
sed_file=$(echo "${dir}/${input_file}")
subset_temp=$(echo "${subset}" |
  sed "s/FILE_TO_BE_SUBSET/${sed_file//\//\\/}/" |
  sed "s/DNA_DIRECTORY/${dir//\//\\/}/" |
  sed "s/BLOOD_DIRECTORY/${dir//\//\\/}/")
Rscript <(echo "${subset_temp}")

rm -rf ${dir}/Blood_subset
mkdir ${dir}/Blood_subset
parallel --no-notice -j ${thread} parser :::: ${dir}/Blood.subset ::: ${dir}/Blood_subset

rm -rf ${dir}/DNA_subset
mkdir ${dir}/DNA_subset
parallel --no-notice -j ${thread} parser :::: ${dir}/DNA.subset ::: ${dir}/DNA_subset

rm -f ${dir}/Blood.subset ${dir}/DNA.subset

# 2. Calculate the minimal rows
echo -e "Rack_Box\tNo.Blood\tNo.DNA\tMin.No.Samples\tNo.Mirrored_samples\tNo.Mirrored_samples_in_mirrored_box\tMinimal_row\tResidual_samples" >>${dir}/summary
for r in {1..10}; do
  for b in {1..12}; do
    r_b=$(echo "${r}_${b}")
    output_rack_box=$(echo "$(number_format ${r})_$(number_format ${b})")

    Blood_l=0
    if [[ -e "${dir}/Blood_subset/${output_rack_box}" ]]; then
      Blood_l=$(cat ${dir}/Blood_subset/${output_rack_box} | wc -l)
    else
      Blood_l=0
    fi

    DNA_fname=$(echo "1${r}_$(number_format ${b})")
    DNA_l=0
    if [[ -e "${dir}/DNA_subset/${DNA_fname}" ]]; then
      DNA_l=$(cat ${dir}/DNA_subset/${DNA_fname} | wc -l)
    else
      DNA_l=0
    fi

    Min_samples=0
    Mir_samples=0
    Mir_samples_in_mir_box=0
    if [[ -n "$(cat ${dir}/Full_join.txt | grep "^${r_b}${TAB}")" ]] || [[ -n "$(cat ${dir}/Full_join.txt | grep "${TAB}1${r_b}${TAB}")" ]]; then
      Min_samples=$(cat ${dir}/Full_join.txt | egrep "^${r_b}${TAB}|^NA${TAB}" | egrep -c "^${r_b}${TAB}|${TAB}1${r_b}${TAB}")
      Mir_samples=$(cat ${dir}/Full_join.txt | grep "^${r_b}${TAB}" | grep -cv "${TAB}NA${TAB}")
      Mir_samples_in_mir_box=$(cat ${dir}/Full_join.txt | grep "^${r_b}${TAB}" | grep -c "${TAB}1${r_b}${TAB}")
    fi

    Residual_samples=$((Min_samples % 9))
    if [[ "${Residual_samples}" -gt 0 ]]; then
      Min_row=$((Min_samples / 9 + 1))
    else
      Min_row=$((Min_samples / 9))
    fi

    echo -e "${output_rack_box}\t${Blood_l}\t${DNA_l}\t${Min_samples}\t${Mir_samples}\t${Mir_samples_in_mir_box}\t${Min_row}\t${Residual_samples}" >>${dir}/summary
  done
done
Rscript -e 'dd <- read.table("summary", header = T); write.csv(dd, "summary.csv", row.names = FALSE)'

lnum=$(cat ${dir}/Full_join.txt | wc -l)
i=1
while [[ "${i}" -le "${lnum}" ]]; do
  line=$(cat ${dir}/Full_join.txt | sed -n "${i}p")
  year=$(echo "${line}" | cut -d $'\t' -f 3 | cut -d "_" -f 2)
  echo -e "${line}\t${year}" >>${dir}/res
  ((i++))
done
