#!/bin/bash

read -p "Perform PartitionFinder2 on current folder? (y/n)" answer
if [ "${answer}" = "y" ]; then
  folder=$(pwd)
  python /home/hk/Software/partitionfinder_2.1.1/PartitionFinder.py ${folder}
fi
