#######################################################################################
# container build dev. utility script
# version 1.0
#######################################################################################

NAME=opera_ms
DOCKER_IMAGE=quay.io/hallamlab/external_$NAME
# DOCKER_IMAGE=quay.io/txyliu/$NAME
# DOCKER_IMAGE=quay.io/hallamlab/$NAME
VERSION=0.9.0
echo image: $DOCKER_IMAGE:$VERSION
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        # pre-download requirements
        mkdir -p $HERE/lib
        cd $HERE/lib
        TINI_VERSION=v0.19.0
        ! [ -f tini ] && wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini
        ! [ -d OPERA-MS ] && git clone git@github.com:CSB5/OPERA-MS.git
        cd $HERE

        # build the docker container locally
        export DOCKER_BUILDKIT=1
        docker build \
            --build-arg="CONDA_ENV=${NAME}_env" \
            -t $DOCKER_IMAGE:$VERSION .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    docker push $DOCKER_IMAGE:$VERSION
    ;;
    --sif)
        # test build singularity
        singularity build $NAME.sif docker-daemon://$DOCKER_IMAGE:latest
    ;;
    --run|-r)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch/res",target="/ref"\
            # --mount type=bind,source="$HERE/scratch/res/.ncbi",target="/.ncbi" \
            # --mount type=bind,source="$HERE/test",target="/ws" \
            # -e XDG_CACHE_HOME="/ws"\
            
        docker run -it --rm \
            --mount type=bind,source="$HERE",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            /bin/bash 
    ;;
    -t1)
        # singularity run ./$NAME.sif bash
        docker run -it --rm \
            --mount type=bind,source="$HERE/scratch",target="/ws"\
            --workdir="/operams" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            bash -c "operams\
                --contig-file test_files/contigs.fasta\
                --short-read1 test_files/R1.fastq.gz\
                --short-read2 test_files/R2.fastq.gz\
                --long-read test_files/long_read.fastq\
                --no-ref-clustering \
                --out-dir /ws/RESULTS 2> /ws/log.err"
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
