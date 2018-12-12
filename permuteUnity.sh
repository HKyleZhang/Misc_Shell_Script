#!/bin/bash

#'partSort.sh' as a function imported here.
partSort() {
  if [ -n "${1}" ]; then
    op=$(echo "${1}_output")

    lnum=$(cat partition | wc -l)
    pi=1
    while [ "${pi}" -le "${lnum}" ]; do
      gnname[$pi]=$(cat partition | sed -n "${pi}p" | cut -d " " -f 1)
      part[$pi]=$(cat partition | sed -n "${pi}p" | cut -d " " -f 3 | cut -d ";" -f 1)
      ((pi++))
    done

    cli=1
    while [ "${cli}" -le "${lnum}" ]; do
      cl[$cli]=$(cat ${1} | grep "${gnname[$cli]}" | cut -d " " -f 2)
      ((cli++))
    done

    rm -rf ${op}
    i=1
    k=1
    while [ "${i}" -le "${lnum}" ]; do
      if [ "${i}" -eq "${lnum}" ]; then
        j=${i}
      else
        j=$((i + 1))
      fi

      if [ "${cl[$i]}" != "NA" ]; then
        partcon=$(echo "${part[$i]}")
        while [ "${j}" -le "${lnum}" ]; do
          if [ "${cl[$j]}" != "NA" ]; then
            if [ "${cl[$j]}" -eq "${cl[$i]}" ]; then
              if [ "${i}" -lt "${lnum}" ]; then
                partcon=$(echo "${partcon},${part[$j]}")
                cl[$j]="NA"
              fi
            fi
          fi

          ((j++))
        done
        if [ "${k}" -lt 10 ]; then
          echo "cluster0${k} = ${partcon}" >>${op}
        else
          echo "cluster${k} = ${partcon}" >>${op}
        fi
        ((k++))
      fi
      ((i++))
    done

  else

    echo -e "\nERROR!!!\nNo cluster information!"

  fi
}

#Identify the run with larger loglikelihood
pickbestrun() {
  iterindex=1
  while [ "${iterindex}" -le "${2}" ]; do
    loglkh[${iterindex}]=$(cat ${1}_run${2}/*iqtree | grep "Log-likelihood of the tree:" | cut -d " " -f 5)
    loglkhmd[${iterindex}]=$(echo "${loglkh[${iterindex}]} * 10000" | bc | cut -d "." -f 1 | cut -d "-" -f 2)
    ((iterindex++))
  done

  iterindex=2
  loglkht=${loglkhmd[1]}
  tnum=1
  while [ "${iterindex}" -le "${2}" ]; do
    if [ "${loglkht}" -gt "${loglkhmd[${iterindex}]}" ]; then
      loglkht=${loglkhmd[${iterindex}]}
      tnum=${iterindex}
    fi
    ((iterindex++))
  done
}

#logLXtract.sh as a function imported here.
logLXtract() {
  if [ "${hyp}" = "H0" ]; then
    seqname=${1}
    seqnamemd=$(echo "${1}_finish")
  elif [ "${hyp}" = "H1" ]; then
    seqname=${1}
  fi

  clfiup=0 #number of cluster file                         #Obtain the total cluster number
  for clfile in ${2}/clinfo/*; do
    fex=$(echo "${clfile}" | cut -d "." -f 2)
    if [ "${fex}" = "cl" ]; then
      ((clfiup++))
      kclnum[$clfiup]=$(basename ${clfile} | cut -d "." -f 1)
    fi
  done #Finish obtaining the total cluster number

  ki=0
  while [ "${ki}" -lt "${clfiup}" ]; do
    ((ki++))
    clnumup=$(echo "${kclnum[$ki]}" | cut -d "k" -f 2)
    clnum=0
    ttllogLhmd=0
    while [ "${clnum}" -lt "${clnumup}" ]; do
      ((clnum++))
      if [ "${clnum}" -lt 10 ]; then
        clnumfm=$(echo "0${clnum}")
      else
        clnumfm=${clnum}
      fi
      if [ "${hyp}" = "H0" ]; then
        cd ${2}/${seqnamemd}/${kclnum[$ki]}/${seqname}_cluster${clnumfm}-out_bestrun
      elif [ "${hyp}" = "H1" ]; then
        cd ${2}/${seqname}/${kclnum[$ki]}/${seqname}_cluster${clnumfm}-out_bestrun
      fi
      logLh=$(cat *iqtree | grep "Log-likelihood of the tree:" | cut -d " " -f 5)
      logLhmd=$(echo "${logLh} * 10000" | bc | cut -d "." -f 1 | cut -d "-" -f 2)
      ttllogLhmd=$((ttllogLhmd + logLhmd))
    done
    echo -e "${seqname} k=${clnumup} -loglikelihood*10^4:\t${ttllogLhmd}" >>${2}/${seqname}_logLhcollection
  done
  if [ ! -d "${2}/logLikelihood" ]; then mkdir ${2}/logLikelihood; fi
  mv ${2}/*logLhcollection ${2}/logLikelihood/
}

#Create partition-sorted file
clfi=0
rm -rf cl_sort
mkdir cl_sort
for file in clinfo/*; do
  fex=$(echo "${file}" | cut -d "." -f 2)
  if [ "${fex}" = "cl" ]; then
    partSort ${file}
    filename=$(basename ${file})
    ((clfi++))
    clf[$clfi]=$(echo "${filename}_output")
    mv ./clinfo/*cl_output ./cl_sort/
  fi
done
echo -e "\nOutput results have been moved to folder: cl_sort"

#Execute the sequence splitting
ni=0
for file in *; do
  namex=$(echo "${file}" | cut -d "." -f 2)

  if [ "${namex}" = "phy" ]; then
    exei=1
    ((ni++))
    name[$ni]=$(echo "${file}" | cut -d "." -f 1)
    mkdir ${name[$ni]}

    while [ "${exei}" -le "${clfi}" ]; do
      python ~/Software/amas/AMAS.py split -f phylip -d dna -i ${file} -l ./cl_sort/${clf[$exei]} -u phylip
      kclnum=$(echo "${clf[$exei]}" | cut -d "." -f 1)
      mkdir ./${name[$ni]}/${kclnum}
      mv ./*cluster* ./${name[$ni]}/${kclnum}/
      ((exei++))
    done
  fi

done
echo -e "\nJob Done!!!\nNow you can proceed to Tree Construction!"

read -p $'\nContinue to Tree Construction? (y/n): ' totree

if [ "${totree}" = "y" ] || [ "${totree}" = "Y" ]; then

  read -p $'\nSpecify the number of runs: ' runtime
  if [ -z "${runtime}" ]; then runtime=2; fi

  read -p $'\nRun tree construction on\nH0:Null Hypothesis.\nH1:Alternative Hypothesis.\nChoose: ' hyp
  if [ -z "${hyp}" ]; then
    echo -e "\nERROR!!!" && exit
  elif [ "${hyp}" = "H0" ]; then
    read -p $'\nSpecify the folder name of H1: ' foldername
    if [ -z "${foldername}" ]; then echo -e "\nERROR!!!" && exit; fi
  fi

  curdir=$(pwd)
  tri=1
  while [ "${tri}" -le "${ni}" ]; do
    trj=1
    while [ "${trj}" -le "${clfi}" ]; do
      kclnum=$(echo "${clf[$trj]}" | cut -d "." -f 1)
      cd ${curdir}/${name[$tri]}/${kclnum}/
      clnum=1
      for seqfile in *; do
        seqlen=$(sed -n "1p" ${seqfile} | cut -d " " -f 2)
        if [ "${seqlen}" -lt 10000 ]; then
          nth="1"
        elif [ "${seqlen}" -lt 1000000 ]; then
          nth="2"
        elif [ "${seqlen}" -lt 10000000 ]; then
          nth="3"
        else
          nth="4"
        fi
        if [ "${clnum}" -lt 10 ]; then
          teststring1=$(echo "cluster0${clnum}")
        else
          teststring1=$(echo "cluster${clnum}")
        fi
        teststring2=$(echo "${seqfile}" | grep "${teststring1}")
        if [ -n "${teststring2}" ]; then
          ri=0
          while [ "${ri}" -lt "${runtime}" ]; do
            ((ri++))
            if [ "${ri}" -gt 1 ]; then clnum=$((clnum - 1)); fi
            seqfname=$(echo "${seqfile}" | cut -d "." -f 1)
            if [ "${hyp}" = "H0" ]; then
              if [ "${clnum}" -lt 10 ]; then
                clnumfm=$(echo "0${clnum}")
              else
                clnumfm=${clnum}
              fi
              model=$(cat ${curdir}/${foldername}/${kclnum}/${foldername}_cluster${clnumfm}-out_bestrun/*iqtree | grep "Best-fit model according to AICc:" | cut -d " " -f 6)
              iqtree -s ${seqfile} -m ${model} -ninit 200 -ntop 50 -nt ${nth} -keep-ident -pre ${seqfname}.run
              ((clnum++))
            elif [ "${hyp}" = "H1" ]; then
              iqtree -s ${seqfile} -m TEST -AICc -ninit 200 -ntop 50 -nt ${nth} -keep-ident -pre ${seqfname}.run
              ((clnum++))
            fi
            mkdir ${seqfname}_run${ri}

            for mvfile in *; do #File sorting

              mvfex=$(echo "${mvfile}" | cut -d "." -f 2)
              if [ "${mvfex}" = "run" ]; then
                mv ${mvfile} ./${seqfname}_run${ri}/
              fi
            done #File sorting finish

          done
          rm -rf ${seqfile}             #For saving the storage room
          pickbestrun ${seqfname} ${ri} #Select the run with the highest log likelihood
          mkdir ${seqfname}_bestrun
          mv ${seqfname}_run${tnum}/* ${seqfname}_bestrun/
          di=1
          while [ "${di}" -le "${ri}" ]; do
            rm -rf ${seqfname}_run${di}
            ((di++))
          done #Finish select the run with the highest log likelihood
        fi
      done
      ((trj++))
    done
    if [ "${hyp}" = "H0" ]; then
      cd ${curdir}
      mv ${name[$tri]} ${name[$tri]}_finish
    fi
    logLXtract ${name[$tri]} ${curdir}
    ((tri++))
  done

  rm -rf ${curdir}/*finish ${curdir}/*phy

fi
