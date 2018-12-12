#!/bin/bash

read -p "Do gene trees extraction on files in current folder? (y/n):" answer
if [ "${answer}" == "y" ]; then
for file in *
do filename=$(echo "${file}" | cut -d "." -f 2)
if [ "${filename}" != "sh" ]; then
   name=$(echo "${file}" | cut -d "." -f 1)
   seq=$(sed -n "1p" ${file})
   echo "$name $seq" >> ../gnTrees_collection.tre
fi
done
 echo "
Job Done!"
else
echo "
Abortion!"
fi
