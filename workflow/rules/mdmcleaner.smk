# Snakefile to run MDMcleaner on each MAG

rule mdmcleaner_all:
    input:
        os.path.join(RESULTS_DIR, "Bins/mags_before_drep/MDMCleaner.done")
    output:
        touch("status/mdmcleaner.done")


################
# MDMCleaner setup
rule mdmcleaner_db:
    output:
        db=os.path.join(DB_DIR, "MDMcleaner/"),
        conf=os.path.join(DB_DIR, "mdmcleaner.config")
    log:
        os.path.join(RESULTS_DIR, "logs/mdmcleaner_db.log")
    conda:
        os.path.join(ENV_DIR, "mdmcleaner.yaml")
    message:
        "Downloading the MDMCleanerDB and create the config file"
    shell:
        "(date && mdmcleaner makedb -o {output.db} && "
        "mdmcleaner set_configs -s local --db {output.db} && "
        "mv mdmcleaner.config {output.conf} &> {log} && "
        "date) &> {log}"

################
# MDMcleaner run
rule mdmcleaner:
    input:
        file=os.path.join(RESULTS_DIR, "Bins/filter_mags/{magsT}.fa"),
        config=rules.mdmcleaner_db.output.conf
    output:
        out=directory(os.path.join(RESULTS_DIR, "Bins/MDMcleaner/{magsT}")),
        done=os.path.join(RESULTS_DIR, "Bins/MDMcleaner/{magsT}.done"),
        renamed=os.path.join(RESULTS_DIR, "Bins/mags_before_drep/{magsT}.fasta.gz"),
        final=os.path.join(RESULTS_DIR, "Bins/mags_before_drep/{magsT}.fasta")
    threads:
        config["mdmcleaner"]["threads"]
    params:
        final=os.path.join(RESULTS_DIR, "Bins/MDMcleaner/{magsT}/{magsT}/{magsT}_filtered_kept_contigs.fasta.gz"),
        prefix="{magsT}"
    conda:
        os.path.join(ENV_DIR, "mdmcleaner.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/mdmcleaner/{magsT}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/mdmcleaner/{magsT}.err.log")
    message:
        "Running MDMCleaner"
    shell:
        """
        (date && mdmcleaner clean -i {input.file} -o {output.out} -c {input.config} -t {threads} --fast_run &&
        if [[ -f {params.final} ]] ; then
            touch {output.done}
        fi && 
        rename.sh in={params.final} out={output.renamed} prefix={params.prefix} ignorejunk=t && 
        gunzip -c {output.renamed} > {output.final} &&
        date) 2> {log.err} > {log.out}
        """

rule check_rename:
    input:
        get_file_names
    output:
        os.path.join(RESULTS_DIR, "Bins/mags_before_drep/MDMCleaner.done")
    shell:
        "(date && echo {input} > {output} && date)"
