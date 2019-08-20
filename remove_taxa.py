#!/usr/bin/python3

import argparse
import os
from Bio import SeqIO
from amas import AMAS

# Parse the arguments
parser = argparse.ArgumentParser()
parser.add_argument('-i', metavar='alignment folder',
                    required=True, dest='alns_folder')
parser.add_argument('-f', metavar='alignment format',
                    required=True, dest='format')
parser.add_argument('-r', metavar='removed taxa',
                    required=True, dest='taxa_to_remove', action='append')
args = parser.parse_args()

# Tidy the alignment file
alns_file = os.listdir(os.path.join(os.getcwd(), args.alns_folder))
for i in alns_file:
    if i.endswith('.gb'):
        file_path = os.path.join(os.getcwd(), args.alns_folder, i)
        name = file_path.replace('.gb', '.gb.seqio')
        SeqIO.convert(file_path, 'fasta', name, 'fasta')

# Remove unwanted taxa
alns_file = os.listdir(os.path.join(os.getcwd(), args.alns_folder))
for i in alns_file:
    if i.endswith('.seqio'):
        file_path = os.path.join(os.getcwd(), args.alns_folder, i)
        aln = AMAS.MetaAlignment(
            in_files=[file_path], data_type='dna', in_format=args.format, cores=1)
        aln_dict = aln.get_parsed_alignments()
        try:
            reduced_aln = aln.remove_taxa(args.taxa_to_remove)
        finally:
            reduced_aln = aln.remove_taxa(args.taxa_to_remove)

        aln_format = aln.print_fasta(reduced_aln[i])

        name = file_path.replace('.seqio', '.seqio.reduced')

        with open(os.path.join(os.getcwd(), name), 'w') as out:
            out.writelines(aln_format)
            out.close()
