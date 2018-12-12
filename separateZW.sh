#!/bin/bash
curdir=$(pwd)

if [ ! -d "alignment_Z" ]; then mkdir alignment_Z; fi
if [ ! -d "alignment_W" ]; then mkdir alignment_W; fi

for file in *fasta; do
  name=$(echo "${file}" | cut -d "." -f 1)
  zf=$(cat ${file} | grep -A1 "ZF")
  zcoll=$(cat ${file} | grep -A1 ">.*_Z" | sed "s/--//" | sed '/^$/d' | sed "s/_Z//")
  wcoll=$(cat ${file} | grep -A1 ">.*_W" | sed "s/--//" | sed '/^$/d' | sed "s/_W//")
  echo -e "${zf}\n${zcoll}" >${curdir}/alignment_Z/${name}_Z.fasta
  echo -e "${zf}\n${wcoll}" >${curdir}/alignment_W/${name}_W.fasta
done

echo -e "\nJob Done!!!"
