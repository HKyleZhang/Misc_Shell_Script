#!/bin/bash

export TAB=$'\t'

# Function 1. Usage
usage="[-f] Specify the folder.
[-y] Guess the year from the last 4 digits of the excel file.
[-s] Only run summarization.
[-h] Display usage."

# Calculate relative days
rel_days() {
  d1=$(date -d "${1}" +%s)
  d2=$(date -d "${2}-04-30" +%s)
  if [[ "$((d1 - d2))" -ge 0 ]]; then
    export rel_result=$(((d1 - d2) / 86400))
  else
    rel_result_temp=$(((d2 - d1) / 86400))
    export rel_result=$(echo "-${rel_result_temp}")
  fi
}

# R code 1. Extract the tables for summarization.
Divide_sheets='ipak <- function(pkg) {
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("rJava", "xlsx", "readxl", "janitor")
ipak(packages)

excel_file <- list.files(pattern = "xlsx")

main_dir <- getwd()

for (i in excel_file) {
  excelfile_name <-
    strsplit(strsplit(i, ".", fixed = TRUE)[[1]][1], "_", fixed = TRUE)[[1]][2]
  sheet_list <- excel_sheets(i)
  for (s in sheet_list) {
    label_local <- strsplit(s, " ", fixed = TRUE)[[1]][1]
    label_nest <- strsplit(s, " ", fixed = TRUE)[[1]][2]
    label_rename <-
      paste(excelfile_name, label_local, label_nest, sep = "_")
    colInd <- 1:17
    sheet_import <- read.xlsx(i, sheetName = s, colIndex = colInd)

    if (grepl("nestC", label_nest) == "FALSE") {
      ## Extract Nest info table
      sub_dir <- paste(excelfile_name, "Nest_info", sep = "_")
      ifelse(!dir.exists(file.path(main_dir, sub_dir)), dir.create(file.path(main_dir, sub_dir)), FALSE)
      ni_output_dir <-
        file.path(main_dir, sub_dir, paste(label_rename, ".info", sep = ""))
      start <-
        which(sheet_import$NEST.FORM..BOBLANKETT. == "Nest ID")
      end <- which(sheet_import$NEST.FORM..BOBLANKETT. == "Nest no")
      nest_info <- sheet_import[start:end, 1:2]
      write.table(
        nest_info,
        ni_output_dir,
        quote = FALSE,
        row.names = FALSE,
        col.names = FALSE,
        sep = "\t"
      )

      ## Extract Nest visit table
      sub_dir <- paste(excelfile_name, "Nest_visit", sep = "_")
      ifelse(!dir.exists(file.path(main_dir, sub_dir)), dir.create(file.path(main_dir, sub_dir)), FALSE)
      nv_output_dir <-
        file.path(main_dir, sub_dir, paste(label_rename, ".nv", sep = ""))
      start <-
        which(sheet_import$NEST.FORM..BOBLANKETT. == "NEST VISITS") + 2
      end <-
        which(sheet_import$NEST.FORM..BOBLANKETT. == "Response") - 3
      nest_visit <- sheet_import[start:end, 1:5]
      for (r in 1:nrow(nest_visit)) {
        isDate <-
          excel_numeric_to_date(as.numeric(as.character(nest_visit[r, 1])))
        if (is.na(isDate) == "FALSE") {
          levels(nest_visit$NEST.FORM..BOBLANKETT.) <-
            gsub(nest_visit[r, 1],
                 isDate,
                 levels(nest_visit$NEST.FORM..BOBLANKETT.))
        } else {
          isSdDate <- as.Date(nest_visit[r, 1], format = "%d/%m/%Y")
          if (is.na(isSdDate) == "FALSE") {
            levels(nest_visit$NEST.FORM..BOBLANKETT.) <-
              gsub(nest_visit[r, 1],
                   isSdDate,
                   levels(nest_visit$NEST.FORM..BOBLANKETT.))
          } else {
            isSdDate <- as.Date(nest_visit[r, 1], format = "%m/%y/%Y")
            if (is.na(isSdDate) == "FALSE") {
              levels(nest_visit$NEST.FORM..BOBLANKETT.) <-
                gsub(nest_visit[r, 1],
                     isSdDate,
                     levels(nest_visit$NEST.FORM..BOBLANKETT.))
            }
          }
        }
      }
      write.table(
        nest_visit,
        nv_output_dir,
        quote = FALSE,
        row.names = FALSE,
        col.names = FALSE,
        sep = "\t"
      )

      ## Extract Ringing table
      sub_dir <- paste(excelfile_name, "Ring_info", sep = "_")
      ifelse(!dir.exists(file.path(main_dir, sub_dir)), dir.create(file.path(main_dir, sub_dir)), FALSE)
      r_output_dir <-
        file.path(main_dir, sub_dir, paste(label_rename, ".ring", sep = ""))
      start <- which(sheet_import$RINGING == "Chick") - 2
      end <- which(sheet_import$RINGING == "Hp1")
      ring <- sheet_import[start:end, 9:16]
      if (is.na(ring[1, 2]) == "FALSE") {
        isDate <-
          excel_numeric_to_date(as.numeric(as.character(ring[1, 2])))
        if (is.na(isDate) == "FALSE") {
          levels(ring$NA..7) <-
            gsub(ring[1, 2],
                 isDate,
                 levels(ring$NA..7))
        } else {
          isSdDate <- as.Date(ring[1, 2], format = "%d/%m/%Y")
          if (is.na(isSdDate) == "FALSE") {
            levels(ring$NA..7) <-
              gsub(ring[1, 2],
                   isSdDate,
                   levels(ring$NA..7))
          } else {
            isSdDate <- as.Date(ring[1, 2], format = "%m/%y/%Y")
            if (is.na(isSdDate) == "FALSE") {
              levels(ring$NA..7) <-
                gsub(ring[1, 2],
                     isSdDate,
                     levels(ring$NA..7))
            }
          }
        }
      }
      write.table(
        ring,
        r_output_dir,
        quote = FALSE,
        row.names = FALSE,
        col.names = FALSE,
        sep = "\t"
      )
    }
  }
}
'

while getopts "a:ysh" opt; do
  case ${opt} in
  a) folder=$(echo "${OPTARG}" | cut -d "/" -f 1) ;;
  y) yyyy_guess="TRUE" ;;
  s) to_sum="TRUE" ;;
  h) echo "${usage}" ;;
  esac
done

dir=$(pwd)
# Check the settings
if [[ -z "${folder}" ]] || [[ -z "${folder}" ]]; then
  echo -e "\n***Message: Please specify the folders correctly."
  exit
elif [[ ! -d "${dir}/${folder}" ]]; then
  echo -e "\n--> Message: The folder does NOT exist."
  exit
fi

# Start
step=0
if [[ "${to_sum}" != "TRUE" ]]; then
  step=$((step + 1))
  echo -e "\n\n${step}. Table extraction\n===================="
  cd ${dir}/${folder}
  Rscript <(echo "${Divide_sheets}")

  step=$((step + 1))
  echo -e "\n\n${step}. Information confirmation\n==========================="

  for f in ${dir}/${folder}/*.xlsx; do
    xname=$(echo "${f}" | cut -d "_" -f 2 | cut -d "." -f 1)

    ### Check the nest information
    for nf in ${dir}/${folder}/${xname}_Nest_info/*.info; do
      nf_name=$(basename ${nf} | cut -d "." -f 1)

      if [[ "${yyyy_guess}" == "TRUE" ]]; then
        Year_guess=$(echo "${xname}" | rev | cut -c 1-4 | rev)
        if [[ "${Year_check}" == "NA" ]] || [[ "${#Year_check}" -gt 4 ]] || [[ "${#Year_check}" -lt 4 ]]; then
          sed -i "s/Year.*/Year${TAB}${Year_guess}/" ${nf}
        fi
      else
        Year_check=$(cat ${nf} | grep "Year" | cut -d $'\t' -f 2)
        yctl=1
        while [[ "${yctl}" -le 1 ]]; do
          if [[ "${Year_check}" == "NA" ]] || [[ "${#Year_check}" -gt 4 ]] || [[ -z "${Year_check}" ]]; then
            echo -e "\nCurrent sheet: ${nf_name}\nYear information is wrong."
            read -p "Please input the correct year: " Year_check
          else
            ((yctl++))
          fi
        done
        sed -i "s/Year.*/Year${TAB}${Year_check}/" ${nf}
      fi

      Male_check=$(cat ${nf} | grep "Male" | cut -d $'\t' -f 2)
      mctl=1
      while [[ "${mctl}" -le 1 ]]; do
        if [[ "${Male_check}" == "NA" ]] || [[ -z "${Male_check}" ]]; then
          echo -e "\nCurrent sheet: ${nf_name}\nMale information is wrong."
          read -p "Please input the correct male information: " Male_check
        else
          ((mctl++))
        fi
      done
      sed -i "s/Male.*/Male${TAB}${Male_check}/" ${nf}

      Female_check=$(cat ${nf} | grep "Female" | cut -d $'\t' -f 2)
      #fctl=1
      #while [[ "${fctl}" -le 1 ]]; do
      if [[ "${Female_check}" == "NA" ]] || [[ -z "${Female_check}" ]]; then
        # 	echo -e "\nCurrent sheet: ${nf_name}\nFemale information is wrong."
        # 	read -p "Please input the correct female information: " Female_check
        # else
        # 	((fctl++))
        sed -i "s/Female.*/Female${TAB}NA/" ${nf}
      fi
      #done
      #sed -i "s/Female.*/Female${TAB}${Female_check}/" ${dir}/${folder}/${xname}_Nest_info/${nf_name}.info
    done

    ## Check the nest visit
    for nv in ${dir}/${folder}/${xname}_Nest_visit/*.nv; do
      nv_name=$(basename ${nv} | cut -d "." -f 1)

      if [[ -z "$(cat ${nv} | cut -d $'\t' -f 1 | grep "NA")" ]]; then
        endline=$(cat ${nv} | cut -d $'\t' -f 1 | wc -l)
      else
        endline=$(($(cat ${nv} | cut -d $'\t' -f 1 | grep -n "NA" | sed -n "1p" | cut -d ":" -f 1) - 1))
      fi

      l=1
      while [[ "${l}" -le "${endline}" ]]; do
        t_info=$(cat ${nv} | sed -n "${l}p" | cut -d $'\t' -f 1)
        echo "${l}: ${t_info}" >>${dir}/${folder}/${xname}_Nest_visit/.${nv_name}.temp
        ((l++))
      done

      ctl=1
      while [[ "${ctl}" -le 1 ]]; do
        echo -e "\nCurrent sheet: ${nv_name}"
        cat ${dir}/${folder}/${xname}_Nest_visit/.${nv_name}.temp
        read -p $'\nSpecify the index number and the content you wish to change into (input format: index:yyyy-mm-dd).\nOtherwise leave it empty: ' t_input
        if [[ -z "$(echo "${t_input}" | grep ":")" ]]; then
          ((ctl++))
        else
          line=$(echo "${t_input}" | cut -d ":" -f 1)
          con=$(echo "${t_input}" | cut -d ":" -f 2)
          sed_con=$(cat ${nv} | sed -n "${line}p" | cut -d $'\t' -f 1)
          sed_con=$(echo "${sed_con//\//\\/}")
          sed -i "s/${sed_con}/${con}/" ${nv}

          read -p "Have anything more to change? (Y/n): " ctl_ans
          if [[ "${ctl_ans}" == "Y" ]] || [[ "${ctl_ans}" == "y" ]]; then
            sed -i "s/${sed_con}/${con}/" ${dir}/${folder}/${xname}_Nest_visit/.${nv_name}.temp
          else
            ((ctl++))
          fi
        fi
      done
    done
  done
  to_sum="TRUE"
fi

if [[ "${to_sum}" == "TRUE" ]]; then
  step=$((step + 1))
  echo -e "\n\n${step}.Summarization\n=============="
  for f in ${dir}/${folder}/*.xlsx; do
    xname=$(echo "${f}" | cut -d "_" -f 2 | cut -d "." -f 1)
    echo -e "Year\tNest\tRing_num\tSiteH\tFem\$\tMal\$\tHatch\tWeiD\tAge\tHour\tMass\tHp1\tAtsuc9\tAtsuc12" >${dir}/${folder}/${xname}.summary

    for rf in ${dir}/${folder}/${xname}_Ring_info/*.ring; do
      rf_name=$(basename ${rf} | cut -d "." -f 1)

      Year_sum=$(cat ${dir}/${folder}/${xname}_Nest_info/${rf_name}.info | grep "Year" | cut -d $'\t' -f 2)
      Nestid_sum=$(cat ${dir}/${folder}/${xname}_Nest_info/${rf_name}.info | grep "Nest ID" | cut -d $'\t' -f 2)
      Siteh_sum=$(cat ${dir}/${folder}/${xname}_Nest_info/${rf_name}.info | grep "Local" | cut -d $'\t' -f 2)
      if [[ "${Siteh_sum}" == "NA" ]]; then
        Siteh_sum=$(echo "${rf_name}" | cut -d "_" -f 2)
      fi
      Fem_sum=$(cat ${dir}/${folder}/${xname}_Nest_info/${rf_name}.info | grep "Female" | cut -d $'\t' -f 2)
      Mal_sum=$(cat ${dir}/${folder}/${xname}_Nest_info/${rf_name}.info | grep "Male" | cut -d $'\t' -f 2)

      chick_num=$((7 - $(cat ${rf} | grep "Ring nr" | grep -o "NA" | wc -l)))
      if [[ "${chick_num}" -eq 0 ]]; then
        Ringnum_sum="NA"
        Weid_sum="NA"
        Hatch_sum="NA"
        Age_sum="NA"
        Atsuc9_sum="NA"
        Atsuc12_sum="NA"

        Hour_sum="NA"
        Mass_sum="NA"
        Hp1_sum="NA"

        echo -e "${Year_sum}\t${Nestid_sum}\t${Ringnum_sum}\t${Siteh_sum}\t${Fem_sum}\t${Mal_sum}\t${Hatch_sum}\t${Weid_sum}\t${Age_sum}\t${Hour_sum}\t${Mass_sum}\t${Hp1_sum}\t${Atsuc9_sum}\t${Atsuc12_sum}" >>${dir}/${folder}/${xname}.summary
      else
        ### Weighing date
        Weid_date=$(cat ${rf} | sed -n "1p" | cut -d $'\t' -f 2)
        if [[ "${Weid_date}" == "NA" ]]; then
          Weid_date=$(cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv | grep -i "ring" | sed -n "1p" | cut -d $'\t' -f 1)
        fi
        Weid_year=$(echo "${Weid_date}" | cut -d "-" -f 1)
        rel_days ${Weid_date} ${Weid_year}
        Weid_sum=${rel_result}

        ### Hatching date
        if [[ -z "$(cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv | grep -i "hatching")" ]]; then
          echo -e "\nCurrent sheet: ${rf_name}"
          cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv
          read -p "Please suggest the hatching date (format: yyyy-mm-dd): " Hatch_date
          if [[ "$(echo "${Hatch_date}" | grep -o "-" | wc -l)" != 2 ]]; then
            Hatch_date="NA"
          else
            Hatch_year=$(echo "${Hatch_date}" | cut -d "-" -f 1)
            rel_days ${Hatch_date} ${Hatch_year}
            Hatch_sum=${rel_result}
          fi
        else
          Hatch_date=$(cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv | grep -i "hatching" | sed -n "1p" | cut -d $'\t' -f 1)
          Hatch_year=$(echo "${Hatch_date}" | cut -d "-" -f 1)
          rel_days ${Hatch_date} ${Hatch_year}
          Hatch_sum=${rel_result}
        fi

        ### Age
        if [[ "${Weid_sum}" != "NA" ]] && [[ "${Hatch_sum}" != "NA" ]]; then
          Age_sum=$((Weid_sum - Hatch_sum + 1))
        fi

        ### Atsuc at day 9 after hatching
        Atsuc9_sum=${chick_num}

        ### Atsuc at day 12 after hatching
        if [[ "${Hatch_sum}" != "NA" ]]; then
          Hatch_s=$(date -d "${Hatch_date}" +%s)
          Atsuc12_s=$((Hatch_s + 11 * 86400))
          Atsuc12_date=$(date -d "@${Atsuc12_s}" +"%Y-%m-%d")
          if [[ -z "$(cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv | grep "${Atsuc12_date}")" ]]; then
            Atsuc12_sum="NA"
          else
            Atsuc12_sum=$(cat ${dir}/${folder}/${xname}_Nest_visit/${rf_name}.nv | grep "${Atsuc12_date}" | cut -d $'\t' -f 3)
            if [[ "${Atsuc12_sum}" == "NA" ]]; then
              Atsuc12_sum="NA"
            fi
          fi
        fi

        ### Hour at the weighing date
        Hour_sum=$(cat ${rf} | grep -i "time" | cut -d $'\t' -f 2)
        if [[ -z "${Hour_sum}" ]] || [[ "${Hour_sum}" == "NA" ]]; then
          Hour_sum="NA"
        fi

        chk=1
        while [[ "${chk}" -le "${chick_num}" ]]; do
          Ringnum_sum=$(cat ${rf} | grep -i "nr" | cut -d $'\t' -f $((chk + 1)))
          Mass_sum=$(cat ${rf} | grep -i "Mass" | cut -d $'\t' -f $((chk + 1)))
          Hp1_sum=$(cat ${rf} | grep -i "Hp1" | cut -d $'\t' -f $((chk + 1)))
          echo -e "${Year_sum}\t${Nestid_sum}\t${Ringnum_sum}\t${Siteh_sum}\t${Fem_sum}\t${Mal_sum}\t${Hatch_sum}\t${Weid_sum}\t${Age_sum}\t${Hour_sum}\t${Mass_sum}\t${Hp1_sum}\t${Atsuc9_sum}\t${Atsuc12_sum}" >>${dir}/${folder}/${xname}.summary
          ((chk++))
        done
      fi
    done
  done

  cd ${dir}/${folder}/
  Rscript -e 'sf <- list.files(pattern = "summary"); for (i in sf) {dd <- read.table(i, header = TRUE, sep = "\t"); name <- strsplit(i, ".", fixed = TRUE)[[1]][1]; name <- paste(name, "_summary.csv", sep = ""); write.csv(dd, name, row.names = FALSE)}'
  #rm -f ${dir}/${folder}/*.summary
fi
