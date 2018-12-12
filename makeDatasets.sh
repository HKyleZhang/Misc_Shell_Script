#!/bin/bash

i=$((RANDOM/37 + 1))

read -p "Specify the number of sequences in a single gene file: " taxanum
if [ -z "${taxanum}" ]; then echo -e "\nERROR!!" && exit; fi

echo -e "\nThe generated datasets(100 datasets in total) start from No.${i} dataset." >impMsg.txt
j=$((i + 100))
filenum=1
percent=5
mkdir datasets

until [ $i -eq $j ]; do
  k=$((i + 1))
  startnum=$(cat outfile | grep -n "${taxanum}" | cut -d ":" -f 1 | sed -n "${i}p")
  end=$(cat outfile | grep -n "${taxanum}" | cut -d ":" -f 1 | sed -n "${k}p")
  endnum=$((end - 1))

  if [ $((i % 5)) -eq 0 ] && [ ${filenum} -gt 4 ]; then
    echo "already complete...${percent}%"
    percent=$((percent + 5))
  fi

  cat outfile | sed -n "${startnum},${endnum}p" >./datasets/d${filenum}.phy
  i=$((i + 1))
  filenum=$((filenum + 1))
done

echo "
********* Already complete 100%! **********"
