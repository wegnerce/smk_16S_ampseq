###############################################################################
# @author:      Carl-Eric Wegner
# @affiliation: Küsel Lab - Aquatic Geomicrobiology
#              Friedrich Schiller University of Jena
#
#              carl-eric.wegner@uni-jena.de
#              https://github.com/wegnerce
#              https://www.exploringmicrobes.science
###############################################################################

rule quality_profiles:
	#
    input:
        expand("results/01_TRIMMED/{sample}_stripped_{pair}.fastq",
              sample=SAMPLES.index, pair=PAIRS)
    output:
        "results/02_DADA2_QUAL_PROFILES/{sample}-quality-profile.png"
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/quality-profile/{sample}-quality-profile-pe.log"
    script:
        "../scripts/quality_profiles.R"
        

rule filter_trim:
	#
    input:
        fwd="results/01_TRIMMED/{sample}_stripped_" + PAIRS[0] + ".fastq",
        rev="results/01_TRIMMED/{sample}_stripped_" + PAIRS[1] + ".fastq"
    output:
        filt="results/03_DADA2_TRIMMED/{sample}.1.fastq.gz",
        filt_rev="results/03_DADA2_TRIMMED/{sample}.2.fastq.gz",
        stats="results/03_DADA2_TRIMMED/filter-trim-pe/{sample}.tsv"
    params:
        maxEE=2,
        truncLen=[250,250],
        minLen=20
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/filter-trim-pe/{sample}.log"
    threads: 4 # set desired number of threads here
    script:
        "../scripts/filter_trim.R"


rule learn_pe:
    # Run twice dada2_learn_errors: on forward and on reverse reads
    input: expand("results/04_DADA2_ERROR_MODELS/model_{orientation}.RDS", orientation=[1,2])


rule learn_errors:
    # 
    input:
    # Quality filtered and trimmed forward FASTQ files (potentially compressed)
        expand("results/03_DADA2_TRIMMED/{sample}.{orientation}.fastq.gz",
               sample=SAMPLES.index, orientation = ["1", "2"])
    output:
        err="results/04_DADA2_ERROR_MODELS/model_{orientation}.RDS",
        plot="results/04_DADA2_ERROR_MODELS/errors_{orientation}.png",
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/learn-errors/learn-errors_{orientation}.log"
    threads: 4 # set desired number of threads here
    script:
        "../scripts/learn_errors.R"


rule derep_denoise_seqtab:
    input:
        R1=expand("results/03_DADA2_TRIMMED/{sample}.1.fastq.gz",
                  sample=SAMPLES.index),
        R2=expand("results/03_DADA2_TRIMMED/{sample}.2.fastq.gz",
                  sample=SAMPLES.index),
        errR1="results/04_DADA2_ERROR_MODELS/model_1.RDS",
        errR2="results/04_DADA2_ERROR_MODELS/model_2.RDS"
    output:
        seqtab="results/05_DADA2_SEQTAB/seqTab.RDS"
    params:
        samples=SAMPLES.index
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/derep_denoise_seqtab.txt"
    script:
        "../scripts/derep_denoise_seqtab.R" 
       
rule remove_chimeras:
    input:
        "results/05_DADA2_SEQTAB/seqTab.RDS",
    output:
        "results/06_DADA2_CHIMERACHECK/seqTab.nochim.RDS" 
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/remove-chimeras/remove-chimeras.log"
    threads: 4 # set desired number of threads here
    script:
        "../scripts/remove_chimeras.R"


rule assign_taxonomy:
    input:
        seqs="results/06_DADA2_CHIMERACHECK/seqTab.nochim.RDS", # Chimera-free sequence table
        refFasta="resources/silva_nr99_v138.1_train_set.fa.gz" # Reference FASTA for taxonomy
    output:
        "results/07_DADA2_TAX_ASSIGN/taxa.RDS" # Taxonomic assignments
    conda:
        "../envs/dada2.yaml"
    log:
        "logs/dada2/assign-taxonomy/assign-taxonomy.log"
    threads: 4 # set desired number of threads here
    script:
        "../scripts/assign_taxonomy.R"
