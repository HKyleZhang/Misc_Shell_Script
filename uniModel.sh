#!/bin/bash

editor='if (!require(foreach)) install.packages("foreach")
if (!require(doParallel)) install.packages("doParallel")

no_cores <- detectCores()
registerDoParallel(no_cores)

files <- list.files(pattern = "*model")
foreach(i=files) %dopar% {
    name <- strsplit(i, ".", fixed = TRUE)[[1]][1]
    name <- paste(name, ".txt", sep = "")
	dd <- read.table(i)
	optmodel <- dd[1,2]
	for (k in 1:nrow(dd)){
		dd[k,2] <- abs(round(dd[k,2] - optmodel,3))
	}
	write.table(dd[order(dd$V1),], file = name, quote = FALSE, row.names = FALSE, col.names = FALSE)
}'

find_model='if (!require(dplyr)) install.packages("dplyr")
dd <- read.table("model.summary")
dd$mean <- apply(dd[,2:ncol(dd)], 1, mean)
dd$sd <- apply(dd[,2:ncol(dd)], 1, sd)
dd <- arrange(dd, mean, sd)
write.table(dd, "bestmodel.txt", quote = FALSE, row.names = FALSE, col.names = FALSE)
'

curdir=$(pwd)
read -p "Specify the folder: " fd

rm -rf ${curdir}/${fd}-temp
mkdir ${curdir}/${fd}-temp
for i in ${curdir}/${fd}/*iqtree; do
  name=$(basename ${i} | cut -d "." -f 1)
  cat ${i} | grep -A92 "List of models sorted by AICc scores:" >${curdir}/${fd}-temp/${name}
done

rm -rf ${curdir}/${fd}-temp2
mkdir ${curdir}/${fd}-temp2
for i in ${curdir}/${fd}-temp/*; do
  name=$(basename ${i})
  lnum=$(cat ${i} | wc -l)
  sed -n "4,${lnum}p" ${i} >${curdir}/${fd}-temp2/${name}
done
rm -rf ${curdir}/${fd}-temp

rm -rf ${curdir}/${fd}-model
mkdir ${curdir}/${fd}-model
for i in ${curdir}/${fd}-temp2/*; do
  name=$(basename ${i})
  cat ${i} | cut -c 1-27 >${curdir}/${fd}-model/${name}.model
done
rm -rf ${curdir}/${fd}-temp2
cd ${curdir}/${fd}-model/
Rscript <(echo "${editor}") 2>&1 >/dev/null
rm -rf ${curdir}/${fd}-model/*model

rm -rf ${curdir}/${fd}-temp
mkdir ${curdir}/${fd}-temp
for i in ${curdir}/${fd}-model/*; do
  if [ ! -e ${curdir}/${fd}-temp/00A.txt ]; then
    cat ${i} | cut -d " " -f 1 >${curdir}/${fd}-temp/00A.txt
  fi
  name=$(basename ${i})
  cat ${i} | cut -d " " -f 2 >${curdir}/${fd}-temp/${name}
done
rm -rf ${curdir}/${fd}-model

cd ${curdir}/${fd}-temp/
paste -d " " * >${curdir}/model.summary
rm -rf ${curdir}/${fd}-temp

cd ${curdir}
Rscript <(echo "${find_model}") 2>&1 >/dev/null
rm -rf ${curdir}/model.summary
