#!/bin/bash

curdir=$(pwd)
fdname="iqMF-sexgn_1000UFB"

mkdir bs_root

for ufbfile in ${curdir}/${fdname}/bs-file/*; do
  name=$(basename ${ufbfile})
  nw_reroot ${ufbfile} ZF >${curdir}/bs_root/${name}
done

#Recalculation
mkdir ${curdir}/${fdname}_bsrecal/

for file in ${curdir}/${fdname}_rooted/*treefile; do
  name0=$(basename ${file} | cut -d "." -f 1-2)
  name1=$(echo "${name0}.ufboot")
  nw_support ${file} ${curdir}/bs_root/${name1} >${curdir}/${fdname}_bsrecal/${name0}.treefile
done
