# Running CheckM on the bins

localrules: 

rule checkm_all:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/{sample}/checkm2/quality_report.tsv"), sample = SAMPLES)
    output:
        touch("status/checkm2.done")

        
# Checking bin quality
rule checkm2:
    input:
        rules.dasTool_run.output
    output:
        tsv=os.path.join(RESULTS_DIR, "Bins/{sample}/checkm2/quality_report.tsv")
    conda:
        os.path.join(ENV_DIR, "checkm2.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/checkm/{sample}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/checkm/{sample}.err.log")
    threads:
        config["checkm2"]["threads"]
    params:
        ext=config["checkm2"]["extension"],
        db=config["checkm2"]["db"],
        checkm2=os.path.join(SUBMODULES, "bin/checkm2"),
    message:
        "Running CheckM2 for directory renamed bins"
    shell:
        "(date && touch {input} && " 
        "export CHECKM2DB={params.db} && "
        "{params.checkm2} predict --threads {threads} -x {params.ext} --input $(dirname {input})/das_DASTool_bins --output-directory $(dirname {output.tsv}) --force && "
        "date) 2> {log.err} > {log.out}"

