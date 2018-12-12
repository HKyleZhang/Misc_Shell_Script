#!/bin/bash

usage='Usage:
This Bash script should be put in the same folder of the executed file.
[-a] File to substitute.
[-b] File to be substituted.
[-h] Display usage.'

while getopts "a:b:h" opt; do
  case ${opt} in
  a) corfile=$(basename ${OPTARG}) ;;
  b) subfile=$(basename ${OPTARG}) ;;
  h) echo "${usage}" ;;
  esac
done

if [[ -z "${corfile}" ]] || [[ -z "${subfile}" ]]; then
  echo "${usage}"
  exit
fi

dir=$(pwd)
if [[ -e "${corfile}" ]] && [[ -e "${subfile}" ]]; then
  i=2
  lnum=$(cat ${corfile} | wc -l)
  while [[ "${i}" -le "${lnum}" ]]; do
    cor_line=$(cat ${corfile} | sed -n "${i}p")
    eng_sp=$(echo "${cor_line}" | cut -d $'\t' -f 3)
    cor_line=$(echo -e "${cor_line}\tCorrected")
    sub_line=$(cat ${subfile} | grep "${eng_sp}")
    sed -i "s/${sub_line}/${cor_line}/" ${subfile}
    ((i++))
  done
fi
