#!/usr/bin/python3

import argparse
import os
import re
import shutil as act
from subprocess import call as sh_run
from rpy2 import robjects as Rscript

# R code. Root phylogenetic trees with ape R package
RooTree = '''
suppressPackageStartupMessages(library(ape))
suppressPackageStartupMessages(library(phylogram))

iqtrees <- read.tree("IQ-TREE_FILE")
iqtrees <- root.multiPhylo(iqtrees, "OUTGROUP", resolve.root = T)

for (i in 1:length(iqtrees)) {
  iqtrees[[i]] <-
    as.phylo.dendrogram(as.cladogram(as.dendrogram.phylo(iqtrees[[i]])))
}

write.tree(iqtrees, "IQ-trees.nw", tree.names = TRUE, digits = 0)'''

# Parse the arguments
parser = argparse.ArgumentParser()
parser.add_argument('-a', metavar='alignment folder',
                    required=True, dest='aln_folder')
parser.add_argument('-i', metavar='IQ-Tree output folder',
                    required=True, dest='iq_output')
parser.add_argument('-m', metavar='model file',
                    required=True, dest='evo_model')
parser.add_argument('-n', metavar='hypothetical topology set',
                    required=True, dest='topo_set')
parser.add_argument('-o', metavar='outgroup', required=True, dest='og')
args = parser.parse_args()
args.aln_folder = re.sub('/$', '', args.aln_folder)

# Directory path
dir = os.getcwd()
aln_dir = dir + '/' + args.aln_folder

# Root and extract topology of the best ML trees
RooTreeTemp = RooTree
RooTreeTemp = RooTreeTemp.replace(
    'IQ-TREE_FILE', args.aln_folder + '.treefile').replace('OUTGROUP', args.og)
os.chdir(dir + '/' + args.iq_output)
Rscript.r(RooTreeTemp)

rooted_tree = open('IQ-trees.nw', 'r')
mod_rooted_tree = rooted_tree.read()
rooted_tree.close()
mod_rooted_tree = re.sub(r':\d', '', mod_rooted_tree)
rooted_tree = open('IQ-trees.nw', 'w')
rooted_tree.write(mod_rooted_tree)
rooted_tree.close()

act.move('IQ-trees.nw', dir)
os.chdir(dir)

# AU topology test using IQ-Tree
alns = os.listdir(aln_dir)
alns.sort()

t = 0
for aln_file in alns:
    if aln_file.endswith(".phy"):
        f = open(aln_dir+'/'+aln_file, 'r')
        aln_name = os.path.basename(f.name)

        # Get model
        model_file = open(dir + '/' + args.evo_model, 'r')
        for line in model_file:
            if aln_name in line:
                model = line.split(':')[0]

        # Get best ML topology
        best_topo = open(dir + '/IQ-trees.nw', 'r').readlines()[t]
        t += 1

        # Get test topology
        test_topo = open(dir + '/' + args.topo_set, 'r').readlines()
        if bool(re.match('\n', test_topo[-1])):
            test_topo = test_topo[:-1]

        # Make topology set
        test_topo.append(best_topo)

        topo_set_file = open(dir+'/topo_set.nw', 'w')
        topo_set_file.writelines(test_topo)
        topo_set_file.close()

        # Topology test using IQ-Tree
        sh_run(['iqtree', '-s', f.name, '--trees', dir + '/topo_set.nw',
                '-m', model, '--test-au', '-zb', '10000', '-keep-ident'])

        os.remove(dir+'/topo_set.nw')

os.mkdir(dir+'/Topo_test')
for i in os.listdir(aln_dir):
    if i.endswith('.iqtree'):
        act.move(aln_dir+'/'+i, dir + '/Topo_test')

for i in os.listdir(aln_dir):
    if i.endswith('.bionj') or i.endswith('.gz') or i.endswith('.log') or i.endswith('.mldist') or 'tree' in i:
        os.remove(aln_dir+'/'+i)

# Summarize
summary = open(dir+'/topo_test.summary', 'a')
res_folder = os.listdir(dir + '/Topo_test')
res_folder.sort()
for i in res_folder:
    res_file = open(dir+'/Topo_test/'+i, 'r')
    res = res_file.readlines()

    for line_no, line in enumerate(res):
        if 'Tree      logL' in line:
            break
        else:
            line_no = -1

    f = open(dir + '/' + args.topo_set, 'r').readlines()
    to_line = int(len(f)) + 2 + int(line_no)

    summary.write(os.path.basename(res_file.name) + '\n')
    summary.writelines(res[line_no:to_line])
    summary.write('\n\n')

    res_file.close()
summary.close()

dest = dir + '/Input_files'
args_dict = vars(args)
del args_dict['og']
os.mkdir(dest)
for i in args_dict.values():
    act.move(dir + '/' + i, dest)

dest = dir + '/Output_files'
os.mkdir(dest)
act.move(dir + '/Topo_test', dest)
act.move(dir + '/IQ-trees.nw', dest)
act.move(dir + '/topo_test.summary', dest)
