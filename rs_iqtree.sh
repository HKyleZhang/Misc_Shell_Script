#!/bin/bash

usage='
[-a] alignment folder.
[-h] display usage.
[-i] IQ-Tree output folder.
[-m] model file.
[-n] null hypothetical topological set.
[-o] outgroup for rooting trees.'

# R code. Root phylogenetic trees with ape R package
RooTree='
suppressPackageStartupMessages(library(ape))
suppressPackageStartupMessages(library(phylogram))

iqtrees <- read.tree("IQ-TREE_FILE")
iqtrees <- root.multiPhylo(iqtrees, "OUTGROUP", resolve.root = T)

for (i in 1:length(iqtrees)) {
  iqtrees[[i]] <-
    as.phylo.dendrogram(as.cladogram(as.dendrogram.phylo(iqtrees[[i]])))
}

write.tree(iqtrees, "IQ-trees.nw", tree.names = TRUE, digits = 0)'

while getopts "a:hi:m:n:o:" opt; do
    case ${opt} in
    a) aln_folder=$(echo "${OPTARG}" | sed "s/\///") ;;
    h) echo "${usage}" && exit ;;
    i) iqtree_output=$(echo "${OPTARG}" | sed "s/\///") ;;
    m) model_file=${OPTARG} ;;
    n) null_topo=${OPTARG} ;;
    o) og=${OPTARG} ;;
    esac
done

dir=$(pwd)

# Root and extract topology of the best ML trees
cd ${dir}/${iqtree_output}/
RooTree_mod=$(echo "${RooTree}" | sed "s/IQ-TREE_FILE/${aln_folder}.treefile/" | sed "s/OUTGROUP/${og}/")
Rscript <(echo "${RooTree_mod}")
sed -i "s/:[[:digit:]]\+//g" ${dir}/${iqtree_output}/IQ-trees.nw
mv ${dir}/${iqtree_output}/IQ-trees.nw ${dir}
cd ${dir}

t=1
for i in ${dir}/${aln_folder}/*.phy; do
    name=$(basename "${i}")

    model=$(cat ${dir}/${model_file} | grep "${name}" | cut -d ":" -f 1)
    best_topo=$(cat ${dir}/IQ-trees.nw | sed -n "${t}p")
    test_topo=$(cat ${dir}/${null_topo})
    echo -e "${test_topo}\n${best_topo}" >${dir}/topo_set.nw

    iqtree -s ${i} -m ${model} --trees ${dir}/topo_set.nw --test-au -zb 20000 -keep-ident

    rm -f ${dir}/topo_set.nw
    ((t++))
done

mkdir ${dir}/Topo_test
mv ${dir}/${aln_folder}/*.iqtree ${dir}/Topo_test/
rm ${dir}/${aln_folder}/*.bionj \
    ${dir}/${aln_folder}/*.gz \
    ${dir}/${aln_folder}/*.log \
    ${dir}/${aln_folder}/*.mldist \
    ${dir}/${aln_folder}/*.tree*

for i in ${dir}/Topo_test/*; do
    a=$(cat ${i} | grep -A7 "Tree      logL")
    echo -e "$(basename ${i})\n${a}\n\n" >>${dir}/topo_test.summary
done
