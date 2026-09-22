ARG CONDA_ENV=for_container

FROM condaforge/miniforge3
# scope var from global
ARG CONDA_ENV

# I believe this is to avoid permission issues with
# manipulating added files to places like /opt
RUN old_umask=`umask` \
    && umask 0000 \
    && umask $old_umask

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ADD ./lib/tini /tini
RUN chmod +x /tini

# singularity doesn't use the -s flag, and that causes warnings.
# -g kills process group on ctrl+C
ENTRYPOINT ["/tini", "-s", "-g", "--"]

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
# create conda env from yaml config
COPY ./envs/base.yml /opt/base.yml
# use an external cache for solved environments
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create -n ${CONDA_ENV} -f /opt/base.yml
# add bins to PATH so that the env appears "active"
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH
# apptainer binds $HOME, and a host ~/.local/lib/python3.12 otherwise shadows this env's packages.
ENV PYTHONNOUSERSITE=1

# --no-deps keeps pip from moving the conda pins. python-libsbml comes from PyPI because
# conda-forge has no 3.12 build of 5.20.x. No solver is installed: CPLEX is bound in at run time
# (PYTHONPATH), since 1.2.2's framed 0.5.1 speaks only CPLEX and Gurobi.
# CAUTION `import carveme` selects CPLEX at import time and raises without it, so nothing that
# imports carveme can run here or without that bind.
# The patch is the only edit to either package, and it changes container types, never values:
# Python 3.10 moved the container ABCs to collections.abc, and CPLEX 22 rejects the tuples and sets
# framed hands it where CPLEX 12.8 took any sequence. A framed it does not apply to fails the build.
COPY ./patches /opt/patches
RUN pip install --no-cache-dir --no-deps carveme==1.2.2 framed==0.5.1 python-libsbml==5.20.4 \
    && pip check \
    && patch -d $(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])') -p1 --forward \
        < /opt/patches/framed-0.5.1-py312-cplex22.patch

# The bundled bigg_proteins.dmnd is DIAMOND 0.9 format (build 95), which DIAMOND 2 refuses to open,
# and metaGEM pins diamond>=2.0.6. carveme_init's own last step rebuilds it from the bundled FASTA.
# Only that step runs here: carveme_init first re-downloads its inputs from CarveMe's master branch.
RUN D=$(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')/carveme/data/input \
    && diamond makedb --in $D/bigg_proteins.faa -d $D/bigg_proteins \
    && diamond dbinfo -d $D/bigg_proteins.dmnd | grep -qE '^ +Sequences +84674$'

COPY ./src /app/
