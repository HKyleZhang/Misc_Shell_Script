#!/bin/bash
read -p "Specify the folder of alignment: " alifpre
read -p $'\nSpecify the folder of trees: ' trefpre
curdir=$(pwd)
alif=$(echo "$curdir/$alifpre")
tref=$(echo "$curdir/$trefpre")

rm -rf genes_dir
mkdir genes_dir

for gfile in ${alif}/*; do
  gene=$(echo "${gfile}")
  gnname=$(basename ${gene} | cut -d "." -f 1 | cut -d "-" -f 2)

  mkdir ./genes_dir/${gnname}
  cp -p ${gfile} ${curdir}/genes_dir/${gnname}/
done

for tfile in ${tref}/*; do
  tre=$(echo "${tfile}")
  trename=$(basename ${tre} | cut -d "." -f 1 | cut -d "-" -f 2)
  tremdname="gene.tre"
  cp -p ${tfile} ${curdir}/genes_dir/${trename}/
  cd ${curdir}/genes_dir/${trename}
  mv *treefile ${tremdname}
done
