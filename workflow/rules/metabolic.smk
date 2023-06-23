# Running METABOLIC on dereplicated MAGS
rule metabolic_all:
    input:
        expand(os.path.join(RESULTS_DIR, "metabolic/output"))
    output:
        touch("status/metabolic.done")

localrules: prep_metabolic_bins

# METABOLIC potential of bins
# NOTE: some adjustments to perl environments made based on here: https://github.com/AnantharamanLab/METABOLIC/issues/27
#rule prep_metabolic:
#    input:
#        os.path.join(RESULTS_DIR, "Bins/finalBins")
#    output:
#        sample=temp(os.path.join(RESULTS_DIR, "data/metabolic_samples.txt")),
#        tmpfile=temp(os.path.join(RESULTS_DIR, "data/reads.txt")),
#        reads=os.path.join(RESULTS_DIR, "data/metabolic_reads.txt")
#    message:
#        "Creating read mapping file for METABOLIC"
#    shell:
#        "(date && "
#        "while read -r line; do ls {input}/*.fa | grep -o \"$line\" ; done < {output.sample} > {output.tmpfile} && "
#        "sed 's@^@/work/projects/nomis/preprocessed_reads/@g' {output.tmpfile} | "
#        "sed 's@$@/mg.r1.preprocessed.fq@g' | "
#        "awk -F, '{{print $0=$1\",\"$1}}' | awk 'BEGIN{{FS=OFS=\",\"}} {{gsub(\"r1\", \"r2\", $2)}} 1' | "
#        "sed $'1 i\\\\\\n# Read pairs:' {output.reads}"     # using forward-slashes to get `\\\n`

rule prep_metabolic_bins:
    input:
        fa=os.path.join(RESULTS_DIR, "Bins/finalBins")
    output:
        dir=directory(os.path.join(RESULTS_DIR, "metabolic/input/finalBins")),
        dummy=os.path.join(RESULTS_DIR, "metabolic/input/rename.done")
    log:
        out=os.path.join(RESULTS_DIR, "logs/metabolic/symlink.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/metabolic/symlink.err.log"),
    message:
        "Symlinking the directory to change .fa to .fasta for the bins"
    shell:
        "(date && cp -vrf {input} {output.dir} && "
        "cd {output.dir} && rename -v 'fa' 'fasta' * && "
        "touch {output.dummy} && date) 2> {log.err} > {log.out}"

rule metabolic:
    input:
        fa=rules.prep_metabolic_bins.output.dir,
        dummy=rules.prep_metabolic_bins.output.dummy
    output:
        directory(os.path.join(RESULTS_DIR, "metabolic/output"))
    log:
        out=os.path.join(RESULTS_DIR, "logs/metabolic/metabolic.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/metabolic/metabolic.err.log")
    conda:
        os.path.join(ENV_DIR, "metabolic.yaml")
    params:
        gtdbtk=config["metabolic"]["db"],
        metabolic=config["metabolic"]["directory"]
    threads:
        config["metabolic"]["threads"]
    message:
        "Running METABOLIC-G for all MAGs"
    shell:
        "(date && "
        "export GTDBTK_DATA_PATH={params.gtdbtk} && "
        "export PERL5LIB && export PERL_LOCAL_LIB_ROOT && export PERL_MB_OPT && export PERL_MM_OPT && "
        """env PERL5LIB="" PERL_LOCAL_LIB_ROOT="" PERL_MM_OPT="" PERL_MB_OPT="" cpanm Array::Split && """
        "perl {params.metabolic}/METABOLIC-G.pl -t {threads} -in-gn {input.fa} -o {output} && "
        "date) 2> {log.err} > {log.out}"
