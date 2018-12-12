#!/bin/bash

curdir=$(pwd)
rm -rf Chr_cluster.summary
f=$(ls | grep '.cl')
k=$(echo "${f}" | cut -d "." -f 1 | cut -d "k" -f 2 | cut -d "0" -f 2)

i=1
while [ "${i}" -le "${k}" ]; do
  A[$i]=0
  W[$i]=0
  Z[$i]=0
  ((i++))
done

while read line; do
  gene=$(echo "${line}" | cut -d " " -f 1)
  prefix=$(echo "${gene}" | cut -c 1-2)
  suffix=$(echo "${gene}" | cut -d "_" -f 2)

  clust=$(echo "${line}" | cut -d " " -f 2)
  i=1
  while [ "${i}" -le "${k}" ]; do
    if [ "${clust}" -eq "${i}" ]; then
      if [ "${#suffix}" -gt 1 ]; then
        ((A[$i]++))
      elif [ "${suffix}" == "W" ]; then
        ((W[$i]++))
      elif [ "${suffix}" == "Z" ]; then
        ((Z[$i]++))
      fi
    fi
    ((i++))
  done
done <${curdir}/${f}

touch Chr_cluster.summary
echo "Chr_type Autosome Z W" >Chr_cluster.summary

i=1
while [ "${i}" -le "${k}" ]; do
  echo "Cluster${i} ${A[$i]} ${Z[$i]} ${W[$i]}" >>Chr_cluster.summary
  ((i++))
done
