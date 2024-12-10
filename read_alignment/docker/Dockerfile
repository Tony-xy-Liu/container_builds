# this is global and used for
#   - conda env yml file name
#   - conda env name
ARG CONDA_ENV=for_container

FROM condaforge/mambaforge as build-env
# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html

# scope var from global
ARG CONDA_ENV

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY ./conda_env.yml /opt/
RUN mamba env create --no-default-packages -f /opt/conda_env.yml

# move to clean execution environment
# jammy is ver. 22.04 LTS
# https://wiki.ubuntu.com/Releases
FROM ubuntu:jammy
# scope var from global
ARG CONDA_ENV
COPY --from=build-env /tini /tini
COPY --from=build-env /opt/conda/envs/${CONDA_ENV} /opt/conda/envs/${CONDA_ENV}

# permanently activate env 
ENV PATH=/opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# singularity doesn't use the -s flag, and that causes warnings
ENTRYPOINT ["/tini", "-s", "--"]
