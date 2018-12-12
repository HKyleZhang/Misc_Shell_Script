#!/bin/bash

read -p "Pairwise Distances are extracted with current folder? (y/n) " answer
if [ "${answer}" = "y" ]; then

  for file in *; do
    filetype=$(echo "${file}" | cut -d "." -f 2)
    if [ "${filetype}" != "sh" ]; then
      name=$(echo "${file}" | cut -d "." -f 1)

      nw_distance -n -m m -t ${file} >${name}_pairwiseDist

    fi
  done

  mkdir pairwise_distance
  mv ./*pairwiseDist ./pairwise_distance

  echo "
Job done!"

fi
