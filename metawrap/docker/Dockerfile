FROM condaforge/mambaforge as build-env

ENV CONDA_ENV "smk"
RUN mamba create --no-default-packages -y -n ${CONDA_ENV} \
    -c bioconda \
    snakemake=7

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# get metawrap container
FROM quay.io/biocontainers/metawrap-mg:1.3.0--hdfd78af_0
ENV CONDA_ENV "smk"
COPY --from=build-env /opt/conda/envs/${CONDA_ENV} /opt/conda/envs/${CONDA_ENV}
COPY --from=build-env /tini /tini
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:$PATH
COPY ./DATA_CONFIG /usr/local/lib/python2.7/site-packages/checkm/

# singularity doesn't use the -s flag, and that causes warnings
ENTRYPOINT ["/tini", "-s", "--"]
