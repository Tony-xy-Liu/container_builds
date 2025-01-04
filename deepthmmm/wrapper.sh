#!/bin/bash

# usage
# ./wrapper.sh get  # (get the container)
# ./wrapper.sh      # (run prediction)

# change these
OUT=./scratch/wrapper
IN=./scratch/Q9AFD7.fasta
CONTAINER=./scratch/apptainer/deeptmhm.sif

# maybe don't change these
HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
THIS=$(realpath $0) # path to this script

case $1 in
    # gets the container
    get)
        singularity pull ./deeptmhmm.sif docker://deeptmhmm/deeptmhmm:latest
    ;;

    # this happens second
    inner)
        IN=$2
        # source files must be in current directory
        ls /openprotein/ | xargs -I % ln -s /openprotein/% .

        # fix provided entry script trying to write to root
        rm predict.py
        entry_script=$(cat /openprotein/predict.py)
        problem="open('/deeptmhmm_results.md' , 'w')"
        solution="open('deeptmhmm_results.md' , 'w')"
        echo "${entry_script/$problem/$solution}" > predict.py

        # run the entry script
        python3 predict.py --fasta $IN
    ;;

    # this happens first
    *)
        # make output and workspace
        WORK=$OUT/_work
        if [ -d $WORK ]; then
            rm -r $WORK
        fi
        mkdir -p $WORK
        CONTAINER=$(realpath $CONTAINER)
        IN=$(realpath $IN)
        OUT=$(realpath $OUT)
        cd $WORK || exit 1

        # copy this script and input to workspace
        cp $THIS ./ || exit 1
        cp $IN ./ || exit 1
        LOCAL_IN=./$(basename $IN)
        LOCAL_THIS=./$(basename $THIS)

        # start container and restart this script from inside
        echo "starting container"
        singularity run -B ./:/ws $CONTAINER bash -c "cd /ws && $LOCAL_THIS inner $LOCAL_IN" || exit 1

        # copy results from workspace
        for result in TMRs.gff3 plot.png deeptmhmm_results.md predicted_topologies.3line probabilities embeddings; do
            cp -r $result $OUT
        done
    ;;
esac
