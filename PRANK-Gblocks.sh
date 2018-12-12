#~!/bin/bash

curdir=$(pwd)

ls | grep "fasta" >files
parallel -j 4 'prank -d={} -o={}.aln -codon -f=fasta -F' :::: files

rm -rf ../prank/
mkdir ../prank/

mv *aln* ../prank/

rm -rf ../preGb/
mkdir ../preGb/

cd ../prank/
for i in *; do
  name=$(echo "${i}" | cut -d "." -f 1)
  cat ${i} | tr "N" "-" >../preGb/${name}_noN.fasta
done

rm -rf ../postGb/
mkdir ../postGb/ ../postGb/graph

cd ../preGb/
for i in *.fasta; do
  Gblocks $i -t=c -p=y -e=.gb
done

mv *gb ../postGb/
mv *gb* ../postGb/graph

cd ../postGb/
rename 's/_noN.fasta.gb/.fasta/g' *

#cat *.fasta > codeml.phy
