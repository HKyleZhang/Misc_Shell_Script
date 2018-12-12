#!/bin/bash

read -p "Specify the file name containing cluster information: " clfile

if [ -n "${clfile}" ]; then
  op=$(echo "${clfile}_output")

  lnum=$(cat partition | wc -l)
  pi=1
  while [ "${pi}" -le "${lnum}" ]; do
    gnname[$pi]=$(cat partition | sed -n "${pi}p" | cut -d " " -f 1)
    part[$pi]=$(cat partition | sed -n "${pi}p" | cut -d " " -f 3 | cut -d ";" -f 1)
    ((pi++))
  done

  cli=1
  while [ "${cli}" -le "${lnum}" ]; do
    cl[$cli]=$(cat ${clfile} | grep "${gnname[$cli]}" | cut -d " " -f 2)
    ((cli++))
  done

  rm -rf ${op}
  i=1
  k=1
  while [ "${i}" -lt "${lnum}" ]; do
    j=$((i + 1))

    if [ "${cl[$i]}" != "NA" ]; then
      partcon=$(echo "${part[$i]}")
      while [ "${j}" -le "${lnum}" ]; do
        if [ "${cl[$j]}" != "NA" ]; then
          if [ "${cl[$j]}" -eq "${cl[$i]}" ]; then
            partcon=$(echo "${partcon},${part[$j]}")
            cl[$j]="NA"
          fi
        fi

        ((j++))
      done
      if [ "${k}" -lt 10 ]; then
        echo "cluster0${k} = ${partcon}" >>${op}
      else
        echo "cluster${k} = ${partcon}" >>${op}
      fi
      ((k++))
    fi
    ((i++))
  done

  echo -e "\nJob Done!!!\nOutput results have been written to: ${op}"

else

  echo -e "\nERROR!!!\nNo cluster information!"

fi
