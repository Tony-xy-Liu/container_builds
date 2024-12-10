HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

NAME=gtdbtk
VER=$(cat $HERE/docker/load/conda_env.yml | grep gtdbtk)
VER=${VER:11}
DOCKER_IMAGE=quay.io/txyliu/$NAME:$VER
echo image: $DOCKER_IMAGE
echo ""

case $1 in
    --build|-b)
        cd docker 
        sudo docker build -t $DOCKER_IMAGE .
    ;;
    --run|-r)
        docker run -it --rm \
            --mount type=bind,source="$HERE/data/release207_v2",target="/ref" \
            $DOCKER_IMAGE \
            /bin/bash
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    sudo docker push $DOCKER_IMAGE
    ;;
    --sif)
        # test build singularity
        singularity build cache/$NAME.sif docker-daemon://$DOCKER_IMAGE
    ;;
    -sr)
        # test build singularity
        singularity shell -B $HERE/data/release207_v2:/ref,$HERE/cache:/ws $HERE/cache/$NAME.sif
    ;;
    -t)
        # docker run -it --rm \
        #     --mount type=bind,source=$HERE/data/release207_v2,target=/ref \
        #     --mount type=bind,source=$HERE/cache,target=/ws \
        #     $DOCKER_IMAGE \
        singularity run -B $HERE/data/release207_v2:/ref,$HERE/cache:/ws $HERE/cache/$NAME.sif \
            gtdbtk classify_wf -x fa --cpus 12 \
                --genome_dir /ws/ins \
                --out_dir /ws/test1
    ;;
    *)
        echo "bad option [$1]"
    ;;
esac
