###############################################################################
# @author:      Carl-Eric Wegner
# @affiliation: Küsel Lab - Aquatic Geomicrobiology
#              Friedrich Schiller University of Jena
#
#              carl-eric.wegner@uni-jena.de
#              https://github.com/wegnerce
#              https://www.exploringmicrobes.science
###############################################################################


rule fastqc_raw:
    # generate QC reports for the raw data
    input:
        read=raw_data_dir + "/{sample}_{pair}.fastq.gz",
    output:
        qual="logs/fastqc/raw/{sample}_{pair}_fastqc.html",
        zip="logs/fastqc/raw/{sample}_{pair}_fastqc.zip",
    resources:
        mem_mb=2000,
    conda:
        "../envs/fastqc.yaml"
    threads: 4
    shell:
        """
        fastqc {input.read} -t {threads} -f fastq --outdir logs/fastqc/raw
        """


rule bbduk_adapter:
    # adapter removal 
    input:
        read1=raw_data_dir + "/{sample}_" + PAIRS[0] + ".fastq.gz",
        read2=raw_data_dir + "/{sample}_" + PAIRS[1] + ".fastq.gz",
    output:
        read1="results/01_TRIMMED/{sample}_trimmed_" + PAIRS[0] + ".fastq.gz",
        read2="results/01_TRIMMED/{sample}_trimmed_" + PAIRS[1] + ".fastq.gz",
        trim_stats="logs/bbduk/{sample}_stats_QC_adapter.txt",
    resources:
        mem_mb=8000,
    conda:
        "../envs/bbmap.yaml"
    params:
        adapter=ADAPTER,
        settings=BBDUK_ADAPTER,
    threads: 8
    shell:
        """
        bbduk.sh -Xmx8g in1={input.read1} in2={input.read2} out1={output.read1} out2={output.read2} stats={output.trim_stats} ref={params.adapter} {params.settings}
        """

rule bbduk_primer:
    # primer removal 
    input:
        read1="results/01_TRIMMED/{sample}_trimmed_" + PAIRS[0] + ".fastq.gz",
        read2="results/01_TRIMMED/{sample}_trimmed_" + PAIRS[1] + ".fastq.gz",
    output:
        read1="results/01_TRIMMED/{sample}_stripped_" + PAIRS[0] + ".fastq",
        read2="results/01_TRIMMED/{sample}_stripped_" + PAIRS[1] + ".fastq",
        trim_stats="logs/bbduk/{sample}_stats_QC_primer.txt",
    resources:
        mem_mb=8000,
    conda:
        "../envs/bbmap.yaml"
    params:
        settings=BBDUK_PRIMER,
    threads: 8
    shell:
        """
        bbduk.sh -Xmx8g in1={input.read1} in2={input.read2} out1={output.read1} out2={output.read2} stats={output.trim_stats} {params.settings}
        rm -f {input.read1}       
        rm -f {input.read2}
        """


rule fastqc_trimmed:
    # generate QC reports for the trimmed data
    input:
        trimmed="results/01_TRIMMED/{sample}_stripped_{pair}.fastq",
    output:
        qual="logs/fastqc/trimmed/{sample}_stripped_{pair}_fastqc.html",
        zip="logs/fastqc/trimmed/{sample}_stripped_{pair}_fastqc.zip",
    resources:
        mem_mb=2000,
    conda:
        "../envs/fastqc.yaml"
    threads: 4
    shell:
        """
        fastqc {input.trimmed} -t {threads} -f fastq --outdir logs/fastqc/trimmed
        """
