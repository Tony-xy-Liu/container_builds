NAME=coverm
DOCKER_IMAGE=quay.io/hallamlab/external_$NAME
# DOCKER_IMAGE=quay.io/hallamlab/$NAME
VER=0.6.1
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
            --mount type=bind,source="$HERE/test",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE:$VER \
            /bin/bash
    ;;
    -t)
        cd test
        # docker run -it --rm \
        #     --mount type=bind,source="./mag_annotator",target="/opt/conda/envs/dram/lib/python3.10/site-packages/mag_annotator" \
        #     --mount type=bind,source="./",target="/ws" \
        #     --workdir="/ws" \
        #     -u $(id -u):$(id -g) \
        #     $DOCKER_IMAGE \
        #     DRAM-setup.py prepare_databases --output_dir /ws

        #coverm genome -p minimap2-pb --single /home/ubuntu/LR_trials/AD118I/AD118I.fastq -d /home/ubuntu/LR_trials/coassembly/Bins/ -x "fa" --output-file coverm_results/relative_abundance/AD118I.txt -m relative_abundance
        docker run -it --rm \
            --mount type=bind,source="./",target="/ws" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE:$VER \
            coverm genome -p minimap2-sr -m mean \
                --bam-file-cache-directory ./bam_cache \
                --output-format dense \
                --single ./reads/SRR10053317.fastq.gz \
                -d ./bins/ -x fa \
                --output-file ./coverm_testout
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
