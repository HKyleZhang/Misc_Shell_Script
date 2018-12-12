#!/bin/bash
scrutinize() {
  stlen=$(echo "${#2}")
  if [ "${3}" -lt 100 ]; then
    fiend=5
  elif [ "${3}" -lt 1000 ]; then
    fiend=6
  elif [ "${3}" -lt 10000 ]; then
    fiend=7
  fi
  step=$((fiend - 1))
  while [ "${fiend}" -le "${stlen}" ]; do
    fist=$((fiend - step))
    unit=$(echo "${2}" | cut -c ${fist}-${fiend})
    left=$(echo "${unit}" | grep ")")
    right=$(echo "${unit}" | grep ":")
    if [ -n "${left}" ] && [ -n "${right}" ]; then
      unit=$(echo "${unit}" | cut -d ")" -f 2 | cut -d ":" -f 1)
      if [ -n "${unit}" ]; then
        if [ "${unit}" -eq "${unit}" ] 2>/dev/null; then
          if [ "${unit}" -lt "${3}" ]; then
            res="FAIL"
          fi
        fi
      fi
    fi
    ((fiend++))
  done
}

read -p $'**********Welcome!**********\nPlease set the threshold value of significant bootstrapping value:\n1.Default: 70.\n2.Customized value.\nChoose index: ' thva
if [ -z "${thva}" ]; then
  thva=70
else
  if [ "${thva}" -eq "${thva}" ] 2>/dev/null; then
    if [ "${thva}" -eq 1 ]; then
      thva=70
    elif [ "${thva}" -eq 2 ]; then
      read -p $'\nSpecify the value: ' thva
      if [ -z "${thva}" ]; then echo -e "\nERROR!" && exit; fi
    fi
  else
    echo -e "\nERROR!" && exit
  fi
fi

curdir=$(pwd)
lnum=$(cat gnTrees_collection.tre | wc -l)
i=0
while [ "${i}" -lt "${lnum}" ]; do
  ((i++))

  if [ $((i % 7)) -eq 0 ]; then echo -e "Processing..."; fi

  sentence=$(cat gnTrees_collection.tre | sed -n "${i}p")
  name=$(echo "${sentence}" | cut -d " " -f 1)
  res="PASS"
  scrutinize ${sentence} ${thva}
  if [ "${res}" = "FAIL" ]; then
    echo "${sentence}" >>${curdir}/output_list
  fi
done

if [ -e output_list ]; then
  echo -e "\n**********Finished!**********\nMsg:The results has been written to output_list."
else
  echo -e "\nMsg:No untrustworthy tree is found."
fi
