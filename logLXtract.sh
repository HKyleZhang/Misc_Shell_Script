#!/bin/bash

read -p $'Extract sum log likelihood of cluster from:\n1.H0:Null Hypothesis.\n2.H1:Alternative Hypothesis.\nChoose: ' hyp

if [ -n "${hyp}" ]; then

  hiup=0   #number of sequence file                            #Obtain the name of the sequence file
  for seqfile in *; do
    fex=$(echo "${seqfile}" | cut -d "." -f 2)
    if [ "${fex}" = "phy" ]; then
      ((hiup++))
      if [ "${hyp}" = "H0" ]; then
        seqname[$hiup]=$(echo "${seqfile}" | cut -d "." -f 1)
        seqnamemd[$hiup]=$(echo "${seqname[$hiup]}_finish")
      elif [ "${hyp}" = "H1" ]; then
        seqname[$hiup]=$(echo "${seqfile}" | cut -d "." -f 1)
      fi
    fi
  done #Finish obtaining the name of the sequence file

  clfiup=0 #number of cluster file                         #Obtain the total cluster number
  for clfile in clinfo/*; do
    fex=$(echo "${clfile}" | cut -d "." -f 2)
    if [ "${fex}" = "cl" ]; then
      ((clfiup++))
      kclnum[$clfiup]=$(basename ${clfile} | cut -d "." -f 1)
    fi
  done #Finish obtaining the total cluster number

  curdir=$(pwd)
  hi=0 #Extract and sum the log likelihood
  while [ "${hi}" -lt "${hiup}" ]; do
    ((hi++))
    clfi=0
    while [ "${clfi}" -lt "${clfiup}" ]; do
      ((clfi++))
      clnumup=$(echo "${kclnum[$clfi]}" | cut -d "k" -f 2)
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
          cd ${curdir}/${seqnamemd[$hi]}/${kclnum[$clfi]}/${seqname[$hi]}_cluster${clnumfm}-out_bestrun
        elif [ "${hyp}" = "H1" ]; then
          cd ${curdir}/${seqname[$hi]}/${kclnum[$clfi]}/${seqname[$hi]}_cluster${clnumfm}-out_bestrun
        fi
        logLh=$(cat *iqtree | grep "Log-likelihood of the tree:" | cut -d " " -f 5)
        logLhmd=$(echo "${logLh} * 10000" | bc | cut -d "." -f 1 | cut -d "-" -f 2)
        ttllogLhmd=$((ttllogLhmd + logLhmd))
      done
      echo -e "${seqname[$hi]} k=${clnumup} -loglikelihood*10^4:\t${ttllogLhmd}" >>${curdir}/${seqname[$hi]}_logLhcollection
    done
  done #Finish extracting and sum the log likelihood
  mkdir logLikelihood
  mv *logLhcollection ./logLikelihood/
fi
