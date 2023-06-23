rule dereplicate:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/finalBins"))
    output:
        touch("status/dereplicate.done")

rule checkmBeforeDrep:
    input:
        os.path.join(RESULTS_DIR, "Bins/mags_before_drep/MDMCleaner.done")
    output:
        tsv=os.path.join(RESULTS_DIR, "Bins/checkm2/quality_report.tsv")
    conda:
        os.path.join(ENV_DIR, "checkm2.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/checkm_beforeDrep.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/checkm_beforeDrep.err.log")
    threads:
        config["checkm2"]["threads"]
    params:
        ext=config["checkm2"]["extension"],
        db=config["checkm2"]["db"],
        checkm2=os.path.join(SUBMODULES, "bin/checkm2"),
    message:
        "Running CheckM2 for directory renamed bins"
    shell:
        "(date && "
        "export CHECKM2DB={params.db} && "
        "{params.checkm2} predict --threads {threads} -x fasta --input $(dirname {input}) --output-directory $(dirname {output.tsv}) --force && "
        "date) 2> {log.err} > {log.out}"

rule dRep_prepare:
    input:
        check=rules.checkmBeforeDrep.output.tsv
    output:
        final=os.path.join(RESULTS_DIR, "Bins/checkm2BeforedRep.tsv"),
        temp=temp(os.path.join(RESULTS_DIR, "Bins/checkm2_temp.tsv"))
    message:
        "Adjusting CheckM output for input to dRep"
    shell:
        """
        cat {input.check} | sed '/^Name/d' | awk '{{print $1".fasta,"$2","$3}}' > {output.temp} &&
        (echo "genome,completeness,contamination" && cat {output.temp}) > {output.final}
        """


# Dereplicating the genomes
rule dRep:
    input:
        bins=rules.checkmBeforeDrep.input,
        check=os.path.join(RESULTS_DIR, "Bins/checkm2BeforedRep.tsv"),
        status="status/mdmcleaner.done"
    output:
        temp=directory(os.path.join(RESULTS_DIR, "Bins/dRep/dereplicated_genomes")),
        final=directory(os.path.join(RESULTS_DIR, "Bins/finalBins"))
    conda:
        os.path.join(ENV_DIR, "drep.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/drep/drep.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/drep/drep.err.log")
    params:
        comp=config["dRep"]["comp"],
        cont=config["dRep"]["cont"]
    threads:
        config["dRep"]["threads"]
    message:
        "Running dRep on all NOMIS MAGs"
    shell:
        "(date && "
        "dRep dereplicate $(dirname {output.temp}) -p {threads} -comp {params.comp} -con {params.cont} --genomeInfo {input.check} -g $(dirname {input.bins})/*fasta -d && "
        "cp -r {output.temp} {output.final} && date) 2> {log.err} > {log.out}"
