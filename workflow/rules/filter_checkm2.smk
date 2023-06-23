rule filter_checkm2:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/filter_mags.tsv")),
        expand(os.path.join(RESULTS_DIR, "Bins/filter_mags/"))
    output:
        touch("status/filter_checkm2.done")

rule get_list_mags:
    input:
        tsv=expand(os.path.join(RESULTS_DIR, "Bins/{sample}/checkm2/quality_report.tsv"), sample = SAMPLES)
    output:
        os.path.join(RESULTS_DIR, "Bins/filter_mags.tsv")
    message:
        "Get list of MAGs that are more than 50% complete"
    shell:
        """(date && cat {input.tsv} | perl -pe "s/Name.*\n//g" | awk '$2>=50 {{print}}' | cut -f1 > {output} && date)"""

rule cp_mags:
    input:
        expand(os.path.join(RESULTS_DIR, "Bins/{sample}/DasTool/das_DASTool_summary.tsv"), sample = SAMPLES)
    output:
        temp(directory(os.path.join(RESULTS_DIR, "Bins/renamed_mags")))
    message:
        "Copy MAGs to another folder"
    shell:
        """(date && mkdir {output} && for file in $(dirname {input}); do cp $file/das_DASTool_bins/*fa {output}; done && date)"""

checkpoint get_filtered_mags:
    input:
        list=rules.get_list_mags.output,
        renamed=os.path.join(RESULTS_DIR, "Bins/renamed_mags")
    output:
        files=directory(os.path.join(RESULTS_DIR, "Bins/filter_mags/"))
    shell:
        """
        mkdir {output.files}
        while read -r line; do cp {input.renamed}/$line.fa {output.files}/$line.fa; done < {input.list}
        """

def get_file_names(wildcards):
    ck_output = checkpoints.get_filtered_mags.get(**wildcards).output[0]
    return expand(os.path.join(RESULTS_DIR,"Bins/mags_before_drep/{magsT}.fasta"),
        magsT=glob_wildcards(os.path.join(ck_output, '{magsT}.fa')).magsT)

