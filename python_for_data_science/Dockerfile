ARG CONDA_ENV=for_container

# https://mamba.readthedocs.io/en/latest/user_guide/mamba.html
FROM condaforge/miniforge3
# scope var from global
ARG CONDA_ENV

# I believe this is to avoid permission issues with 
# manipulating added files to places like /opt
RUN old_umask=`umask` \
&& umask 0000 \
&& umask $old_umask

# Singularity uses tini, but raises warnings
# because the -s flag is not used
ADD ./load/tini /tini
RUN chmod +x /tini
# ENTRYPOINT ["/tini", "-s", "-g", "--", "/app/entry"]
ENTRYPOINT ["/tini", "-s", "-g", "--"]

# Install Google Chrome for kaleido
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        gnupg \
        fonts-liberation \
        libasound2t64 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxrandr2 \
        libpango-1.0-0 \
        libcairo2 \
        xdg-utils \
        # Additional dependencies for X11 and fonts
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxext6 \
        libdbus-1-3 \
        libglib2.0-0 \
        fonts-liberation \
        # Additional dependencies for Chrome stability
        libdrm2 \
        libxshmfence1 \
        libexpat1 \
    && rm -rf /var/lib/apt/lists/*
    # # Add Google's official signing key
    # wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-chrome.gpg && \
    # # Add Google Chrome repository
    # echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    # # Update package list to include the new repo and install Chrome
    # apt-get update && \
    # apt-get install -y --no-install-recommends google-chrome-stable && \
    # rm -rf /var/lib/apt/lists/*

ADD ./load/env.yml /opt/env.yml
ENV PATH=/opt/conda/envs/${CONDA_ENV}/bin:$PATH
RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env create -n ${CONDA_ENV} -f /opt/env.yml \
    && python -c "import asyncio; from kaleido import get_chrome; asyncio.run(get_chrome())"
