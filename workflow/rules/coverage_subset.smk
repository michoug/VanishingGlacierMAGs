rule coverage_subset:
    input:
        expand(os.path.join(RESULTS_DIR, "Assembly/{sample}_filter.fasta.sa"), sample = SAMPLES),
        expand(os.path.join(RESULTS_DIR, "TempReads/{sample_2}_sub_R1.fastq.gz"), sample_2 = SAMPLES_2),
        expand(os.path.join(RESULTS_DIR,"Bam/{sample}/{sample}_{sample_2}.bam"), sample = SAMPLES, sample_2 = SAMPLES_2)
    output:
        touch("status/coverage_subset.done")



rule filter_n_reads:
    input:
        reads1=os.path.join(READS_DIR, "{sample_2}_mg.r1.preprocessed.fq.gz"),
        reads2=os.path.join(READS_DIR, "{sample_2}_mg.r2.preprocessed.fq.gz")
    output:
        out1=temp(os.path.join(RESULTS_DIR, "TempReads/{sample_2}_sub_R1.fastq.gz")),
        out2=temp(os.path.join(RESULTS_DIR, "TempReads/{sample_2}_sub_R2.fastq.gz"))
    conda:
        os.path.join(ENV_DIR, "mapping.yaml")
    threads:
        config["filter_n_reads"]["threads"]
    params:
        config["filter_n_reads"]["read_p"]
    message:
        "Subset a proportion X of the reads for each sample.fq.gz pair"
    shell:
        "seqkit sample -j {threads} -p {params} -s 42 -o {output.out1} {input.reads1} && "
        "seqkit sample -j {threads} -p {params} -s 42 -o {output.out2} {input.reads2}"

rule filter_length:
    input:
        os.path.join(ASSEMBLY_DIR,"{sample}.fa")
    output:
        os.path.join(RESULTS_DIR,"Assembly/{sample}_filter.fasta")
    conda:
        os.path.join(ENV_DIR, "mapping.yaml")
    threads:
        config["filter_length"]["threads"]
    message:
        "Remove contigs less than 1.5kb"
    shell:
        "seqkit seq -j {threads} --remove-gaps -o {output} -m 1499 {input}"

rule mapping_index:
    input:
        rules.filter_length.output
    output:
        os.path.join(RESULTS_DIR,"Assembly/{sample}_filter.fasta.sa")
    log:
        os.path.join(RESULTS_DIR, "logs/mapping_{sample}.bwa.index.log")
    conda:
        os.path.join(ENV_DIR, "mapping.yaml")
    message:
        "Mapping: BWA index for assembly mapping"
    shell:
        "(date && bwa index {input} && date) &> {log}"

rule mapping:
    input:
        read1=rules.filter_n_reads.output.out1,
        read2=rules.filter_n_reads.output.out2,
        cont=rules.filter_length.output,
        idx=rules.mapping_index.output
    output:
        temp(os.path.join(RESULTS_DIR,"Bam/{sample}/{sample}_{sample_2}.bam"))
    threads:
        config["mapping"]["threads"]
    conda:
        os.path.join(ENV_DIR, "mapping.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/mapping/{sample}_{sample_2}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/mapping/{sample}_{sample_2}.err.log")
    message:
        "Running bwa to produce sorted bams"
    shell:
        "(date && bwa mem -t {threads} {input.cont} {input.read1} {input.read2} | samtools sort -@{threads} -o {output} - && " 
        "samtools index {output} && date) 2> {log.err} > {log.out}"
