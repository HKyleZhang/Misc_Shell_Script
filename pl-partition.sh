#!/bin/bash

seqpos1=1
seqpos2=2
seqpos3=3
seqt=0

read -p "Specify output file name:" output
if [ -z "${output}" ]; then
  output="partition"
fi

read -p $'Output tempelate:\n1.Nothing.\n2.RAxML\n3.Nexus\nChoose: ' tpli
if [ -z "${tpli}" ]; then
  tpli=1
fi

read -p "Partition of gene or codon? (gene/codon):" answer
if [ "${answer}" = "gene" ]; then

  filenumpre=$(ls | wc -l)
  filenum=$((filenumpre - 1))

  cs=1
  for file in *; do
    name0=$(echo "${file}" | cut -d "." -f 2)

    if [ "${name0}" = "phy" ]; then
      name=$(echo "${file}" | cut -d "." -f 1 | cut -d "-" -f 2)
      seq=$(cat $file | cut -d " " -f 3)
      seqt=$(echo "$((seqt + seq))")
      if [ "${tpli}" -eq 1 ]; then
        echo "${name} = $seqpos1-$seqt;" >>../${output}
      elif [ "${tpli}" -eq 2 ]; then
        echo "DNA, ${name} = $seqpos1-$seqt" >>../${output}
      elif [ "${tpli}" -eq 3 ]; then
        if [ "${cs}" -eq 1 ]; then
          echo -e "#nexus\nbegin sets;\n" >../${output}.nex
        fi
        echo "     charset part${cs} = $seqpos1-$seqt;" >>../${output}.nex
        if [ "${cs}" -eq "${filenum}" ]; then
          echo -e "\nend;" >>../${output}.nex
        fi
      fi
      seqpos1=$(echo "$((seqt + 1))")
      ((cs++))
    fi
  done

elif [ "${answer}" = "codon" ]; then
  echo "************************************************************

Partitioning will be performed for codon 1, 2, 3 separately.

************************************************************"
  filenumpre=$(ls | wc -l)
  filenum=$((filenumpre * 3 - 3))

  cs=1
  for file in *; do
    name0=$(echo "${file}" | cut -d "." -f 2)

    if [ "${name0}" = "phy" ]; then
      name=$(echo "${file}" | cut -d "." -f 1 | cut -d "-" -f 2)
      seq=$(cat $file | cut -d " " -f 3)
      seqt=$(echo "$((seqt + seq))")
      if [ "${tpli}" -eq 1 ]; then
        echo -e "${name}_pos1 = $seqpos1-$seqt\3;\n${name}_pos2 = $seqpos2-$seqt\3;\n${name}_pos3 = $seqpos3-$seqt\3;" >>../${output}
      elif [ "${tpli}" -eq 2 ]; then
        echo -e "DNA, ${name}_pos1 = $seqpos1-$seqt\3\nDNA, ${name}_pos2 = $seqpos2-$seqt\3\nDNA, ${name}_pos3 = $seqpos3-$seqt\3" >>../${output}
      elif [ "${tpli}" -eq 3 ]; then
        if [ "${cs}" -eq 1 ]; then
          echo -e "#nexus\nbegin sets;\n" >../${output}.nex
        fi

        echo "     charset part${cs} = $seqpos1-$seqt\3;" >>../${output}.nex
        ((cs++))
        echo "     charset part${cs} = $seqpos2-$seqt\3;" >>../${output}.nex
        ((cs++))
        echo "     charset part${cs} = $seqpos3-$seqt\3;" >>../${output}.nex

        if [ "${cs}" -eq "${filenum}" ]; then
          echo -e "\nend;" >>../${output}.nex
        fi
        ((cs++))
      fi
      seqpos1=$(echo "$((seqt + 1))")
      seqpos2=$(echo "$((seqpos1 + 1))")
      seqpos3=$(echo "$((seqpos2 + 1))")
    fi
  done
fi
