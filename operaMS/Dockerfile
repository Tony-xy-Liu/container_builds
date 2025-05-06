ARG CONDA_ENV=for_container
FROM condaforge/miniforge3 as conda
# scope var from global
ARG CONDA_ENV

# We do some umask munging to avoid having to use chmod later on,
# as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# singularity doesn't use the -s flag, and that causes warnings
COPY ./lib/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-s", "--"]

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git wget cpanminus build-essential
RUN apt-get install -y r-base default-jdk
# RUN git clone --single-branch --branch OPERA-MS-0.9.0 https://github.com/CSB5/OPERA-MS.git operams
COPY /lib/OPERA-MS /operams
WORKDIR /operams
RUN make

COPY ./load/base.yml /opt/
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create -n ${CONDA_ENV} --no-default-packages -f /opt/base.yml
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH

RUN perl OPERA-MS.pl check-dependency
COPY /load/entry /app/
