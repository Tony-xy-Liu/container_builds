ARG CONDA_ENV=for_container

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
FROM condaforge/miniforge3 as conda
# scope var from global
ARG CONDA_ENV

# lel missing a lot of stuff

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

COPY ./load/* /opt/
RUN mamba env create -n ${CONDA_ENV} --no-default-packages -f /opt/env.yml
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# singularity doesn't use the -s flag, and that causes warnings
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-s", "--"]
