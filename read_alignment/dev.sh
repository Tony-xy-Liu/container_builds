NAME=read_alignment
DOCKER_IMAGE=quay.io/hallamlab/external_$NAME
# DOCKER_IMAGE=quay.io/hallamlab/$NAME
VER=0.2
echo image: $DOCKER_IMAGE:$VER
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        # change the url in python if not txyliu
        # build the docker container locally *with the cog db* (see above)
        cd docker 
        docker build --build-arg VER=$VER -t $DOCKER_IMAGE:$VER .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    docker push $DOCKER_IMAGE:$VER
    ;;
    --sif)
        # test build singularity
        singularity build $NAME.sif docker-daemon://$DOCKER_IMAGE:$VER
    ;;
    --run|-r)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch",target="/ws" \
        docker run -it --rm \
            --mount type=bind,source="$HERE",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE:$VER \
            /bin/bash
    ;;
    -t)
        cd test

        # cp ../example.sh ./test.sh  
        docker run -it --rm \
            --mount type=bind,source="./",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE:$VER \
        /ws/test.sh
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
