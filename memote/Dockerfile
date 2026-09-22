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
ENV PATH /opt/conda/envs/${CONDA_ENV}/bin:/app:$PATH
# apptainer binds $HOME, and a host ~/.local/lib/python3.7 otherwise shadows this env's packages.
ENV PYTHONNOUSERSITE=1

# memote 0.9.13 bounds almost nothing from above (cobra>=0.15.3), so an open install pulls a
# stack it never ran with. Resolve everything as PyPI stood on its release day instead. That
# downgrades setuptools under conda's, whose distutils-precedence.pth then names a missing module.
# pip is in the resolve because memote imports depinfo, whose pipdeptree needs a 2019 pip.
RUN uv pip install --system --python $(which python) --no-cache \
        --exclude-newer 2019-12-05T00:00:00Z memote==0.9.13 pip==19.3.1 \
    && rm $(python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')/distutils-precedence.pth \
    && uv pip freeze --python $(which python) > /opt/memote_freeze.txt \
    && pip check

COPY ./src /app/
