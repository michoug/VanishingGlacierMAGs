# Snakefile to run MGThermometer on each MAG


# MAGS = glob_wildcards(os.path.join(INPUT_DIR, "{mags}.fna")).mags
# MAGS = glob_wildcards(os.path.join(RESULTS_DIR, "Bins/finalBins/{mags}.fa")).mags


rule mgthermometer:
    input:
        expand(os.path.join(RESULTS_DIR, "mgthermometer/table_OGT.txt"))
    output:
        touch("status/mgthermometer.done")


checkpoint countGenome:
    input:
        os.path.join(RESULTS_DIR, "Bins/finalBins")
    output:
        temp(directory(os.path.join(RESULTS_DIR, "Bins/tempBins")))
    shell:
        "mkdir {output} && cp {input}/*fasta {output}/"


def count_mags(wildcards):
    ck_output = checkpoints.countGenome.get(**wildcards).output[0]
    return expand(os.path.join(RESULTS_DIR,"mgthermometer/proportion_{mags}.txt"),
        mags=glob_wildcards(os.path.join(ck_output, '{mags}.fasta')).mags)


###############
# PRODIGAL
rule mgthermometer_run:
    input:
        fasta=os.path.join(RESULTS_DIR, "Bins/tempBins/{mags}.fasta"),
        script=os.path.join(SRC_DIR,"getFrequency.pl")
    output:
        protein = os.path.join(RESULTS_DIR, "mgthermometer/prodigal/{mags}.faa"),
        gff = os.path.join(RESULTS_DIR, "mgthermometer/prodigal/{mags}.gff"),
        nucl = os.path.join(RESULTS_DIR, "mgthermometer/prodigal/{mags}.ffn"),
        proportion=os.path.join(RESULTS_DIR, "mgthermometer/proportion_{mags}.txt")
    params:
        prefix="{mags}"
    conda:
        os.path.join(ENV_DIR, "mgthermometer.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/mgthermometer/{mags}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/mgthermometer/{mags}.err.log")
    message:
        "Prodigal annotation and Calculate proportion of IVYWREL for {wildcards.mags}"
    shell:
        "(date && "
        "prodigal -a {output.protein} -d {output.nucl} -f gff -i {input.fasta} -q -o {output.gff} && "
        "perl {input.script} {output.protein} {output.proportion} && "
        "date) 2> {log.err} > {log.out}"


rule concatResults:
    input:
        count_mags
    output:
        os.path.join(RESULTS_DIR, "mgthermometer/table_OGT.txt")
    shell:
        "(date && cat {input} > {output} && date)"

