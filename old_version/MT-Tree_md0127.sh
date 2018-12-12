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
    3.ModelTest-NG -> IQ-Tree
    4.ModelTest-NG
    5.ModelFinder(IQ-Tree) -> IQ-Tree

Choose the number of the workflow: " wkfl

if [ ${wkfl} -gt 5 ]; then
       wkfl="0"
fi

if [ "${wkfl}" -gt 0 ] && [ "${wkfl}" -lt 5 ]; then

#Model Selection using ModelTest-NG
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
fi

#Tree Construction

if [ "${wkfl}" -eq 1 ]; then
##Using Phyml
read -p $'\n\n>>>>Bootstrapping?(y/n):(Answer Default:n) ' support #Define the method for branch support method.
if [ "${support}" = "y" ]; then 
support="1000"
else
echo "
----------------------------------------------------------

       NOTE:The branch support method would be aLRT

----------------------------------------------------------"
read -p $'\n>>>>Select other methods? Current method is aBayes.(y/n):(Answer Default:n) ' support
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

echo -e "\n----------< Congratulations! JOB DONE!! >----------"

elif [ "${wkfl}" -eq 2 ]; then
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
  read -p $'\nSpecify the number of bootstrapping replicate: ' bsnum
  if [ -n "${bsnum}" ]; then
    support="--bootstrap --bs-trees ${bsnum}"
  else
    support="--bootstrap"
    echo "
----------------------------------------------------------

Message: 100-replicate bootstrapping will be run.

----------------------------------------------------------"
  fi
elif [ ${supportindex} -eq 3 ]; then
  read -p $'\nSpecify the number of bootstrapping replicate: ' bsnum
  if [ -n "${bsnum}" ]; then
    support="--all --bs-trees ${bsnum}"
  else
    support="--all"
    echo "
----------------------------------------------------------

Message: 100-replicate bootstrapping will be run.

----------------------------------------------------------"
  fi
elif [ ${supportindex} -eq 4 ]; then
  read -p $'\nSpecify the reference tree file: ' rftree
  read -p $'\nSpecify the file of the set of replicate trees: ' rptee
  if [ -n "${rftree}" ]; then
    
    if [ -n "${rptree}" ]; then
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
   modelsetting0=$(cat ../MTresult/${inp}  | grep "Best model according to AICc" -A31 | grep "raxml-ng" | cut -d " " -f 7-8)
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

echo -e "\n----------< Congratulations! JOB DONE!! >----------"
elif [ "${wkfl}" -eq 3 ] || [ "${wkfl}" -eq 5 ]; then
#Using IQ-Tree
##A series of options defined
read -p "
>>>>Select analysis type:
    1.Tree construction with UFB(Ultra Fast Bootstrapping).
    2.Tree construction with Non-parametric Bootstrapping.
    3.Customized node support setting.
Choose the numder of analysis type: " iqopt

  if [ ${iqopt} -eq 1 ]; then
          
     if read -t 8 -p $'\nSpecify the number of bootstrapping replicate (default is 1000): ' bsnumpre; then 
        bsnum=${bsnumpre}
     else
        bsnum="1000" 
     fi

     if read -t 10 -p $'\nAdd another flag? Please specify: ' addflags; then
        lrttest=$(echo ${addflags} | grep "alrt" | cut -d " " -f 2)
         if [ -n "${lrttest}" ]; then
            if [ ${lrttest} -lt 1000 ]; then 
               addflags="-alrt 1000"
               echo "
--------------------------ERROR!-------------------------- 

        Message: 1000-replicate aLRT will be run.

----------------------------------------------------------"
            fi
         fi
     fi
  
     bsset="-bb ${bsnum} -bnni -wbtl ${addflags}"

  elif [ ${iqopt} -eq 2 ]; then
     
     if read -t 8 -p $'\nSpecify the number of bootstrapping replicate (default is 100): ' bsnumpre; then
        bsnum=${bsnumpre}
     else 
        bsnum="100" 
     fi
     
     if read -t 10 -p $'\nAdd another flag? Please specify: ' addflags; then
        lrttest=$(echo ${addflags} | grep "alrt" | cut -d " " -f 2)
         if [ -n "${lrttest}" ]; then
            if [ ${lrttest} -lt 1000 ]; then 
               addflags="-alrt 1000"
               echo "
--------------------------ERROR!-------------------------- 

        Message: 1000-replicate aLRT will be run.

----------------------------------------------------------"
            fi
         fi
     fi

  bsset="-b ${bsnum} -wbtl ${addflags}"

  elif [ ${iqopt} -eq 3 ]; then
       read -p $'\nSpecify the flag for node supporting methods: ' bsset 
  fi

if read -t 5 -p $'\nSpecify the number of runs: ' iternumpre; then
   iternum=${iternumpre}
else
   echo -e "
---------------------------------------------------------- 

             Message: There will be 2 runs.

----------------------------------------------------------\n\n"
   iternum=2
fi
  
if [ "${wkfl}" -eq 3 ]; then
    opname="iq-"
elif [ "${wkfl}" -eq 5 ]; then
    opname="iqMF-"
fi
##Generate output layout
rm -rf ../${opname}
mkdir ../${opname} ../${opname}/report ../${opname}/bs-file ../${opname}/trivia
if [ $iqopt -eq 1 ]; then
  mkdir ../${opname}/splitSupport
fi
predir=$(pwd)

##Execute the analysis
for file in *
do
  filetype=$(echo "${file}" | cut -d "." -f 2)
  if [ "${filetype}" = "phy" ]; then
   
   iterindex=1
   while [ "${iterindex}" -le "${iternum}" ] 
   do
     rm -rf ../run${iterindex}
     mkdir ../run${iterindex}
     cp -p ${file} ../run${iterindex}
   
     cd ../run${iterindex}
       for iterfile in *
       do   
         seqlen=$(sed -n "1p" ${iterfile} | cut -d " " -f 3)
         if [ "${seqlen}" -lt 10000 ]; then 
            nth="1"
         elif [ "${seqlen}" -lt 1000000 ]; then 
            nth="2"
         elif [ "${seqlen}" -lt 10000000 ]; then
            nth="3"
         else
            nth="4"
         fi
         if [ "${wkfl}" -eq 3 ]; then
            inp0=$(echo "${iterfile}" | cut -d "." -f 1)
            inp=$(echo "${inp0}.out")
            modelsetting0=$(cat ../MTresult/${inp} | grep "Best model according to AICc" -A31 | grep "iqtree" | cut -d " " -f 7-8)
            modelsetting="${modelsetting0} -ninit 200 -ntop 50 -nt ${nth} ${bsset} -keep-ident"
            iqtree -s ${iterfile} ${modelsetting}
         elif [ "${wkfl}" -eq 5 ]; then
            modelsetting="-m TEST -AICc -ninit 200 -ntop 50 -nt ${nth} ${bsset} -keep-ident" 
            iqtree -s ${iterfile} ${modelsetting}
         fi        
       done
      ((iterindex++))
    done 

##Identify the run with bigger log likelihood
  cd ${predir}
  
  iterindex=1
  while [ "${iterindex}" -le "${iternum}" ]
  do
    loglkh[${iterindex}]=$(cat ../run${iterindex}/*iqtree | grep "Log-likelihood of the tree:" | cut -d " " -f 5)
    loglkhmd[${iterindex}]=$(echo "${loglkh[${iterindex}]} * 10000" | bc | cut -d "." -f 1 | cut -d "-" -f 2)
    ((iterindex++))
  done
  
  iterindex=2; loglkht=${loglkhmd[1]}; tnum=1
  while [ "${iterindex}" -le "${iternum}" ]
  do
    if [ "${loglkht}" -gt "${loglkhmd[${iterindex}]}" ]; then
       loglkht=${loglkhmd[${iterindex}]}
       tnum=${iterindex}
    fi
    ((iterindex++))
  done
 

##File sorting
     mv ../run${tnum}/*iqtree ../${opname}/report/
     mv ../run${tnum}/*treefile ../${opname}/
     mv ../run${tnum}/*log ../run${tnum}/*gz ../run${tnum}/*bionj ../run${tnum}/*mldist ../${opname}/trivia

     if [ -n "${bsset}" ]; then
        mv ../run${tnum}/*contree ../${opname}/trivia
     fi
     
     if [ ${iqopt} -eq 1 ]; then
        mv ../run${tnum}/*splits* ../${opname}/splitSupport
        mv ../run${tnum}/*ufboot ../${opname}/bs-file
     elif [ ${iqopt} -eq 2 ]; then
        mv ../run${tnum}/*boottrees ../${opname}/bs-file
     fi     

 fi
done

if [ "${wkfl}" -eq 3 ]; then
   mv ../MTresult ../${opname}/
fi

iterindex=1
while [ "${iterindex}" -le "${iternum}" ]
do
  rm -rf ../run${iterindex}
  ((iterindex++))
done

echo -e "\n----------< Congratulations! JOB DONE!! >----------"

elif [ ${wkfl} -eq 4 ]; then
#Only run model selection
echo -e "\n----------< Congratulations! JOB DONE!! >----------"
fi

if [ "${wkfl}" -eq 0 ]; then

echo "
-------------------------ERROR!---------------------------

   Message: Please specify a workflow index in next run.

----------------------------------------------------------"

fi
