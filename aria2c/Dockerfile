ARG CONDA_ENV=for_container

# jammy is ver. 22.04 LTS
# https://wiki.ubuntu.com/Releases
FROM ubuntu:jammy
# scope var from global
ARG CONDA_ENV

RUN apt -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update \
    && apt install -y \
        aria2 \
    && rm -rf /var/cache/apt/lists

## We do some umask munging to avoid having to use chmod later on,
## as it is painfully slow on large directores in Docker.
RUN old_umask=`umask` && \
    umask 0000 && \
    umask $old_umask

# Singularity uses tini, but raises warnings
# because the -s flag is not used
ADD ./load/tini /tini
RUN chmod +x /tini
# ENTRYPOINT ["/tini", "-s", "-g", "--", "/app/entry"]
ENTRYPOINT ["/tini", "-s", "-g", "--"]
