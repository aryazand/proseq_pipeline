##################
#  recipes to create UCSC Genome Browser hub
##################

rule create_bigwig_symlinks:
    input:
        bw = "results/tracks/{sample}_{species}_{direction}.{ext}",
        gff3 = "data/genome/{species}/{genome}.gff"
    output:
        bw = "results/UCSCGenomeBrowser/{species}/{genome}/bw/{sample}_{species}_{direction}.{ext}"
    log:
        "log/create_symlinks_{sample}_{species}_{direction}_{genome}.{ext}.log"
    wildcard_constraints:
        direction = "for|rev",
        ext = "bw|fiveprime\.bw"
    shell:
        """
        ln -sr {input.bw} {output.bw}
        """


rule create_trackdb:
    # prepare a UCSC genome browser trackdb.txt file
    # TODO: add track colors
    input:
        samples = expand("results/UCSCGenomeBrowser/{{species}}/{{genome}}/bw/{sample}_{{species}}_{direction}.bw", 
                    sample = sample_names, 
                    direction = ['rev', 'for']),
        fiveprime_samples = expand("results/UCSCGenomeBrowser/{{species}}/{{genome}}/bw/{sample}_{{species}}_{direction}.fiveprime.bw", 
                    sample = sample_names, 
                    direction = ['rev', 'for']),
        bigbed = lambda wc: "results/UCSCGenomeBrowser/{species}/{genome}/{genome}.bb"
    output:
        trackdb_file = "results/UCSCGenomeBrowser/{species}/{genome}/trackDb.txt"
    log:
        "log/create_trackdb_{species}_{genome}.log"
    run:
        # create trackdb file
        with open(output.trackdb_file, 'w') as tf:
            
            track_db = [
                'track {}'.format(config["genomes"][wildcards.species]["genome_name"]),
                'type bigGenePred',
                'group map',
                'priority 1',
                'bigDataUrl {}'.format(os.path.basename(input.bigbed)),
                'longLabel {}'.format(config["genomes"][wildcards.species]["longlabel"]), 
                'shortLabel {}'.format(config["genomes"][wildcards.species]["shortlabel"]),
                'visibility pack',
                ''
            ]

            for sample in sample_names:

                #hex_color = config["track_colors"][group] if group in config["track_colors"] else "#000000"
                #track_color = tuple(int(hex_color[i:i+2], 16) for i in (1, 3, 5)) # convert to RGB
                
                track = [
                    '##############################################',
                    '',
                    'track {}'.format(sample),
                    'container multiWig',
                    'type bigWig',
                    'aggregate transparentOverlay',
                    'showSubtrackColorOnUi on',
                    'shortLabel {}'.format(sample),
                    'longLabel {}'.format(sample),
                    'visibility full',
                    'autoScale group',
                    'maxHeightPixels 100:50:8',
                    'type bigWig',
                    'priority 2',
                    '',
                    '\ttrack {}_for'.format(sample),
                    '\tparent {}'.format(sample),
                    '\tshortLabel {}_forwrad'.format(sample),
                    '\tlongLabel {}_forward'.format(sample),
                    '\tbigDataUrl bw/{}_for.bw'.format(sample + "_" + wildcards.species),
                    '\ttype bigWig',
                    '\tcolor 113,35,124',
                    '\taltColor 113,35,124',
                    '\tpriority 2.1',
                    '', 
                    '\ttrack {}_rev'.format(sample),
                    '\tparent {}'.format(sample),
                    '\tshortLabel {}_reverse'.format(sample),
                    '\tlongLabel {}_reverse'.format(sample),
                    '\tbigDataUrl bw/{}_rev.bw'.format(sample + "_" + wildcards.species),
                    '\ttype bigWig',
                    '\tnegateValues on',
                    '\tcolor 242,157,228', 
                    '\taltColor 242,157,228',
                    '\tpriority 2.2',
                    '',
                    'track {}_fiveprime'.format(sample),
                    'container multiWig',
                    'type bigWig',
                    'aggregate transparentOverlay',
                    'showSubtrackColorOnUi on',
                    'shortLabel {}'.format(sample),
                    'longLabel {}'.format(sample),
                    'visibility full',
                    'autoScale group',
                    'maxHeightPixels 100:50:8',
                    'type bigWig',
                    'priority 2',
                    '',
                    '\ttrack {}_fiveprime_for'.format(sample),
                    '\tparent {}_fiveprime'.format(sample),
                    '\tshortLabel {}_fiveprime_forward'.format(sample),
                    '\tlongLabel {}_fiveprime_forward'.format(sample),
                    '\tbigDataUrl bw/{}_for.fiveprime.bw'.format(sample + "_" + wildcards.species),
                    '\ttype bigWig',
                    '\tcolor 113,35,124',
                    '\taltColor 113,35,124',
                    '\tpriority 2.1',
                    '', 
                    '\ttrack {}_fiveprime_rev'.format(sample),
                    '\tparent {}_fiveprime'.format(sample),
                    '\tshortLabel {}_fiveprime_reverse'.format(sample),
                    '\tlongLabel {}_fiveprime_reverse'.format(sample),
                    '\tbigDataUrl bw/{}_rev.fiveprime.bw'.format(sample + "_" + wildcards.species),
                    '\ttype bigWig',
                    '\tnegateValues on',
                    '\tcolor 242,157,228', 
                    '\taltColor 242,157,228',
                    '\tpriority 2.2',
                    ''
                ]
                
                track_db += track

            tf.write('\n'.join(track_db))


rule create_hub:
    # create hub.txt file
    input:
        trackdb_file = lambda wc: "results/UCSCGenomeBrowser/{species}/" + config["genomes"][wc.species]["genome_name"] + "/trackDb.txt"
    output:
        hub_file = "results/UCSCGenomeBrowser/{species}/hub.txt"
    log:
        "log/create_hub_{species}.log"
    params:
        shortlabel = lambda wc: config["genomes"][wc.species]["shortlabel"],
        longlabel = lambda wc: config["genomes"][wc.species]["longlabel"],
        email = config["ucsc"]["email"],
    shell:
        """
        echo "hub {wildcards.species}" > {output.hub_file}
        echo "shortLabel {params.shortlabel}" >> {output.hub_file}
        echo "longLabel {params.longlabel}" >> {output.hub_file}
        echo "genomesFile genomes.txt" >> {output.hub_file}
        echo "email {params.email}" >> {output.hub_file}
        """

rule create_genometxt: 
    # create genomes.txt file
    input:
        trackdb_file = lambda wc: "results/UCSCGenomeBrowser/{species}/" + config["genomes"][wc.species]["genome_name"] + "/trackDb.txt",
        twobit_file = lambda wc: "results/UCSCGenomeBrowser/{species}/" + config["genomes"][wc.species]["genome_name"] + "/sequence.2bit"
    output:
        genomes_file = "results/UCSCGenomeBrowser/{species}/genomes.txt"
    log:
        "log/create_genometxt_{species}.log"
    params:
        genomes = lambda wc: config["genomes"][wc.species]["genome_name"],
        shortlabel = lambda wc: config["genomes"][wc.species]["shortlabel"],
        defaultPos = lambda wc: config["genomes"][wc.species]["ucsc-defaultPos"]
    shell:
        """
        trackdb_path=$(realpath --relative-base=$(dirname {output.genomes_file}) {input.trackdb_file})
        twobit_path=$(realpath --relative-base=$(dirname {output.genomes_file}) {input.twobit_file})
        echo "genome {params.genomes}" > {output.genomes_file}
        echo "description {params.shortlabel}" >> {output.genomes_file}
        echo "trackDb $trackdb_path" >> {output.genomes_file}
        echo "twoBitPath $twobit_path" >> {output.genomes_file}
        echo "organism {wildcards.species}" >> {output.genomes_file}
        echo "defaultPos {params.defaultPos}" >> {output.genomes_file}
        """

rule hubcheck:
    # use hubCheck to validate the hub
    input:
        hub = expand("results/UCSCGenomeBrowser/{species}/hub.txt", species = config["genomes"].keys())
    conda:
        "../envs/ucsc_hubcheck.yml"
    shell:
        "hubCheck {input.hub}"