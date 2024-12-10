NAME=mintia
DOCKER_IMAGE=quay.io/hallamlab/external_$NAME
# DOCKER_IMAGE=quay.io/hallamlab/$NAME
echo image: $DOCKER_IMAGE
echo ""

HERE=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

case $1 in
    --build|-b)
        TINI_VERSION=v0.19.0
        TINI_LOCAL=lib/tini
        mkdir -p $HERE/lib
        if ! [ -f $HERE/$TINI_LOCAL ]; then
            wget -o $HERE/$TINI_LOCAL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini
        fi
        export DOCKER_BUILDKIT=1
        docker build \
            --build-arg="CONDA_ENV=${NAME}_env" \
            --build-arg="TINI=./${TINI_LOCAL}" \
            -t $DOCKER_IMAGE .
    ;;
    --push|-p)
        # login and push image to quay.io, remember to change the python constants in src/
        # sudo docker login quay.io
	    # docker push $DOCKER_IMAGE:latest
        echo "can't push, contains proprietary software"
    ;;
    --sif|-bs)
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
            $DOCKER_IMAGE 
    ;;
    -rs)
        # test run docker image
            # --mount type=bind,source="$HERE/scratch",target="/ws" \
            # --mount type=bind,source="$HERE/scratch/res",target="/ref"\
            # --mount type=bind,source="$HERE/scratch/res/.ncbi",target="/.ncbi" \
            # --mount type=bind,source="$HERE/test",target="/ws" \
            # --mount type=bind,source="$HERE/test/checkm_db",target="/checkm_db" \
            # -e XDG_CACHE_HOME="/ws"\
        
        singularity run -B ./scratch:/ws $NAME.sif /bin/bash
    ;;
    -t)
        threads=14
        asm_folder=/ws/test_s2_asm
        ann_folder=/ws/test_s2_ann

# mintia assemble t $threads -d $asm_folder \
#     -i \
#         /home/tony/workspace/tools/MINTIA/Data/Input/Assemble/BifidoAdolescentis.s2.R1.fq \
#         /home/tony/workspace/tools/MINTIA/Data/Input/Assemble/BifidoAdolescentis.s2.R2.fq \
#     -v /home/tony/workspace/tools/MINTIA/Data/Input/Assemble/pCC1FOS.fasta
#     
        docker run -it --rm \
            --mount type=bind,source="$HERE/scratch",target="/ws"\
            --mount type=bind,source="/home/tony/workspace/resources",target="/res"\
            --workdir="/ws" \
            -u $(id -u):$(id -g) \
            $DOCKER_IMAGE 
            # mintia annotate -t $threads -d $ann_folder \
            #     -i $asm_folder/BifidoAdolescentis.s2/scaffolds.fasta --separator . \
            #     --nrDB /res/nr/nr.dmnd \
            #     --uniprotDB /res/uniprot/uniprot_sprot.dmnd \
            #     --FunctionalAndTaxonomic \
            #     --Megan /ws/megan_trial_license \
            #     --Cog /res/cog/Cog.v3-28-17.00 \
                # --SubmissionFiles
    ;;

    -tm)
        threads=14
        asm_folder=./test_s2_asm
        ann_folder=./test_s2_ann

        # mintia assemble t $threads -d $asm_folder \
        #     -i \
        #         ./MINTIA_fork/Data/Input/Assemble/BifidoAdolescentis.s2.R1.fq \
        #         ./MINTIA_fork/Data/Input/Assemble/BifidoAdolescentis.s2.R2.fq \
        #     -v ./MINTIA_fork/Data/Input/Assemble/pCC1FOS.fasta
        #     

        mintia annotate -t $threads -d $ann_folder \
            -i $asm_folder/BifidoAdolescentis.s2/scaffolds.fasta --separator . \
            --nrDB ./external/nr.dmnd \
            --uniprotDB ./external/uniprot_sprot.dmnd \
            --FunctionalAndTaxonomic \
            --Megan license_not_needed_for_M6 \
            --Cog ./external/Cog.v3-28-17.00 \
            --SubmissionFiles
    ;;
    *)
        echo "bad option"
        echo $1
    ;;
esac
