#!/usr/bin/python

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-n', metavar='name of the project',
                    required=True, dest='p_folder')
args = parser.parse_args()

dir = os.getcwd()

os.mkdir(dir + '/' + args.p_folder)
os.mkdir(dir + '/' + args.p_folder + '/Data')
os.mkdir(dir + '/' + args.p_folder + '/Analysis')
os.mkdir(dir + '/' + args.p_folder + '/Docs')
os.mkdir(dir + '/' + args.p_folder + '/Local_scripts')
os.mkdir(dir + '/' + args.p_folder + '/Progs')
os.mkdir(dir + '/' + args.p_folder + '/Others')
