##############################
# MODULES
import os, re
import glob
import pandas as pd

# ##############################
# # Parameters
# CORES=int(os.environ.get("CORES", 4))


##############################
# Paths
SRC_DIR=srcdir("../../scripts")
# ENV_DIR = srcdir("../envs")
# NOTES_DIR = srcdir("../notes")
SUBMODULES=srcdir("../../submodules")

##############################
# Dependencies 
PERL5LIB="/home/users/sbusi/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
PERL_LOCAL_LIB_ROOT="/home/users/sbusi/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
PERL_MB_OPT="--install_base \"/home/users/sbusi/perl5\""
PERL_MM_OPT="INSTALL_BASE=/home/users/sbusi/perl5"


##############################
# default executable for snakemake
shell.executable("bash")


##############################
# working directory
workdir:
    config["work_dir"]


##############################
# Relevant directories
ASSEMBLY_DIR=config["assembly_dir"]
DB_DIR=config["db_dir"]
ENV_DIR=config["env_dir"]
#MAG_DIR=config["mag_dir"]
READS_DIR=config["reads_dir"]
RESULTS_DIR=config["results_dir"]

##############################
# Steps
STEPS = config["steps"]


##############################
# Input
SAMPLES = [line.strip() for line in open("config/sample_list.txt").readlines()]
SAMPLES_2=SAMPLES

# SAMPLES_2 = [line.strip() for line in open("config/rock_list.txt").readlines()]
#SAMPLES_2 = [line.strip() for line in open("config/all_rock_sediment_samples.txt").readlines()]

# Alternative method: SAMPLES=[line.strip() for line in open("config/all_samples.txt", 'r')]
