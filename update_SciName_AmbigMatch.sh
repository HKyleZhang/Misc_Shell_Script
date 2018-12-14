#!/bin/bash

ambiguous_match() {
  w1=${1}
  w2=${2}

  alphabet="abcdefghijklmnopqrstuvwxyz"

  i=1
  Mis=0
  while [[ "${i}" -le 26 ]]; do
    Letter=$(echo "${alphabet}" | cut -c "${i}")
    L1=$(echo "${w1}" | grep -oi "${Letter}" | wc -l)
    L2=$(echo "${w2}" | grep -oi "${Letter}" | wc -l)
    if [[ "${L1}" != "${L2}" ]]; then
      Mis=1
      break 1
    fi
    ((i++))
  done

  if [[ "${Mis}" -eq 0 ]]; then
    export Ambig_logic="TRUE"
  else
    export Ambig_logic="FALSE"
  fi
}

usage='Usage:
This Bash script should be put in the same folder of the executed file.
[-a] File to be matched against. Column1:English name. Column2:Scientific name.
[-b] File to be updated.         Column1:Scientific name. Column2:English name.
[-s] Single-end match.
[-p] Paired-end match.
[-h] Display usage.'

while getopts "a:b:sph" opt; do
  case ${opt} in
  a) bgfile=$(basename ${OPTARG}) ;;
  b) updfile=$(basename ${OPTARG}) ;;
  s) method=2 ;;
  p) method=3 ;;
  h) echo "${usage}" ;;
  esac
done

if [[ -z "${bgfile}" ]] || [[ -z "${updfile}" ]]; then
  echo "${usage}"
  exit
fi

if [[ -z "${method}" ]]; then
  method=1
fi

dir=$(pwd)
if [[ -e "${bgfile}" ]] && [[ -e "${updfile}" ]]; then
  echo "Start!"
  bgfile_name=$(echo "${bgfile}" | cut -d "." -f 1)
  updfile_name=$(echo "${updfile}" | cut -d "." -f 1)

  updlnum=$(cat ${updfile} | wc -l)

  # 1. Greedy searching
  if [[ "${method}" -eq 1 ]]; then
    bglnum=$(cat ${bgfile} | wc -l)

    count=0
    j=2
    while [[ "${j}" -le "${updlnum}" ]]; do
      updfile_sp=$(cat ${updfile} | sed -n "${j}p" | cut -d $'\t' -f 2)
      k=2
      while [[ "${k}" -le "${bglnum}" ]]; do
        bgfile_sp=$(cat ${bgfile} | sed -n "${k}p" | cut -d $'\t' -f 1)

        len1=$(echo "${#bgfile_sp}")
        len2=$(echo "${#updfile_sp}")

        if [[ "${len1}" -le "${len2}" ]]; then
          diff=$((len2 - len1))
        else
          diff=$((len1 - len2))
        fi

        if [[ "${diff}" -le 1 ]]; then
          ambiguous_match "${updfile_sp}" "${bgfile_sp}"
          if [[ "${Ambig_logic}" == "TRUE" ]]; then
            bgline=$(cat ${bgfile} | sed -n "${k}p" | cut -d $'\t' -f 2)
            updline=$(cat ${updfile} | sed -n "${j}p")
            echo -e "${bgline}\t${updline}" >>${dir}/${updfile_name}_updated.txt
            ((count++))
            break
          fi
        fi
        ((k++))
      done
      if [[ "${k}" -ge "${bglnum}" ]]; then
        updline=$(cat ${updfile} | sed -n "${j}p")
        echo -e "NA\t${updline}" >>${dir}/${updfile_name}_updated.txt
      fi
      echo -e "Completed ${count} species."
      ((j++))
    done

    # 2. Single-end of 3 digits searching
  elif [[ "${method}" -eq 2 ]]; then
    j=2
    while [[ "${j}" -le "${updlnum}" ]]; do
      updfile_sp=$(cat ${updfile} | sed -n "${j}p" | cut -d $'\t' -f 2)
      key=$(echo "${updfile_sp}" | cut -c 1-3)
      cat ${bgfile} | grep "${key}" >${dir}/.${bgfile_name}.temp
      bglnum=$(cat ${dir}/.${bgfile_name}.temp | wc -l)
      na="TRUE"
      k=1
      while [[ "${k}" -le "${bglnum}" ]]; do
        bgfile_sp=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${k}p" | cut -d $'\t' -f 1)

        len1=$(echo "${#bgfile_sp}")
        len2=$(echo "${#updfile_sp}")

        if [[ "${len1}" -le "${len2}" ]]; then
          diff=$((len2 - len1))
        else
          diff=$((len1 - len2))
        fi
        if [[ "${diff}" -le 3 ]]; then
          ambiguous_match "${updfile_sp}" "${bgfile_sp}"
          if [[ "${Ambig_logic}" == "TRUE" ]]; then
            bgline=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${k}p" | cut -d $'\t' -f 2)
            updline=$(cat ${updfile} | sed -n "${j}p")
            echo -e "${bgline}\t${updline}" >>${dir}/${updfile_name}_updated.txt
            na="FALSE"
            break 1
          fi
        fi
        ((k++))
      done
      rm -f ${dir}/.${bgfile_name}.temp
      if [[ "${na}" == "TRUE" ]]; then
        updline=$(cat ${updfile} | sed -n "${j}p")
        echo -e "NA\t${updline}" >>${dir}/${updfile_name}_updated.txt
      fi
      count=$((j - 1))
      echo -e "Completed ${count} species."
      ((j++))
    done

    # 3. Paired-end of 4 digits searching
  elif [[ "${method}" -eq 3 ]]; then
    j=2
    while [[ "${j}" -le "${updlnum}" ]]; do
      ## Update attempt using English name as key
      updfile_engsp=$(cat ${updfile} | sed -n "${j}p" | cut -d $'\t' -f 2)
      engkey1=$(echo "${updfile_engsp}" | cut -c 1-2)
      engkey2=$(echo "${updfile_engsp}" | rev | cut -c 1-2 | rev)

      cat ${bgfile} | grep "${engkey1}" | grep "${engkey2}"$'\t' >${dir}/.${bgfile_name}.temp
      bglnum=$(cat ${dir}/.${bgfile_name}.temp | wc -l)
      engna="TRUE"
      engk=1
      while [[ "${engk}" -le "${bglnum}" ]]; do
        bgfile_engsp=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${engk}p" | cut -d $'\t' -f 1)
        ambiguous_match "${updfile_engsp}" "${bgfile_engsp}"
        if [[ "${Ambig_logic}" == "TRUE" ]]; then
          bgline=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${engk}p" | cut -d $'\t' -f 2)
          updline=$(cat ${updfile} | sed -n "${j}p")
          echo -e "${bgline}\t${updline}" >>${dir}/${updfile_name}_updated.txt
          engna="FALSE"
          break 1
        fi
        ((engk++))
      done
      rm -f ${dir}/.${bgfile_name}.temp

      ## Update attempt using Scientific name as key
      if [[ "${engna}" == "TRUE" ]]; then
        updfile_scisp=$(cat ${updfile} | sed -n "${j}p" | cut -d $'\t' -f 1)
        scikey1=$(echo "${updfile_scisp}" | cut -c 1-2)
        scikey2=$(echo "${updfile_scisp}" | rev | cut -c 1-2 | rev)

        cat ${bgfile} | grep "${scikey1}" | grep "${scikey2}"'$' >${dir}/.${bgfile_name}.temp
        bglnum=$(cat ${dir}/.${bgfile_name}.temp | wc -l)
        scina="TRUE"
        scik=1
        while [[ "${scik}" -le "${bglnum}" ]]; do
          bgfile_scisp=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${scik}p" | cut -d $'\t' -f 2)
          ambiguous_match "${updfile_scisp}" "${bgfile_scisp}"
          if [[ "${Ambig_logic}" == "TRUE" ]]; then
            bgline=$(cat ${dir}/.${bgfile_name}.temp | sed -n "${scik}p" | cut -d $'\t' -f 2)
            updline=$(cat ${updfile} | sed -n "${j}p")
            echo -e "${bgline}\t${updline}" >>${dir}/${updfile_name}_updated.txt
            scina="FALSE"
            break 1
          fi
          ((scik++))
        done
        rm -f ${dir}/.${bgfile_name}.temp
      fi

      if [[ "${engna}" == "TRUE" ]] && [[ "${scina}" == "TRUE" ]]; then
        updline=$(cat ${updfile} | sed -n "${j}p")
        echo -e "NA\t${updline}" >>${dir}/${updfile_name}_updated.txt
      fi

      count=$((j - 1))
      echo -e "Completed No.${count} species: ${updfile_engsp}"
      ((j++))
    done
  fi
  echo -e "\nCongrats!Job done!"
fi
