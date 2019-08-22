# MetaErgInstallHelper
A few scripts to help with the installation of **MetaErg**, the contig/bin annotation pipeline.

## What is MetaErg?
[MetaErg](https://sourceforge.net/projects/metaerg/) is a set of Perl scripts describing a **full** annotation workflow for metagenomic/proteomic contigs using HMMER, Diamond and a few feature prediction tools, that produces summary files (including tbl and gff3) and an overview report. Using MinPath, MetaCyc and KEGG Pathways are reconstructed from the functional annotation (KO,GO and EC numbers are available!). You could compare it to [Prokka](https://github.com/tseemann/prokka), but it is better suited for meta samples.

Due to the nature of the bioinformatic hell, the pipeline has a few dependencies which need to be installed and sometimes modified. This repo prrovides scripts to ease the installation process. If something isn't working, feel free to contact me.

## Usage (Last tested with 1.0.2, August 2019)

The availability of Conda is assumed. If it is not installed on your system, please follow the installation [described here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html)

You first need to download the scripts. The easiest way to do that is just to clone the repository:

``` sh
git clone https://github.com/Finesim97/MetaErgInstallHelper.git metaergscripts
# metaergscripts will be the directory that stores the scripts from this repo
```

You will also need to download [SignalP 4.1](http://www.cbs.dtu.dk/cgi-bin/sw_request?signalp+4.1)(**5 doesn't work**) and [TMHMM](http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?tmhmm). Place the downloaded `.tar.gz` in your current working directory, next to the metaergscripts folder.

Next you have to check the configuration of the installer. 

``` sh
nano metaergscripts/installMetaErg.sh
```

After that you either can run the installation or include in your workflow scripts (see below for a Snakemake example).

``` sh
bash metaergscripts/installMetaErg.sh metaerginstall | tee metaErgInstallLog.txt
# metaerginstall will be the directory with the installation and dependencies. This may take a while.
```

Now you can run MetaErg with the `runMetaErg.sh` script:

``` sh
bash metaergscripts/runMetaErg.sh metaerginstall -h
bash metaergscripts/runMetaErg.sh metaerginstall --sp --tm --outdir metaerg_test --prefix test --locustag metaerg_test metaerginstall/metaerg/examples/test.fasta | tee metaErgTestLog.txt
```

Remember to honor the licenses of the the used tools and cite them in your work, including the [Metabolic HMMs](https://doi.org/10.1038/s41396-018-0078-0) and the [CAS HMMs](https://doi.org/10.1038/nature21059).


## Snakemake Example
After cloning the repo, setting `setupCondaEnv` to `false` and downloading SignalP and TMHMM you can setup two rules like that:

``` python
#
# Install MetaErg
#
rule installMetaErg:
	input:
		"signalp-4.1g.Linux.tar.gz",
		"tmhmm-2.0c.Linux.tar.gz",
		script="metaergscripts/installMetaErg.sh"
	output:
		directory("metaerg")
	log:
		"install_metaerg.log"
	conda:
		"metaerg.yaml"
	threads:
		32
	shell:
		"bash {input.script} {output} &> {log}"
#
# Run MetaErg
#
rule metaergsample:
	input:
		installdir=rules.installMetaErg.output,
		bin=rules.megahitassembly.output.contigs,
		depthmat=rules.assemblycoverage.output.depthmatrix,
		script="metaergscripts/runMetaErg.sh"
	output:
		reportdir="metaerg/{sample}"
	log:
		"metaerg/{sample}.log"
	params:
		mincontiglen=config["mincontiglen_metaerg"], #200
		minorff=config["minorfflen_metaerg"], #100
	conda:
		"metaerg.yaml"
	shadow:
		"full" # TMHMM places its temp directory in the working directory.
	threads:
		32 # MetaErg Runs multiple hmmer jobs in parallel with --cpus cores
	shell:
		"bash {input.script} {input.installdir} --mincontiglen {params.mincontiglen} --minorflen {params.minorff} --sp --tm --outdir {output.reportdir} --cpus 8 --depth {input.depthmat} {input.bin} --force &> {log}"

```
