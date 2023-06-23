# Running CheckM on all the bins
rule checkm_all:
    input:
#         expand(os.path.join(RESULTS_DIR, "dir_00{number}"), number=["1", "2", "3", "4", "5"]),
        expand(os.path.join(RESULTS_DIR, "renamed_mags/checkm_{number}/checkm.tsv"), number=["1", "2", "3", "4", "5"]),
        expand(os.path.join(RESULTS_DIR, "Bins/checkmBeforedRep.tsv"))
    output:
        touch("status/checkm.done")

## Folder split
#rule split_bin_folder:
#    input:
#        os.path.join(RESULTS_DIR, "renamed_mags")
#    output:
#        dirs=directory(expand(os.path.join(RESULTS_DIR, "renamed_mags/dir_00{number}"), number=["1", "2", "3", "4", "5"])),
#        out=protected(os.path.join(RESULTS_DIR, "renamed_mags/split.done"))
#    log:
#        out=os.path.join(RESULTS_DIR, "logs/split/split.out.log"),
#        err=os.path.join(RESULTS_DIR, "logs/split/split.err.log")
#    message:
#        "Splitting the bins into folders of 3000 each"
#    shell:
#        "(date && cd {input} && "
#        """i=0; for f in *; do d=dir_$(printf %03d $((i/3000+1))); mkdir -p $d;ln -vs $PWD/"$f" $PWD/$d/"$f"; let i++; done && """
#        "touch {output.out} && date) 2> {log.err} > {log.out}"

# Checking bin quality
rule checkm:
    input:
        os.path.join(RESULTS_DIR, "renamed_mags/dir_00{number}")
    output:
        tsv=os.path.join(RESULTS_DIR, "renamed_mags/checkm_{number}/checkm.tsv")
    conda:
        os.path.join(ENV_DIR, "checkm.yaml")
    wildcard_constraints:
        number="|".join(["1", "2", "3", "4", "5"])
    log:
        out=os.path.join(RESULTS_DIR, "logs/checkm/dir_00{number}_checkm.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/checkm/dir_00{number}_checkm.err.log")
    threads:
        config["checkM"]["threads"]
    message:
        "Running CheckM for directory: {wildcards.number}"
    shell:
        "(date && "
        "checkm lineage_wf -t {threads} --file {output.tsv} -x fa {input} $(dirname {output.tsv}) && "
        "date) 2> {log.err} > {log.out}"
        
rule cat_checkm:
    input:
        expand(os.path.join(RESULTS_DIR, "renamed_mags/checkm_{number}/checkm.tsv"), number=["1", "2", "3", "4", "5"])
    output:
        check=os.path.join(RESULTS_DIR, "Bins/checkm_all.tsv")
    log:
        out=os.path.join(RESULTS_DIR, "logs/checkm/cat_checkm.out.log"),
        err=os.path.join(RESULTS_DIR, "logs/checkm/cat_checkm.err.log")
    message:
        "Concatenating CheckM outputs and remove duplicate extra lines"
    shell:
        """(date && cat {input} | sed '/^--/d' | perl -pe "s/Bin.*\\n//g" > {output} && date) 2> {log.err} > {log.out}"""

rule dRep_prepare:
    input:
        check=os.path.join(RESULTS_DIR, "Bins/checkm_all.tsv")
    output:
        final=os.path.join(RESULTS_DIR, "Bins/checkmBeforedRep.tsv"),
        temp=temp(os.path.join(RESULTS_DIR, "Bins/checkm_temp.tsv"))
    message:
        "Adjusting CheckM output for input to dRep"
    shell:
        """
        awk '{{print $1".fa,"$13","$14}}' {input.check} | perl -pe "s/Bin.*\\n//g" > {output.temp} && 
        (echo "genome,completeness,contamination" && cat {output.temp}) > {output.final}
        """
