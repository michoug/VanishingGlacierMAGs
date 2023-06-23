rule coverage_all:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/cat_mags_cov_{sample_2}.txt"), sample_2 = SAMPLES_2),
        os.path.join(RESULTS_DIR, "cat_mags_cov.txt")
    output:
        touch("status/coverage.done")

# CONCATENATING MAGS
rule concatenate_mags:
    input:
        mags=os.path.join(RESULTS_DIR, "Bins/dRep/dereplicated_genomes")
    output:
        os.path.join(RESULTS_DIR, "concat/cat_mags.fa")
    message:
        "Concatenating all dereplicated MAGS"
    shell:
        "(date && cat {input}/*.fasta > {output} && date)"


rule mapping_all:
    input:
        read1=os.path.join(READS_DIR, "{sample_2}_mg.r1.preprocessed.fq.gz"),
        read2=os.path.join(READS_DIR, "{sample_2}_mg.r2.preprocessed.fq.gz"),
        cont=rules.concatenate_mags.output,
        #idx=rules.mapping_index.output
    output:
        temp(os.path.join(RESULTS_DIR, "Bam/cat_mags.fa.{sample_2}_mg.r1.preprocessed.fq.gz.bam"))
    threads:
        config["mapping"]["threads"]
    conda:
        os.path.join(ENV_DIR, "coverm.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/mapping/{sample_2}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/mapping/{sample_2}.err.log")
    message:
        "Running coverm to produce sorted bams for: {wildcards.sample_2}"
    shell:
        "(date && "
        "TMPDIR=. coverm make -r {input.cont} -t {threads} -o $(dirname {output}) --discard-unmapped -c {input.read1} {input.read2} && "
        "date) 2> {log.err} > {log.out}"

# COVERAGE
rule coverage:
    input:
        os.path.join(RESULTS_DIR, "Bam/cat_mags.fa.{sample_2}_mg.r1.preprocessed.fq.gz.bam")
    output:
        final=os.path.join(RESULTS_DIR, "Bins/cat_mags_cov_{sample_2}.txt")
#        temp=temp(os.path.join(RESULTS_DIR, "Bins/{sample}/{sample}_temp.txt")),
#        final=os.path.join(RESULTS_DIR, "Bins/{sample}/{sample}_cov.txt")
    conda:
        os.path.join(ENV_DIR, "coverm.yaml")        
    threads:
        config["mapping"]["threads"]
    priority: 
        50
    log:
        out=os.path.join(RESULTS_DIR, "logs/coverage/coverage_{sample_2}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/coverage/coverage_{sample_2}.err.log")
    message:
        "Estimating coverage for concatenated MAGs"
    shell:
        "(date && coverm contig -b {input} -m trimmed_mean -t {threads} -o {output.final} && date)" 
        " 2> {log.err} > {log.out}"

rule concat_coverage:
    input:
        files = expand(os.path.join(RESULTS_DIR, "Bins/cat_mags_cov_{sample_2}.txt"), sample_2 = SAMPLES_2),
        script=os.path.join(SRC_DIR,"mergeTables.pl")
    output:
        os.path.join(RESULTS_DIR, "cat_mags_cov.txt") 
    log:
        out=os.path.join(RESULTS_DIR, "logs/concat_coverage.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/concat_coverage.err.log")
    message:
        "Concatenating the coverage files"
    shell:
        "(date && perl {input.script} {input.files} {output} && date)"
        " 2> {log.err} > {log.out}"
