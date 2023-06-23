# Running EggNog-Mapper on the concatenated bins

rule eggnog_all:
    input:
        expand(os.path.join(RESULTS_DIR, "eggnog/allMAGs_egg.txt.emapper.annotation"))
    output:
        touch("status/eggnog.done")


# Preparing the MAG files
rule multi_to_single:
    input:
        fa=os.path.join(RESULTS_DIR, "concat/cat_mags.fa")
    output:
        fixed_fa=os.path.join(RESULTS_DIR, "concat/cat_mags_fixed.fa")
    conda:
        os.path.join(ENV_DIR, "seqtk.yaml")
    message:
        "Converting multi-line FASTA to single line FASTA files"
    shell:
        "(date && seqtk seq {input.fa} > {output.fixed_fa} && date)"

# Preparing EGGNOG run
checkpoint prep_eggnog:
    input:
        fa=rules.multi_to_single.output.fixed_fa
    output:
        dir=directory(os.path.join(RESULTS_DIR, "split"))
    log:
        out=os.path.join(RESULTS_DIR, "logs/split/split.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/split/split.err.log")
    params:
        length=config["eggnog"]["split"]["length"],
        suffix=config["eggnog"]["split"]["suffix"]
    message:
        "Splitting the large concactenated MAGs into chunks of 2000000"
    shell:
        "(date && mkdir -p {output.dir} && "
        "split -l {params.length} -a {params.suffix} -d {input.fa} {output.dir}/mag_chunk_ && date) 2> {log.err} > {log.out}"

rule bin_link:
    input:
        os.path.join(RESULTS_DIR, "split/mag_chunk_{i}")
    output:
        os.path.join(RESULTS_DIR, "split_bins/mag_chunk_{i}.fa")
    message:
        "Creating dummy folder to make checkpoints easier && since split does not produce suffices"
    shell:
        "ln -vs {input} {output}"

# EGGNOG mapping to annotations
rule emapper:
    input:
        os.path.join(RESULTS_DIR, "split_bins/mag_chunk_{i}.fa")
    output:
        directory(os.path.join(RESULTS_DIR, "eggnog/{i}"))
    conda:
        os.path.join(ENV_DIR, "eggnog.yaml")
    threads:
        config["eggnog"]["threads"]
    log:
        out=os.path.join(RESULTS_DIR, "logs/eggnog/emapper_{i}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/eggnog/emapper_{i}.err.log")
    params:
        itype=config["eggnog"]["itype"],
        genepred=config["eggnog"]["genepred"],
        db=config["eggnog"]["db"]
    message:
        "Running EggNog-mapper on {wildcards.i}"
    shell:
        "(date && mkdir -p {output} && "
        "emapper.py -m diamond --data_dir {params.db} --itype {params.itype} --genepred {params.genepred} --no_file_comments --cpu {threads} -i {input} -o {wildcards.i} --output_dir {output} &&"
        "date) 2> {log.err} > {log.out}"


# Aggregating the checkpoints
def aggregate_emapper(wildcards):
    checkpoint_output = checkpoints.prep_eggnog.get(**wildcards).output[0]
    return expand(os.path.join(RESULTS_DIR, "eggnog/{i}"),
           i=glob_wildcards(os.path.join(checkpoint_output, "mag_chunk_{i}")).i)

localrules: bin_link, cat_emapper_out

rule cat_emapper_out:
    input:
        aggregate_emapper
    output:
        os.path.join(RESULTS_DIR, "eggnog/allMAGs.emapper_orthologs")
    log:
        out=os.path.join(RESULTS_DIR, "logs/eggnog/cat_seeds.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/eggnog/cat_seeds.err.log")
    message:
        "Cat EggNog-mapper output"
    shell:
        "(date && "
        "cat $(find $(dirname {output}) -name \"*.emapper.seed_orthologs\" | sort ) > tmp_seeds && "
        "sed '1!{{/^#qseqid/d;}}' tmp_seeds > {output} && rm -v tmp_seeds && date) 2> {log.err} > {log.out}"

rule emapper_final:
    input:
        rules.cat_emapper_out.output
    output:
        os.path.join(RESULTS_DIR, "eggnog/allMAGs_egg.txt.emapper.annotation")
    conda:
        os.path.join(ENV_DIR, "eggnog.yaml")
    threads:
        config["eggnog"]["final_threads"]
    log:
        out=os.path.join(RESULTS_DIR, "logs/eggnog/final_emapper.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/eggnog/final_emapper.err.log")
    params:
        itype=config["eggnog"]["itype"],
        genepred=config["eggnog"]["genepred"],
        db=config["eggnog"]["db"]
    message:
        "Running EggNog-mapper on All MAGs"
    shell:
        "(date && "
        "emapper.py --data_dir {params.db} --annotate_hits_table {input} --no_file_comments -o $(echo {output} | sed 's/.emapper.annotation//g' ) --cpu {threads} --dbmem && "
        "date) 2> {log.err} > {log.out}"
