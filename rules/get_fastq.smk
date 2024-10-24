rule download_sra:
    output: 
        "data/fastq/{sra}/{sra}.sra"
    conda:
        "../envs/get-fastq.yml"
    log:
        out = "log/download_sra_{sra}.out",
        err = "log/download_sra_{sra}.err"
    shell: 
        """
        prefetch {wildcards.sra} -O fastq 2> {log.err} 1> {log.out}
        """

rule sra_to_fastq:
    # each sra is converted to 3 files based on paired-end reads: *_1.fastq [pair 1], *_2.fastq [pair 2], and *.fastq [reads without pairs]
    # subsample the fastq_sample option in config file is not empty
    input:
        "data/fastq/{sra}/{sra}.sra"
    output:
        f1 = temp("data/fastq/{sra}_1.fastq"),
        f2 = temp("data/fastq/{sra}_2.fastq")
    conda:
        "../envs/get-fastq.yml"
    threads: 10
    log:
        out = "log/sra_to_fastq_{sra}.out",
        err = "log/sra_to_fastq_{sra}.err"
    params:
        fastq_sample = config['fastq_sample'],
        seed = 100
    shell:
        """
        fasterq-dump -O data/fastq {input} 

        if [ -z "{params.fastq_sample}" ]
        then
            echo "no subsampling of fastq"
        else
            echo "subsample {params.fastq_sample} reads from fastq"
            seqtk sample -s{params.seed} {output.f1} {params.fastq_sample} > {output.f1}.TMP
            mv {output.f1}.TMP {output.f1}
            seqtk sample -s{params.seed} {output.f2} {params.fastq_sample} > {output.f2}.TMP
            mv {output.f2}.TMP {output.f2}
        fi
        """

rule gzip_fastq:
    input:
        "data/fastq/{sra}_{direction}.fastq"
    output:
        "data/fastq/{sra}_{direction}.fastq.gz"
    conda:
        "../envs/get-fastq.yml"
    log:
        out = "log/dump_fastq_{sra}_{direction}.out",
        err = "log/dump_fastq_{sra}_{direction}.err"
    shell:
        "gzip {input}"