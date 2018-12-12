#!/bin/bash

usage='Usage:
This Bash script should be put in the same folder of the executed file.
[-f] File to be run.
[-h] Display usage.'

while getopts "f:h" opt; do
  case ${opt} in
  f) file=$(basename ${OPTARG}) ;;
  h) echo "${usage}" ;;
  esac
done

if [[ -z "${file}" ]]; then
  echo "${usage}"
  exit
fi

dir=$(pwd)
if [[ -e "${dir}/${file}" ]]; then
  echo "Start!"
  fname=$(echo "${file}" | cut -d "." -f 1)
  lnum=$(cat ${file} | wc -l)
  l=2
  echo -e "Scientific_name\tScientific_name_ori\tEnglish_name" >>${dir}/${fname}.update
  while [[ "${l}" -le "${lnum}" ]]; do
    line=$(cat ${file} | sed -n "${l}p")
    # Form the search key
    search_key=$(echo "${line}" | cut -d $'\t' -f 2)
    wiki_key=$(echo "${search_key} Wikipedia")
    birdlife_key=$(echo "${search_key} BirdLife")

    # Searching online
    SciName_wiki=$(googler -n 2 -C --np ${wiki_key} | grep "(" | cut -d ')' -f 1 | sed -n "1p" | cut -d '(' -f 2)
    SciName_birdlife=$(googler -n 3 -C --np ${birdlife_key} | grep "BirdLife" | grep "(" | cut -d ')' -f 1 | sed -n "1p" | cut -d '(' -f 2)

    # Trust order of resources:1.BirdLife International. 2.Wikipedia
    if [[ "${SciName_wiki}" != "${SciName_birdlife}" ]]; then
      update_Name=${SciName_birdlife}
    else
      update_Name=${SciName_wiki}
    fi

    if [[ ! -z "${update_Name}" ]]; then
      echo -e "${update_Name}\t${line}" >>${dir}/${fname}.update
    else
      echo -e "NA\t${line}" >>${dir}/${fname}.update
    fi
    ((l++))
  done
else
  echo "File does NOT exist."
  exit
fi
