#!/usr/bin/env bash
# Author: Lukas Jansen
# Licensed under the Academic Free License version 3.0
set -e

if (( $# < 1 )); then
    echo "Specifiy the install directory!"
    echo "runMetaErg.sh <installdir> [params to metaerg]"
    exit 1
fi

p=$(realpath "$1")

shift

condadir="$p/condaenv"

if [ -d "$condadir" ]; then
   echo "Activating conda env..."
   conda activate "$condadir" || source activate "$condadir"
fi

# Env variables for the different tools to run

perldir=$(realpath "$p/perllibs")
export MinPath=$p/MinPath/
export SIGNALP=$(echo $p/signalp-?.?/)
export PATH=$PATH:$p/metaerg/bin:$p/MinPath/:$p/rRNAFinder/bin:$(echo $p/signalp-?.?/bin):$(echo $p/signalp-?.?):$(echo $p/tmhmm-?.??/bin)
eval $(perl -I$perldir -Mlocal::lib=$perldir)

perl $(which check_tools.pl)

echo "$@"
perl $(which metaerg.pl) "$@"