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
  mkdir ${dir}/output/

  lnum=$(cat ${file} | wc -l)
  line1=$(cat ${file} | sed -n "1p")
  iter=$(((lnum / 300) + 1))

  end=1
  i=1
  while [[ "${i}" -le "${iter}" ]]; do
    start=$((end + 1))
    end=$((i * 300 + 1))

    if [[ "${start}" -lt "${lnum}" ]] && [[ "${end}" -le "${lnum}" ]]; then
      cat ${file} | sed -n "${start},${end}p" >>${dir}/output/${fname}${i}.txt
      ((i++))
    else
      cat ${file} | sed -n "${start},${lnum}p" >>${dir}/output/${fname}${i}.txt
      ((i++))
    fi
  done
fi
