# Preparing bins for dereplication and downstreams analyses
#

rule prep_bins:
    input:
        os.path.join(RESULTS_DIR, "Bins/mags_before_drep/renamed_mags.done")
    output:
        touch("status/bins_renamed.done")

# Renaming contig headers
rule rename:
    input:
        fasta=os.path.join(RESULTS_DIR, "Bins/filter_mags/MDMcleaner/{mags}/{mags}/{mags}_filtered_kept_contigs.fasta.gz")
    output:
        renamed=temp(os.path.join(RESULTS_DIR, "Bins/mags_before_drep/{mags}.fasta.gz")),
        final=os.path.join(RESULTS_DIR, "Bins/mags_before_drep/{mags}.fasta")
    conda:
        os.path.join(ENV_DIR, "bbmap.yaml")
    log:
        out=os.path.join(RESULTS_DIR, "logs/rename/rename_{mags}.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/rename/rename_{mags}.err.log")
    threads:
        config["bbmap"]["threads"]
    message:
        "Renaming contig headers for {wildcards.mag}"
    shell:
        "(date && "
        "rename.sh in={input.fasta} out={output.renamed} prefix={wildcards.mags} ignorejunk=t && "
        "gunzip -c {output.renamed} > {output.final} && "
        "date) 2> {log.err} > {log.out}"

rule check_rename:
    input:
        get_file_names_mm
    output:
        os.path.join(RESULTS_DIR, "Bins/mags_before_drep/renamed_mags.done")
    shell:
        "(date && echo {input} > {output} && date)"
