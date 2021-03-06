# MetaErgInstallHelper
One script to help with the installation of **MetaErg**, the contig/bin annotation pipeline.

## What is MetaErg?
[MetaErg](https://github.com/xiaoli-dong/metaerg) is a set of Perl scripts describing a **full** annotation workflow for metagenomic/proteomic contigs using HMMER, Diamond and a few feature prediction tools, that produces summary files (including tbl and gff3) and an overview report. Using MinPath, MetaCyc and KEGG Pathways are reconstructed from the functional annotation (KO,GO and EC numbers are available!). You could compare it to [Prokka](https://github.com/tseemann/prokka), but it is better suited for meta samples.

Due to the nature of the bioinformatic hell, the pipeline has a few dependencies which need to be installed and sometimes modified. This repo provides a script to ease the installation process. If something isn't working, feel free to contact me.

## Usage (Last tested with 1.2.1, October 2019)

The availability of Conda is assumed. If it is not installed on your system, please follow the installation [described here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html) and also run `conda init --all`. After installing you need to open a new shell to have it available. 

You first need to download the script. 

``` sh
wget https://raw.githubusercontent.com/Finesim97/MetaErgInstallHelper/master/installMetaErg.sh
```

You will also need to download [SignalP 5](http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?signalp) and [TMHMM](http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?tmhmm). Place the downloaded `.tar.gz` in your current working directory.

``` sh
# ls -l
-rw-r--r--  1 lu6085 studenten        2131 Okt 18 12:50 installMetaErg.sh
-rw-r--r--  1 lu6085 studenten    45239117 Jun 19 10:13 signalp-5.0b.Linux.tar.gz
-rw-r--r--  1 lu6085 studenten     1174180 Okt 18 11:25 tmhmm-2.0c.Linux.tar.gz
```


After that you either can run the installation or include it in your workflow scripts.

``` sh
bash installMetaErg.sh metaerginstall 2>&1 | tee metaErgInstallLog.txt
# metaerginstall will be the directory with the installation and dependencies.
```

You will also need the reference files for metaerg.  The following commands will install the database into MetaErgs default database directory. 
Download them from their server with:
``` sh
wget http://ebg.ucalgary.ca/metaerg/db.tar.gz
tar xzvf db.tar.gz -C metaerginstall/metaerg/
```

Or build them yourself:
``` sh
source activate metaerginstall
setup_db.pl -o metaerginstall/metaerg -v 132 # SILVA version
```

Now you can run MetaErg (if you didn't install the database to the default location, you have to add the -db option.)
``` sh
source activate metaerginstall
metaerg.pl --help
metaerg.pl  --depth metaerginstall/metaerg/example/demo.depth.txt metaerginstall/metaerg/example/demo.fna --sp --tm --outdir "metaergtest" --cpus 8
```

Remeber to cite:
[Dong X and Strous M (2019) An Integrated Pipeline for Annotation and Visualization of Metagenomic Contigs. Front. Genet. 10:999. doi: 10.3389/fgene.2019.00999](https://www.frontiersin.org/articles/10.3389/fgene.2019.00999/full)