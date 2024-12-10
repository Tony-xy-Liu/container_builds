FROM condaforge/mambaforge as build-env

ENV CONDA_ENV "dram"
ADD https://raw.githubusercontent.com/WrightonLabCSU/DRAM/master/environment.yaml /opt/environment.yaml
RUN mamba env create --name ${CONDA_ENV} -f /opt/environment.yaml \
    && mamba clean -afy

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# use a smaller runtime image
# jammy is ver. 22.04 LTS
# https://wiki.ubuntu.com/Releases
FROM ubuntu:jammy
ENV CONDA_ENV "dram"
COPY --from=build-env /opt/conda/envs/${CONDA_ENV} /opt/conda/envs/${CONDA_ENV}
COPY --from=build-env /tini /tini
COPY ./dram /opt/conda/envs/${CONDA_ENV}/bin/

# add a slightly better launcher
ARG VER
RUN echo $VER>/opt/conda/envs/${CONDA_ENV}/bin/VERSION

ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:$PATH

# singularity doesn't use the -s flag, and that causes warnings
ENTRYPOINT ["/tini", "-s", "--"]
