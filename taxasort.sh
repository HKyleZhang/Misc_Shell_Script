#!/bin/bash

read -p "Specify the order of taxa(separate by coma): " order

rm -rf ../fasta_new
mkdir ../fasta_new
for f in *.fasta; do
  txn=$(($(cat ${f} | wc -l) / 2))

  n=1
  until [[ "${n}" -gt "${txn}" ]]; do
    txname=$(echo "${order}" | cut -d "," -f ${n})
    txseq=$(cat ${f} | grep -A1 "${txname}")
    echo "${txseq}" >>../fasta_new/${f}
    ((n++))
  done
done
