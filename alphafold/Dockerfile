FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04
ARG CONDA_ENV=for_container
ARG MAMBA_VER

# I believe this is to avoid permission issues with 
# manipulating added files to places like /opt
RUN old_umask=`umask` \
    && umask 0000 \
    && umask $old_umask

ADD ./load/alphafold /opt/alphafold

ENV DEBIAN_FRONTEND noninteractive
RUN mv /var/lib/dpkg/info/libc-bin.* /tmp/ \
    && apt update \
    && apt-get update \
    && apt install -y libc-bin vim wget \
    && apt-get install --no-install-recommends -y build-essential cmake git hmmer kalign aria2 tzdata \
    && apt install -y cuda-command-line-tools-11-1
# docker's version of "unset DEBIAN_FRONTEND" 
ENV DEBIAN_FRONTEND=
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get clean

ENV MAMBA_INSTALLER=Mambaforge-${MAMBA_VER}-Linux-x86_64.sh
RUN wget -P /opt/ https://github.com/conda-forge/miniforge/releases/download/${MAMBA_VER}/${MAMBA_INSTALLER} \
    && chmod 777 /opt/${MAMBA_INSTALLER} \
    && /opt/${MAMBA_INSTALLER} -b -p /opt/miniconda3 \
    && rm -rf /opt/${MAMBA_INSTALLER}
ENV PATH /opt/miniconda3/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/miniconda3/lib:$LD_LIBRARY_PATH

# we have to downgrade the jax dependencies for cuda 11.1 for sockeye
# cuda 11.1 is not on conda
# update env.yml if alphafold_container_build/load/alphafold/requirements.txt changes 
ADD ./load/env.yml /opt/env.yml
RUN --mount=type=cache,target=/opt/miniconda3/pkgs mamba env create -n ${CONDA_ENV} -f /opt/env.yml
ENV PATH /opt/miniconda3/envs/${CONDA_ENV}/bin:$PATH

ADD ./load/alphafold_common /opt/alphafold/alphafold/common
ADD ./load/entry /app/alphafold
ENV PATH /app:$PATH

RUN chmod u+s /sbin/ldconfig.real

# Singularity uses tini, but raises warnings
# because the -s flag is not used
ADD ./load/tini /tini
RUN chmod +x /tini
# ENTRYPOINT ["/tini", "-s", "-g", "--", "/app/entry"]
ENTRYPOINT ["/tini", "-s", "-g", "--"]
