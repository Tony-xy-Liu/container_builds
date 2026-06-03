ARG CONDA_ENV=for_container
ARG VERSION

FROM ubuntu:24.04
# scope var from global
ARG CONDA_ENV
ARG VERSION

# I believe this is to avoid permission issues with 
# manipulating added files to places like /opt
RUN old_umask=`umask` \
    && umask 0000 \
    && umask $old_umask

# Singularity uses tini, but raises warnings
# we set it up here correctly for singularity
ADD ./lib/tini /tini
RUN chmod +x /tini
    
# singularity doesn't use the -s flag, and that causes warnings.
# -g kills process group on ctrl+C
ENTRYPOINT ["/tini", "-s", "-g", "--"]

# Install dependencies (orad is mostly self-contained but needs tar/gzip to extract)
RUN apt-get update && apt-get install -y libstdc++6 ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy the orad binary you downloaded from Illumina
COPY ./lib/orad.${VERSION}.linux /app
RUN chmod +x /app/orad
ENV PATH=/app:$PATH
ENV ORA_REF_PATH=/app/oradata
