#!/bin/bash

read -p "Do gene trees extraction on files in current folder? (y/n):" answer
if [ "${answer}" = "y" ]; then
read -p "
Tag the name before the trees?(y/n): " tag
for file in *
do filename=$(echo "${file}" | cut -d "." -f 2)
if [ "${filename}" != "sh" ]; then
   name=$(echo "${file}" | cut -d "." -f 1 | cut -d "-" -f 2)
   seq=$(sed -n "1p" ${file})
   if [ "${tag}" = "y" ]; then
     echo "$name $seq" >> ../gnTrees_collection.tre
   elif [ "${tag}" = "n" ]; then
     echo "$seq" >> ../gnTrees_noname.tre
   fi
fi
done
 echo "
Job Done!"
else
echo "
Abortion!"
fi
