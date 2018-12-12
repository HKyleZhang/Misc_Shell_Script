#!/bin/bash

parsemodel()
{ 
 mpart[1]=$(echo "${1}" | cut -d "+" -f 1)
 if [ "${mpart[1]}" = "SYM" ] || [ "${mpart[1]}" = "K2P" ] || [ "${mpart[1]}" = "JC" ]; then
    mappend="statefreqpr=fixed(equal)"
 else
    mappend=""
 fi

 if [ "${mpart[1]}" = "GTR" ] || [ "${mpart[1]}" = "SYM" ]; then
    mpart[1]="lset nst=6"
 elif [ "${mpart[1]}" = "HKY" ] || [ "${mpart[1]}" = "K2P" ]; then
    mpart[1]="lset nst=2"
 elif [ "${mpart[1]}" = "F81" ] || [ "${mpart[1]}" = "JC" ]; then
    mpart[1]="lset nst=1"
 else
    mpart[1]="lset nst=6"
 fi

 Fyes=$(echo "${1}" | grep "F")
 if [ -n ${Fyes} ]; then nm=$(echo "${1}" | sed "s/+F//"); fi
 
 Iyes=$(echo "${nm}" | grep "I")
 Gyes=$(echo "${nm}" | grep "G")
 mpart[2]=""
 if [ -n "${Iyes}" ] && [ -n "${Gyes}" ]; then
    mpart[2]="rates=invgamma"
 elif [ -n "${Iyes}" ] && [ -z "${Gyes}" ]; then
    mpart[2]="rates=propinv"
 elif [ -z "${Iyes}" ] && [ -n "${Gyes}" ]; then
    mpart[2]="rates=gamma"
 fi
 
}



curdir=$(pwd)

count=0
for file in *nex
do 
  ((count++))
done

index=0
for file in *nex
do
  fname=$(echo "${file}" | cut -d "." -f 1)
  fmname=$(echo "${fname}.phy.iqtree")
  model=$(cat ${curdir}/report/${fmname} | grep "Best-fit model according to AICc:" | cut -d ":" -f 2 | cut -d " " -f 2)
  parsemodel ${model}
  mds=$(echo "${mpart[1]} ${mappend} ${mpart[2]}") 
 
  mbname=$(echo "${fname}.mrb")
  cp -p ${curdir}/template ${curdir}/${mbname}
  sed -i "s/<seqfile>/${fname}.nex/" ${curdir}/${mbname}
  sed -i "s/<modelsetting>/${mds}/" ${curdir}/${mbname}
  mpirun -np 4 mb <${mbname}> ${fname}.finish
 
  mkdir ${fname}                                                            #File sorting
  mkdir ${fname}/statistics ${fname}/trees ${fname}/trivia ${fname}/report
  mv *.t *.parts *.tstat *.vstat *.trprobs ${curdir}/${fname}/trees/
  mv *.p *.pstat *.lstat ${curdir}/${fname}/statistics/
  mv *.finish ${curdir}/${fname}/report
  mv *.ckp* *.mrb *.mcmc ${curdir}/${fname}/trivia/                          #Finish file sorting

  rm -rf ${file}
  
  echo "Programme is running..."
  ((index++))
  if [ "${index}" -eq 1 ]; then
     echo -e "\n${index} file is finished..."
  elif [ "${index}" -lt "${count}" ]; then
     echo "${index} files is finished..."
  else
     echo "*******Job Done!!!********"
  fi
done 

