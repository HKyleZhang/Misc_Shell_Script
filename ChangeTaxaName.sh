#!/bin/bash

#Erasing anything else but only keeping taxa name

for file in ../alignment_raw/*; do
  name=$(grep "^>" ${file} | cut -d ">" -f 2 | cut -d "_" -f 1 | uniq)
  grep -A1 "^>" ${file} | sed "s/.*_/>/" | sed "s/:.*//" >${name}.fasta
done
