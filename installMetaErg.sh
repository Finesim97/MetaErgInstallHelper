#!/usr/bin/env bash
# Author: Lukas Jansen
# Licensed under the Academic Free License version 3.0
set -e


##### Edit me #####

signalparchive="signalp-4.1g.Linux.tar.gz" # Path to the signalp 4.1 tar.gz (5 doesn't work!)

tmhmmarchive="tmhmm-2.0c.Linux.tar.gz" # Path to the tmhmm tar.gz

signalptmhmm32bit=true # The 64bit executables included in SignalP/TMHMM don't work on our systems, if true, 32bit executables will be used instead

signalpMaxSequences=10000000000 # The default behaviour of SignalP is to accept only 20000 sequences, with more it just will exit without an error and do nothing.

silvaversion=132 # Version of the silva SSU/LSU to download

fixNoRRNACrash=true # The 1.0.2 version of MetaErg crashes if rRNAFinder doesn't finds any rRNA Fragments, if true, a patch will be applied, that may not work/be necessary for future versions

setupCondaEnv=true # Set this to false if the conda env should be managed by you or a workflow tool with Conda support like Snakemake
# The runMetaErg script detects the directory automatically, just delete the installdir/condaenv folder, if you change your mind later.

##################



if (( $# != 1 )); then
    echo "Only one parameter allowed!"
    echo "installMetaErg.sh <installdir>"
    exit 1
fi


shebangfix='1 s,^.*$,#!/usr/bin/env perl,'
unamefix="s/\`uname -m\`/'i386'/"

targetdir=$1
mkdir -p $targetdir
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Thanks to Dave Dopson https://stackoverflow.com/a/246128

echo "Extracting signalp..."
tar xzf $signalparchive -C $targetdir --overwrite
echo "Extracting tmhmm..."
tar xzf $tmhmmarchive -C $targetdir --overwrite

olddir=$(pwd)
cd $targetdir


#
# Signalp
#

signalpexec=$(echo signalp-?.?/signalp)
cp -v $signalpexec ${signalpexec}_original
chmod +x $signalpexec

echo "Adding write permission for you to the reference files, so you may actually delete them..."
chmod -R u+rw signalp-?.?

echo "Fixing signalp perl shebang..."
sed -i "$shebangfix" $signalpexec

echo "Removing forced env replacement..."
sed -E -i "s/\\\$ENV\\{SIGNALP\\} = '[^']+';//" $signalpexec

echo "Setting max sequence limit..."
sed -E -i "s/my \\\$MAX_ALLOWED_ENTRIES=[0-9]*;/my \\\$MAX_ALLOWED_ENTRIES=$signalpMaxSequences;/" $signalpexec

if [ "$signalptmhmm32bit" = true ] ; then
   echo "Forcing 32bit executables in signalp..."
   sed -i  "$unamefix" $signalpexec
fi

#
# tmhm
#

tmhmmexec=$(echo tmhmm-?.??/bin/tmhmm)
tmhmmformat=$(echo tmhmm-?.??/bin/tmhmmformat.pl)

cp -v $tmhmmexec ${tmhmmexec}_original
chmod +x $tmhmmexec
cp -v "$tmhmmformat" ${tmhmmformat}_original
chmod +x "$tmhmmformat"

echo "Fixing tmhmm perl shebang..."
sed -i "$shebangfix" $tmhmmexec

echo "Fixing tmhmmformat.pl perl shebang..."
sed -i "$shebangfix" $tmhmmformat

if [ "$signalptmhmm32bit" = true ] ; then
   echo "Forcing 32bit executables in tmhmm..."
   sed -i "$unamefix" $tmhmmexec
fi

#
# Conda Env
#

condadir="./condaenv"

if [ "$setupCondaEnv" = true ];  then
   echo "Creating conda env..."
   conda env create -f "$scriptdir/metaerg.yml" -p "$condadir" --force
   echo "Activating conda env..."
   echo "There can be error due to missing activation, but the source activate fallback might still work."
   conda activate "$condadir" || source activate "$condadir"
fi

#
# metaerg
#

echo "Downloading metaerg..."
wget "https://sourceforge.net/projects/metaerg/files/latest/download" -qO "metaerg.zip"

echo "Unzipping metaerg ..."
unzip -q -o metaerg.zip

if [ "$fixNoRRNACrash" = true ] ; then
   echo "Applying no rRNA found -> missing file -> crash fix ..."
   patch metaerg/bin/predictFeatures.pl << \EOM
226c226
<     my $cmd = "rRNAFinder.pl --threads $cpus --evalue $evalue --domain $gtype --outdir $outdir $fasta";
---
>     my $cmd = "rRNAFinder.pl --threads $cpus --evalue $evalue --domain $gtype --outdir $outdir $fasta && touch $outdir/rRNA.tax.txt";
EOM
fi

#
# rrnafinder
#

echo "Downloading rrnafinder..."
wget "https://sourceforge.net/projects/rrnafinder/files/latest/download" -qO "rrnafinder.zip"

echo "Unzipping rrnafinder..."
unzip -o -q rrnafinder.zip
echo "Adding executable bits..."
chmod +x rRNAFinder/bin/*.pl


#
# MinPath
#

echo "Downloading MinPath"
wget "http://omics.informatics.indiana.edu/mg/get.php?justdoit=yes&software=minpath1.4.tar.gz" -qO- | tar xzf -

mv MinPath/MinPath?.?.py MinPath/MinPath.py



#
# CAS hmms
#

echo "Downloading the casmodels from https://www.nature.com/articles/nature21059..."
wget "https://media.nature.com/original/nature-assets/nature/journal/v542/n7640/extref/nature21059-s3.zip" -qO "casmodels.zip"

echo "Unzipping the casmodels..."
unzip -q "casmodels.zip" nature21059-s3/SuppData6.Cas.profiles.incl_XYnovel9.db.hmm.zip

echo "Unzipping the casmodels (again)..."
unzip -q "nature21059-s3/SuppData6.Cas.profiles.incl_XYnovel9.db.hmm.zip" SuppData6.Cas.profiles.incl_XYnovel9.db.hmm 
mv SuppData6.Cas.profiles.incl_XYnovel9.db.hmm metaerg/db/hmm/casgenes.hmm

#
# Metabolic hmms
#

echo "Cloning the metabolic hmm repo..."
git clone https://github.com/banfieldlab/metabolic-hmms.git metabolic-hmms

echo "Converting the hmm with the wrong version..."
hmmconvert --outfmt 3/b metabolic-hmms/sulfide_quinone_oxidoreductase_sqr.hmm > metabolic-hmms/fixed_sulfide_quinone_oxidoreductase_sqr.hmm 
rm metabolic-hmms/sulfide_quinone_oxidoreductase_sqr.hmm

cat metabolic-hmms/*.hmm > metaerg/db/hmm/metabolic.hmm

#
# Perl libs
#

echo "Preparing perl local::lib..."
echo "The warning for SWISS is normal"
perldir=$(realpath "perllibs")
eval $(perl -I$perldir -Mlocal::lib=$perldir)
cpanm --force -l $perldir threads::shared "https://sourceforge.net/projects/swissknife/files/latest/download"

#
# metaerg dbs
#


# Env variables for the different tools to run

p=$(pwd)
export MinPath=$p/MinPath/
export SIGNALP=$(echo $p/signalp-?.?/)
export PATH=$PATH:$p/metaerg/bin:$p/MinPath/:$p/rRNAFinder/bin:$(echo $p/signalp-?.?/bin):$(echo $p/signalp-?.?):$(echo $p/tmhmm-?.??/bin)

echo "Using path:"
echo $PATH

echo "Dependency check:"
perl $(which check_tools.pl)

echo "Building rrnafinder dbs ..."
make_taxonclassify_db.pl $silvaversion

echo "Building metaerg dbs ..."
perl $(which build_db.pl)

cd $olddir