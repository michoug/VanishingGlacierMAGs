# VanishingGlacierMAGs generation and analysis

[![DOI](https://zenodo.org/badge/657517189.svg)](https://zenodo.org/doi/10.5281/zenodo.10648954)

This pipeline is used to generate MAGs from different individual assemblies and their respective reads for the [VanishingGlaciers](https://www.glacierstreams.ch/) project. The pipeline is based on the [Snakemake](https://snakemake.readthedocs.io/en/stable/) workflow management system and is designed to be run on a high-performance computing cluster.

## Pipeline description

- This pipeline starts with different individual assemblies (`fasta` files) and their respective reads (`mg.r{1,2}.preprocessed.fq` files).
- To reduce computational time, the reads are subsampled to 10% reads per sample and the contigs less than 1.5 kbp are removed.
- The subsampled reads are then mapped against the assemblies using [BWA](https://github.com/lh3/bwa).
- The mapped reads are then used to bin the contigs using [MetaBAT2](https://bitbucket.org/berkeleylab/metabat/src/master/), [CONCOCT](https://github.com/BinPro/CONCOCT) and [MetaBinner](https://github.com/ziyewang/MetaBinner).
- The bins are then optimized using [DAS_Tool](https://github.com/cmks/DAS_Tool).
- [CheckM2](https://github.com/chklovski/CheckM2) is used to estimate the quality of the bins and only the ones that are 50% complete are kept.
- [MDMCleaner](https://github.com/KIT-IBG-5/mdmcleaner) reduces contamination from those bins.
- Next, bins are dereplicated with [dRep](https://github.com/MrOlm/drep) to form MAGs and only bins with >70% completeness and < 10% contamination are kept.
- Read mapping against all the MAGs is done using [BWA](https://github.com/lh3/bwa). 
- And [GtdbTk](https://github.com/Ecogenomics/GTDBTk) is used for the taxonomy.
- [MGThermometer](https://doi.org/10.1101/2022.07.14.499854) is used to measure the `optimal growth rate` based on the relative abundance of `FIVYWREL` aminoacids
  - Optimal growth rate is measured as follows,
```math
OGT = 937 * F_{IVYWREL} − 335
```


## Setup

### Conda

[Conda user guide](https://docs.conda.io/projects/conda/en/latest/user-guide/index.html)

```bash
# install miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh # follow the instructions
```

Getting the repository including sub-modules
```bash
git clone --recurse-submodules git@github.com:michoug/SnakemakeBinning.git
git checkout busi
```

Create the main `snakemake` environment

```bash
# create venv
conda env create -f requirements.yaml -n "snakemake"
```

### Run Setup
* Place your preprocessed/trim reads (e.g. `sample_r1.fastq.gz` and `sample_r2.fastq.gz` files) in a `reads` folder
* Place the individual assemblies (e.g. `sample.fa`) into an `assembly` folder
* Modify the `config/config.yaml` file to change the different paths and eventually the different options
* Modify the `config/all_samples.txt` file to include your samples

### Without Slurm

`snakemake -s workflow/Snakefile --configfile config/config.yaml --cores 28 --use-conda -rp`

### With Slurm

This part was mainly taken from [@susheelbhanu](https://github.com/susheelbhanu/) [nomis_pipeline](https://github.com/susheelbhanu/nomis_pipeline)

* Modify the `slurm.yaml` file by checking `partition`, `qos` and `account` that heavily depends on your system
* Modify the `sbatch.sh` file by checking `#SBATCH -p`, `#SBATCH --qos=` and `#SBATCH -A` options that heavily depends on your system

`sbatch config/sbatch.sh`

