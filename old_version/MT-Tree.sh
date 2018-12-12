#!/bin/bash

echo "
**********************************************************
*                                                        *
*                     WELCOME USE!                       *
*                                                        *
**********************************************************"

read -p "
>>>>Please select a workflow:

    1.ModelTest-NG -> Phyml
    2.ModelTest-NG -> RAxMl-NG
    3.ModelTest-NG

Choose(1, 2, or 3): " wkfl

if [ "${wkfl}" != 1 ]; then
  if [ "${wkfl}" != 2 ]; then
    if [ "${wkfl}" != 3 ]; then
       wkfl="0"
    fi
  fi
fi

if [ "${wkfl}" != 0 ]; then

#Model Selection
for file in *
do
  filetype=$(echo "${file}" | cut -d "." -f 2)
  if [ "${filetype}" = "phy" ]; then
     MTname=$(echo "${file}" | cut -d "." -f 1)
     modeltest-ng -i ${file} -t ml -o ${MTname} -p 4 -f ef -h uigf -s 11 
  fi
done

#Output sorting
rm -rf ../MTresult
mkdir ../MTresult
mkdir ../MTresult/log ../MTresult/tree ../MTresult/topos ../MTresult/ckp
mv ./*log ../MTresult/log/
mv ./*tree ../MTresult/tree/
mv ./*ckp ../MTresult/ckp/
mv ./*topos ../MTresult/topos/
mv ./*out ../MTresult/

#Tree Construction

if [ ${wkfl} -eq 1 ]; then
##Using Phyml
read -p "

>>>>Bootstrapping?(y/n):(Answer Default:n) " support #Define the method for branch support method.
if [ "${support}" = "y" ]; then 
support="1000"
else
echo "
----------------------------------------------------------

       NOTE:The branch support method would be aLRT

----------------------------------------------------------"
read -p "
>>>>Select other methods? Current method is aBayes.(y/n):(Answer Default:n) " support
  if [ "${support}" = "y" ]; then
  read -p "
>>>>Methods(flag):
Not using aLRT 0
aLRT statistics -1 
Chi2-based parametric branch supports -2
SH-like branch supports -4

Specify the flag of the method:" support
  else
  support="-5"
  fi
fi

 for file in *
 do
   filetype=$(echo "${file}" | cut -d "." -f 2)
  if [ "${filetype}" = "phy" ]; then
   inp0=$(echo "${file}" | cut -d "." -f 1)
   inp=$(echo "${inp0}.out")
   modelsetting0=$(cat ../MTresult/${inp}  | grep "Best model according to AICc" -A31 | grep "phyml" | cut -d " " -f 8-13,16-19)
   modelsetting="${modelsetting0} -b ${support} -s BEST"
   mpirun -n 4 phyml-mpi -i ${file} ${modelsetting}
  fi
 done

##Tree file sorting after phyml
if [ ${support} -eq 1000 ]; then
   rm -rf ../phy-
   mkdir ../phy- ../phy-/stats
   mv ./*_stats* ./*_boot_trees* ../phy-/stats/
   mv ./*tree* ../phy- 
else
   rm -rf ../phy-
   mkdir ../phy- ../phy-/stats
   mv ./*_stats* ../phy-/stats/
   mv ./*tree* ../phy- 
fi

mv ../MTresult ../phy-

echo "
----------< Congratulations! JOB DONE!! >----------
"

elif [ ${wkfl} -eq 2 ]; then
##Using RAxMl-NG
read -p "
>>>>Select Analysis type:
    
    1.Run topology search to find the best-scoring ML tree(default).
    2.Non-parametric boostrapping analysis.
    3.Combined tree search and bootstrapping analysis, bootstrap support values will be plotted onto the best-scoring ML tree.
    4.Compute bipartition support for a given reference tree (e.g., best ML tree) using an existing set of replicate trees.

Choose (1, 2, 3, or 4): " supportindex

if [ ${supportindex} -eq 1 ]; then
  support="--search"
elif [ ${supportindex} -eq 2 ]; then
  read -p "
Specify the number of bootstrapping replicate: " bsnum
  if [ "${bsnum}" != "" ]; then
    support="--bootstrap --bs-trees ${bsnum}"
  else
    support="--bootstrap"
    echo "
----------------------------------------------------------

Message: 100-replicate bootstrapping will be run.

----------------------------------------------------------"
  fi
elif [ ${supportindex} -eq 3 ]; then
  read -p "
Specify the number of bootstrapping replicate: " bsnum
  if [ "${bsnum}" != "" ]; then
    support="--all --bs-trees ${bsnum}"
  else
    support="--all"
    echo "
----------------------------------------------------------

Message: 100-replicate bootstrapping will be run.

----------------------------------------------------------"
  fi
elif [ ${supportindex} -eq 4 ]; then
  read -p "
Specify the reference tree file: " rftree
  read -p "
Specify the file of the set of replicate trees: " rptee
  if [ "${rftree}" != ""]; then
    
    if [ "${rptree}" != ""]; then
      support="--support --tree ${rftree} --bs-trees ${rptree}"
    else
      support="--search"
      supportindex="1"
      echo "
--------------------------ERROR!-------------------------- 

        Message: Only topology search will be run.

----------------------------------------------------------"
    fi

  else
    support="--search"
    supportindex="1"
      echo "
--------------------------ERROR!-------------------------- 

        Message: Only topology search will be run.

----------------------------------------------------------"
  fi
fi
 
for file in *
do
  filetype=$(echo "${file}" | cut -d "." -f 2)
  if [ "${filetype}" = "phy" ]; then
   inp0=$(echo "${file}" | cut -d "." -f 1)
   inp=$(echo "${inp0}.out")
   modelsetting0=$(cat ../MTresult/${inp}  | grep "Best model according to AICc" -A31 | grep "raxml-ng" | cut -d " " -f 7-8 )
   modelsetting="${modelsetting0} ${support} --tree rand{20}"
   mpirun -n 1 raxml-ng-mpi --msa ${file} ${modelsetting}
  fi
done

##File sorting after RAxMl
rm -rf ../rax-
mkdir ../rax- ../rax-/log ../rax-/startTree-ML ../rax-/model 
if [ ${supportindex} -eq 1 ]; then

  mv ./*bestModel ../rax-/model/
  mv ./*bestTree ../rax-/
  mv ./*log ../rax-/log/
  mv ./*mlTrees ./*startTree ../rax-/startTree-ML/
  mv ../MTresult ../rax-/

elif [ ${supportindex} -eq 2 ]; then
  mv ./*bootstraps ../rax-/
  mv ./*log ../rax-/log/
  mv ./*startTree ../rax-/startTree-ML/
  mv ../MTresult ../rax-/

elif [ ${supportindex} -eq 3 ]; then
  mkdir ../rax-/bs-file ../rax-/bestTree 
  mv ./*bestModel ../rax-/model/
  mv ./*bestTree ../rax-/bestTree/
  mv ./*bootstraps ../rax-/bs-file/
  mv ./*log ../rax-/log/
  mv ./*mlTrees ./*startTree ../rax-/startTree-ML/
  mv ./*support ../rax-/
  mv ../MTresult ../rax-/

elif [ ${supportindex} -eq 4 ]; then

comment="waiting for programming"

fi

echo "
----------< Congratulations! JOB DONE!! >----------
"

elif [ ${wkfl} -eq 3 ]; then
#Only run model selection
echo "
----------< Congratulations! JOB DONE!! >----------
"
fi

else

echo "
-------------------------ERROR!---------------------------

   Message: Please specify a workflow index in next run.

----------------------------------------------------------"

fi
