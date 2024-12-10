ARG CONDA_ENV=for_container

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
FROM condaforge/mambaforge as build-env
# scope var from global
ARG CONDA_ENV

COPY ./load/* /opt/
RUN cd /opt \
    && git clone https://github.com/dwbellott/shims2_assembly_pipeline.git
RUN cd /opt/shims2_assembly_pipeline \
    && vendor/bin/carton install --cached --deployment

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# move to clean execution environment
FROM ubuntu
# scope var from global
ARG CONDA_ENV
COPY --from=build-env /opt/conda/envs/${CONDA_ENV} /opt/conda/envs/${CONDA_ENV}
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:$PATH

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# singularity doesn't use the -s flag, and that causes warnings
ENTRYPOINT ["/tini", "-s", "--"]
