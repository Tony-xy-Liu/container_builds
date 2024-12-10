NAME=metawrap-smk
DOCKER_IMAGE=quay.io/txyliu/$NAME
echo image: $DOCKER_IMAGE
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        # change the url in python if not txyliu
        # build the docker container locally *with the cog db* (see above)
        cd docker 
        sudo docker build -t $DOCKER_IMAGE .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    sudo docker push $DOCKER_IMAGE:latest
    ;;
    --sif)
        # test build singularity
        sudo singularity build $NAME.sif docker-daemon://$DOCKER_IMAGE:latest
    ;;
    --run|-r)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch",target="/ws" \
            # --mount type=bind,source="$HERE/scratch/res",target="/ref"\
            # --mount type=bind,source="$HERE/scratch/res/.ncbi",target="/.ncbi" \
        docker run -it --rm \
            -e XDG_CACHE_HOME="/ws"\
            --mount type=bind,source="$HERE/test",target="/ws" \
            --mount type=bind,source="$HERE/test/checkm_db",target="/checkm_db" \
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE \
            /bin/bash
    ;;
    -t)
        PYTHONPATH=""
        
        # 3 binds
        singularity exec -B $LX_REF/checkm_src:/usr/local/lib/python2.7/site-packages/checkm,$LX_REF/checkm_data_2015_01_16:/checkm_db,./:/ws \
            $LX_REF/metawrap.sif metaWRAP binning -t 16 -m 60 --maxbin2 --metabat2 --concoct \
            -a /ws/metagenomic_assembly--9fb17d/SRR5326368.asm.fa \
            -o /ws/metagenomic_binning--88f730/SRR5326368_metawrap \
            --single-end /ws/metagenomic_binning--88f730/temp/f778aa.SRR5326368.fastq
        
        # 3 binds
        singularity exec -B $LX_REF/checkm_src:/usr/local/lib/python2.7/site-packages/checkm,$LX_REF/checkm_data_2015_01_16:/checkm_db,./:/ws \
            $LX_REF/metawrap.sif metaWRAP bin_refinement -t 16 -m 60 --quick -c 50 -x 10 \
            -A /ws/metagenomic_binning--7f2ea2/SRR6484432_metawrap/maxbin2_bins \
            -B /ws/metagenomic_binning--7f2ea2/SRR6484432_metawrap/concoct_bins \
            -o /ws/metagenomic_binning--7f2ea2/SRR6484432_metawrap_refine
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
