# GTDBTK taxonomy
rule gtdbtk_all:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/gtdbtk_final"))
    output:
        touch("status/gtdbtk.done")

rule gtdbtk:
    input:
        rules.dRep.output.final
    output:
        directory(os.path.join(RESULTS_DIR, "Bins/gtdbtk_final"))
    log:
        os.path.join(RESULTS_DIR, "logs/gtdbtk.log")
    conda:
        os.path.join(ENV_DIR, "gtdbtk.yaml")
    params:
        config["gtdbtk"]["path"]
    threads:
        config["gtdbtk"]["threads"]
    message:
        "Running GTDB on MAGs"
    shell:
        "(date && export GTDBTK_DATA_PATH={params} && gtdbtk classify_wf --cpus {threads} -x fa --genome_dir {input} --out_dir {output} && date) &> >(tee {log})"

