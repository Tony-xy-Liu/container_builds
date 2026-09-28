ARG CONDA_ENV=for_container

FROM condaforge/miniforge3
# scope var from global
ARG CONDA_ENV

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

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
# create conda env from yaml config
COPY ./envs/base.yml /opt/base.yml
# use an external cache for solved environments
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create -n ${CONDA_ENV} -f /opt/base.yml
# add bins to PATH so that the env appears "active"
ENV PATH=/opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH
# apptainer binds $HOME, and a host ~/.local/lib/python3.12 otherwise shadows this env's packages.
ENV PYTHONNOUSERSITE=1

# No CPLEX is installed. It is bound in at run time (PYTHONPATH). reframed takes CPLEX when it
# imports and falls through to SCIP when it does not, so one image serves both solvers.
# The bundled bigg_proteins.dmnd stays as shipped, as in the stock image.

COPY ./src /app/
