NAME=treesapp_mirror
DOCKER_IMAGE=quay.io/hallamlab/$NAME
echo image: $DOCKER_IMAGE
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        # change the url in python if not txyliu
        # build the docker container locally *with the cog db* (see above)
        cd docker 
        docker build -t $DOCKER_IMAGE .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    docker push $DOCKER_IMAGE:latest
    ;;
    --sif)
        # test build singularity
        singularity build $NAME.sif docker-daemon://$DOCKER_IMAGE:latest
    ;;
    --run|-r)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch",target="/ws" \
            # --mount type=bind,source="$HERE/scratch/res",target="/ref"\
            # --mount type=bind,source="$HERE/scratch/res/.ncbi",target="/.ncbi" \
            # --mount type=bind,source="$HERE/test",target="/ws" \
            # --mount type=bind,source="$HERE/test/checkm_db",target="/checkm_db" \
            # -e XDG_CACHE_HOME="/ws"\
            
        docker run -it --rm \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            /bin/bash 
    ;;
    -t)
        # #
        # # scratch space for testing stuff
        # #
        # cd $HERE/src
        # # # python -m simple_meta setup -ref $HERE/scratch/test1/ref -c docker
        # # python -m simple_meta run -ref $HERE/scratch/res -i SRR19573024 -o $HERE/scratch/test2/ws -t 16
        # # # --mock

        # # python -m simple_meta setup -ref $HERE/scratch/res -c singularity
        # python -m simple_meta run -r $HERE/scratch/res -i SRR19573024 -o $HERE/scratch/test3/ws -t 14

        docker run -it --rm \
            --mount type=bind,source="$HERE/scratch",target="/ws"\
            --workdir="/ws" \
            -e MPLCONFIGDIR="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            treesapp info
            # /bin/bash 
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
