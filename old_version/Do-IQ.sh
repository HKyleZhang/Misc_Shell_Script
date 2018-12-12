#!/bin/bash

read -p "
Use IQ-Tree to do model test and tree construction for current folder? (y/n): " answer

if [ "${answer}" = "y" ]; then
  read -p "
Run Bootstrapping? (y/n): " bs
  if [ "${bs}" = "y" ]; then
    read -p "
Specify the number of bootstrapping replicate (default is 100): " bsnum
    if [ "${bsnum}" = "" ]; then 
       bsnum="100" 
    fi
    
    read -p "
Select: 1.Ultra Fast Bootstrapping; 2.Non-parametric Bootstrapping  " bsmethod
    if [ "${bsmethod}" = 1 ]; then
       bsset="-bb ${bsnum} -bnni -wbtl"
    elif [ "${bsmethod}" = 2 ]; then
       bsset="-b ${bsnum} -wbtl"
    else
       bsset=""
    fi
  else
    bsset=""
  fi
  
  for file in *
  do
    filetype=$(echo "${file}" | cut -d "." -f 2)
    if [ "${filetype}" = "phy" ]; then
      iqtree -s ${file} -t RANDOM -o ZF -nt AUTO -keep-ident -AICc ${bsset}
    fi
  done
#File sorting
rm -rf ../iq-
mkdir ../iq- ../iq-/report ../iq-/bs-file ../iq-/trivia
mv ./*iqtree ../iq-/report/
mv ./*treefile ../iq-/
mv ./*contree ./*log ./*gz ../iq-/trivia
if [ "${bsmethod}" = 1 ]; then
  mkdir ../iq-/splitSupport
  mv ./*splits* ../iq-/splitSupport
  mv ./*ufboot ../iq-/bs-file
elif [ "${bsmethod}" = 2 ]; then
  mv ./*boottrees ../iq-/bs-file
fi
echo "
+---------+ Finished! +---------+"

else
echo "
+---------+ Bye! +---------+"
fi
