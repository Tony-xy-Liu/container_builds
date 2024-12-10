ARG CONDA_ENV=for_container

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
FROM condaforge/mambaforge as conda
# scope var from global
ARG CONDA_ENV

RUN apt update && apt install -y \
    xvfb 

COPY ./MINTIA_fork/environment.yaml     /opt/
COPY ./MINTIA_fork/set_env_config.sh    /opt/
COPY ./MINTIA_fork/setup.sh             /opt/
COPY ./MINTIA_fork/unset_env_config.sh  /opt/
RUN --mount=type=cache,target=/opt/conda/pkgs /opt/setup.sh ${CONDA_ENV} /opt/conda

COPY ./lib/* /app/
COPY ./MINTIA_fork/mintia /app/mintia
COPY ./MINTIA_fork/mintia.pl /app/mintia.pl
ENV PATH /app:$PATH

RUN echo ${CONDA_ENV} >/app/env_name
COPY ./load/entry /app/entry

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# # Singularity uses tini, but raises warnings
# # because the -s flag is not used
# ARG TINI
# COPY $TINI /tini
# RUN chmod +x /tini
# # ENV TINI_VERSION v0.19.0
# # ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
# # RUN chmod +x /tini
# ENTRYPOINT ["/tini", "-s", "-g", "--", "/app/entry"]
ENTRYPOINT ["/app/entry"]
