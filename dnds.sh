#!/bin/bash
read -p "Specify file name: " fn

ex=$(echo "${fn}" | cut -d "." -f 2)
rm -rf ../${ex}
mkdir ../${ex}

num=$(cat ${fn} | grep -n "     6" | wc -l)

i=1
while [[ "${i}" -le "${num}" ]]; do
  lin=$(cat ${fn} | grep -n "     6" | sed -n "${i}p" | cut -d ":" -f 1)
  linstart=$((lin + 2))
  linend=$((lin + 6))
  name=$(cat genelist | sed -n "${i}p")
  cat ${fn} | sed -n "${linstart},${linend}p" >../${ex}/${name}.${ex}
  ((i++))
done

rm -rf ../${ex}-temp
mkdir ../${ex}-temp

cd ../${ex}/
for i in *; do
  sed -i 's/MW /MW/' ${i}
  sed -i 's/BC /BC/' ${i}
  sed -i 's/CW /CW/' ${i}

  echo "${i}" | cut -d "." -f 1 | cut -d "-" -f 2 >../${ex}-temp/${i}
  cat "${i}" | cut -d " " -f 16 >>../${ex}-temp/${i}
done

cd ../${ex}-temp
rm -rf ../${ex}

echo -e "gene\nGRW\nCRW\nMW\nBC\nCW" >00.txt
paste -d " " * >../${ex}.txt

cd ..
rm -rf ${ex}-temp
