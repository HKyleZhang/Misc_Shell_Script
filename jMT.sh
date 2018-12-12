#!/bin/bash

echo "************************************************************

Msg:Analysis is performed on the current folder.
If you wish to change, please change it in the script.

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

echo "************************************************************

Msg:Current number of substistution schemes is 3.
If you wish to change, please change it in the script.

************************************************************"

#Model selection
rm -rf ../${jmtfolder}
mkdir ../${jmtfolder}
for file in *; do
  jmt0=$(echo "${file}" | cut -d "." -f 1)
  jmt="${jmt0}_jMT"

  var=$(echo "${file}" | cut -d "." -f 2)

  if [ "${var}" = "${filetype}" ]; then
    java -jar /home/hk/Software/jmodeltest-2.1.10/jModelTest.jar -d ${file} -s 3 -S BEST -f -i -g 4 -AICc -uLnL -p -o ../${jmtfolder}/${jmt}
  fi
done

echo "
Job Done!"
