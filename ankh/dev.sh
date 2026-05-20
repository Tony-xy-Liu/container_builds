#!/bin/bash
NAME=ankh
DEV_USER=hallamlab
DOCKER_IMAGE=quay.io/$DEV_USER/external_$NAME
VERSION=2026.05.19
echo image: $DOCKER_IMAGE:$VERSION
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        mkdir -p $HERE/load
        cd $HERE/load
        TINI_VERSION=v0.19.0
        ! [ -f tini ] && wget https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini
        cd $HERE

        export DOCKER_BUILDKIT=1
        docker build -t $DOCKER_IMAGE:$VERSION -t $DOCKER_IMAGE:latest .
    ;;
    --push|-p)
        # sudo docker login quay.io
        docker push $DOCKER_IMAGE:$VERSION
        docker push $DOCKER_IMAGE:latest
    ;;
    --sif)
        apptainer build $NAME.sif docker-daemon://$DOCKER_IMAGE:$VERSION
    ;;
    --run|-r)
        docker run -it --rm \
            --mount type=bind,source="$HERE",target="/ws" \
            --workdir="/ws" \
            $DOCKER_IMAGE:$VERSION \
            /bin/bash
    ;;
    --test|-t)
        docker run --rm $DOCKER_IMAGE:$VERSION \
            python -c "import torch, transformers, ankh; print('torch', torch.__version__); print('transformers', transformers.__version__); print('ankh', ankh.__version__ if hasattr(ankh, '__version__') else 'ok')"
    ;;
    *)
        echo "usage: dev.sh -b|-p|--sif|-r|-t"
    ;;
esac
