#!/bin/bash -l

##############################
# SLURM
# NOTE: used for this script only, NOT for the snakemake call below

#SBATCH -J nomis_pipeline
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 1
#SBATCH --time=2-00:00:00
#SBATCH -p batch
#SBATCH -A project_ensemble
#SBATCH --qos=normal

##############################
# SNAKEMAKE

# conda env name
SMK_ENV="snakemake" # USER INPUT REQUIRED
# number of cores for snakemake
SMK_CORES=70
# snakemake file
SMK_SMK="workflow/Snakefile"
# config file
SMK_CONFIG="config/config.yaml" # USER INPUT REQUIRED
# slurm config file
SMK_SLURM="config/slurm.yaml"
# slurm cluster call
SMK_CLUSTER="sbatch -p {cluster.partition} -A {cluster.account} -q {cluster.qos} {cluster.explicit} -N {cluster.nodes} -n {cluster.n} -c {threads} -t {cluster.time} --job-name={cluster.job-name}"


##############################
# IMP

# activate the env
conda activate ${SMK_ENV}

# run the pipeline

snakemake -s ${SMK_SMK} --local-cores 1 \
-j ${SMK_CORES} \
--configfile ${SMK_CONFIG} --use-conda --conda-prefix snakemake_envs \
--cluster-config ${SMK_SLURM} --cluster "${SMK_CLUSTER}" --rerun-incomplete --rerun-triggers mtime -rp -k --unlock

snakemake -s ${SMK_SMK} --local-cores 1 \
-j ${SMK_CORES} \
--configfile ${SMK_CONFIG} --use-conda --conda-prefix snakemake_envs \
--cluster-config ${SMK_SLURM} --cluster "${SMK_CLUSTER}" --rerun-incomplete --rerun-triggers mtime -rp -k
