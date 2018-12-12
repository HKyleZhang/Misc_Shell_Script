#!/bin/bash

read -p "Do gene trees extraction on files in current folder? (y/n):" answer
if [ "${answer}" = "y" ]; then
  read -p "
Select trees extraction options:
     1. Extract trees WITH gene name ahead.
     2. Extract trees WITHOUT gene name ahead.
     3. Run both 1st and 2nd options.
Choose: " index

  for file in *; do
    filename=$(echo "${file}" | cut -d "." -f 2)
    if [ "${filename}" != "sh" ]; then
      name=$(echo "${file}" | cut -d "." -f 1 | cut -d "-" -f 2)
      seq=$(sed -n "1p" ${file})

      if [ ${index} -eq 1 ]; then
        echo "$name $seq" >>../gnTrees_collection.tre
      elif [ ${index} -eq 2 ]; then
        echo "$seq" >>../gnTrees_noname.tre
      elif [ ${index} -eq 3 ]; then
        echo "$name $seq" >>../gnTrees_collection.tre
        echo "$seq" >>../gnTrees_noname.tre
      fi
    fi
  done
  echo "
Job Done!"
else
  echo "
Abortion!"
fi
