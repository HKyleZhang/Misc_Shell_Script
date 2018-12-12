#!/bin/bash

echo "************************************************************

Msg:Analysis is performed on the current folder.
If you wish to change, please change it in the script jMT-phyml.sh

************************************************************"
fd=$(pwd)
datafolder=$(basename ${fd}) #Define the folder where the Phylip-format files are.

read -p "
>>>>File type for analysis is (Default:phy):" filetype
if [ -z "${filetype}" ]; then
  filetype="phy" #Defaut file type is phylip format.
fi

read -p "
>>>>Specify the folder name to store the output from jModelTest (Default will create a folder named output_jMT):" jmtfolder #Define the folder where the jMT results are saved.
if [ -z "${jmtfolder}" ]; then
  jmtfolder="output_jMT" #Default folder to store the output.
fi

read -p "
>>>>Specify the folder name to store the analysis result:" alyfolder
if [ -z "${alyfolder}" ]; then
  alyfolder="analysis_output"
fi

read -p "
>>>>Bootstrapping?(y/n):(Answer Default:n)" support #Define the method for branch support method.
if [ "${support}" = "y" ]; then
  support="1000"
else
  echo "
************************************************************

Msg:The branch support method would be aLRT

************************************************************"
  read -p "
>>>>Select other methods? Current method is aBayes.(y/n):(Answer Default:n)" support
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

#Model selection
rm -rf ../${jmtfolder}
mkdir ../${jmtfolder}
for file in *; do
  jmt0=$(echo "${file}" | cut -d "." -f 1)
  jmt="${jmt0}_jMT"

  var=$(echo "${file}" | cut -d "." -f 2)

  if [ "${var}" = "${filetype}" ]; then
    java -jar /home/hk/Software/jmodeltest-2.1.10/jModelTest.jar -d ${file} -s 11 -S BEST -f -i -g 4 -AICc -uLnL -p -o ../${jmtfolder}/${jmt}
  fi
done

#Extract the information of the best model for each file
cd ../${jmtfolder}
rm -rf ../model_setting
mkdir ../model_setting
for file in *; do
  name0=$(echo "${file}" | cut -d "." -f 1)
  name="${name0}_mse"

  cat ${file} | grep "phyml" | grep "BEST" | uniq >../model_setting/${name}
done

#Feed the phyml
cd ../${datafolder}
for file in *; do

  var=$(echo "${file}" | cut -d "." -f 2)

  if [ "${var}" = "${filetype}" ]; then

    treename0=$(echo "${file}" | cut -d "." -f 1)
    treename="${treename0}_jMT_mse"
    modelcount=$(grep -c "phyml" ../model_setting/${treename})

    if [ "${modelcount}" = 1 ]; then
      modelsetting0=$(cat ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelsetting="${modelsetting0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelsetting}
    elif [ "${modelcount}" = 2 ]; then
      modelA0=$(sed -n "1p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelAsetting="${modelA0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelAsetting}

      modelB0=$(sed -n "2p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelBsetting="${modelB0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelBsetting}
    elif [ "${modelcount}" = 3 ]; then
      modelA0=$(sed -n "1p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelAsetting="${modelA0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelAsetting}

      modelB0=$(sed -n "2p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelBsetting="${modelB0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelBsetting}

      modelC0=$(sed -n "3p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelCsetting="${modelC0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelCsetting}
    elif [ "${modelcount}" = 4 ]; then
      modelA0=$(sed -n "1p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelAsetting="${modelA0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelAsetting}

      modelB0=$(sed -n "2p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelBsetting="${modelB0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelBsetting}

      modelC0=$(sed -n "3p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelCsetting="${modelC0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelCsetting}

      modelD0=$(sed -n "4p" ../model_setting/${treename} | sed "s/.*.phy //" | cut -d " " -f 1-4,7-21)
      modelDsetting="${modelD0} -b ${support}"
      mpirun -n 4 phyml-mpi -i ${file} ${modelDsetting}
    fi
  fi
done

#File sorting
rm -rf ../${alyfolder} ../model_setting
mkdir ../${alyfolder}
mv ../${jmtfolder} ${fd}/*.txt* ../${alyfolder}/

if [ "${support}" = 1000 ]; then
  mkdir ../${alyfolder}/stats
  mv ../${alyfolder}/*_stats* ../${alyfolder}/*_boot_trees* ../${alyfolder}/stats/
else
  mkdir ../${alyfolder}/stats
  mv ../${alyfolder}/*_stats* ../${alyfolder}/stats/
fi
