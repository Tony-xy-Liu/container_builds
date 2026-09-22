#!/bin/bash
# dev script version 1.0

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
NAME=external_memote
DEV_USER=hallamlab
VER="0.9.13"
DOCKER_IMAGE=quay.io/$DEV_USER/$NAME

CONDA=mamba # https://mamba.readthedocs.io/en/latest/mamba-installation.html#mamba-install
echo image: $DOCKER_IMAGE:$VER
echo ""

case $1 in
    ###################################################
    # build

    -bd) # docker
        # pre-download requirements
        mkdir -p $HERE/lib
        cd $HERE/lib
        TINI_VERSION=v0.19.0
        ! [ -f tini ] && wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini
        cd $HERE

        # build the docker container locally
        export DOCKER_BUILDKIT=1
        docker build \
            --build-arg="CONDA_ENV=${NAME}_env" \
            --build-arg="PACKAGE=${NAME}" \
            --build-arg="VERSION=${VER}" \
            -t $DOCKER_IMAGE:$VER .
    ;;
    -bs) # apptainer image *from docker*
        apptainer build $NAME.sif docker-daemon://$DOCKER_IMAGE:$VER
    ;;

    ###################################################
    # upload

    -ud) # docker
        # login and push image to quay.io
        # sudo docker login quay.io
        docker push $DOCKER_IMAGE:$VER
        echo "!!!"
        echo "a new quay repository is private: make it public before anything pulls it"
        echo "https://$DOCKER_IMAGE?tab=settings"
    ;;

    ###################################################
    # run

    -rd) # docker
        shift
        mkdir -p ./scratch/docker
        docker run -it --rm \
            -u $(id -u):$(id -g) \
            --mount type=bind,source="$HERE/scratch/docker",target="/ws"\
            --workdir="/ws" \
            $DOCKER_IMAGE:$VER /bin/bash
    ;;
    -rs) # apptainer
        shift
        mkdir -p ./scratch/docker
        cd ./scratch/docker
        apptainer exec \
            --bind ./:/ws \
            --workdir /ws \
            $HERE/$NAME.sif /bin/bash
    ;;

    ###################################################
    # test

    --check) # apptainer: metaGEM's two memote commands on e_coli_core; run it where the tools run
        apptainer exec --cleanenv $HERE/$NAME.sif memote_check
    ;;

    ###################################################

    *)
        echo "bad option"
        echo $1
    ;;
esac
