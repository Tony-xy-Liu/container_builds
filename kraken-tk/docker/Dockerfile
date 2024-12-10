FROM condaforge/mambaforge as build-env
# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html

COPY ./load/* /opt/
RUN mamba env create --no-default-packages -f /opt/conda_env.yml

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# move to clean execution environment
FROM ubuntu
COPY --from=build-env /opt/conda/envs/for_container /opt/conda/envs/for_container
COPY --from=build-env /tini /tini
ENV PATH=/opt/conda/envs/for_container/bin:$PATH

# singularity doesn't use the -s flag, and that causes warnings
ENTRYPOINT ["/tini", "-s", "--"]
