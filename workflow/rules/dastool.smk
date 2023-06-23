rule dastool:
    input:
       expand(os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/das_DASTool_summary.tsv"), sample = SAMPLES)
    output:
       touch("status/dastool.done")

rule prepare_dasTool:
    input:
        metabat=rules.metabat2.output,
        concoct=rules.concoct.output,
        metabinner=rules.metabinner.output
    output:
        metabatout=os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/metabat_das.tsv"),
        concoctout=os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/concoct_das.tsv"),
        metabinnerout=os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/metabinner_das.tsv")
    params:
        value="{sample}"
    conda: 
        os.path.join(ENV_DIR, "dastool.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/prepare_dasTool/{sample}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/prepare_dasTool/{sample}.err.log")
    message:
        "Preparing files for DasTool"
    shell:
        """
        (date && Fasta_to_Contig2Bin.sh -e fa -i {input.metabat} > {output.metabatout} && 
        perl -pe 's/metabat./{params.value}_metabat_/g' {output.metabatout} > t.txt && mv t.txt {output.metabatout} && 
        perl -pe 's/\t/\t{params.value}_metabinner_/g' {input.metabinner} > {output.metabinnerout} && 
        perl -pe 's/,/\t{params.value}_concoct_/g' {input.concoct} | tail -n +2 > {output.concoctout} && date) 2> {log.err} > {log.out}
        """


rule dasTool_run:
    input:
        metabat=rules.prepare_dasTool.output.metabatout,
        concoct=rules.prepare_dasTool.output.concoctout,
        metabinner=rules.prepare_dasTool.output.metabinnerout,
        cont=rules.filter_length.output
    output:
        os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/das_DASTool_summary.tsv")
    conda:
        os.path.join(ENV_DIR, "dastool.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/dasTool/{sample}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/dasTool/{sample}.err.log")
    threads:
        config["dasTool"]["threads"]
    message:
        "Running DasTool"
    shell:
        """
        (date && 
        DAS_Tool -i {input.concoct},{input.metabat},{input.metabinner} --score_threshold 0.3 -l concoct,metabat,metabinner -c {input.cont} -o $(dirname {output})/das --write_bins --search_engine diamond --threads {threads} && 
        date) 2> {log.err} > {log.out}        
        """
