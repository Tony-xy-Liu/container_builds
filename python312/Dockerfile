ARG CONDA_ENV=for_container

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
FROM condaforge/miniforge3 as build-env
# scope var from global
ARG CONDA_ENV

# I believe this is to avoid permission issues with 
# manipulating added files to places like /opt
RUN old_umask=`umask` \
    && umask 0000 \
    && umask $old_umask

ADD ./load/env.yml /opt/env.yml
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create -n ${CONDA_ENV} --no-default-packages -f /opt/env.yml
ENV PATH=/opt/conda/envs/${CONDA_ENV}/bin:$PATH

# Singularity uses tini, but raises warnings
# because the -s flag is not used
ADD ./load/tini /tini
RUN chmod +x /tini
# ENTRYPOINT ["/tini", "-s", "-g", "--", "/app/entry"]
ENTRYPOINT ["/tini", "-s", "-g", "--"]
