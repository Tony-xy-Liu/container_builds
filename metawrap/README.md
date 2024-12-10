# ALL CREDIT TO [METAWRAP](https://github.com/bxlab/metaWRAP)
## https://github.com/bxlab/metaWRAP
*adds [snakemake](https://snakemake.readthedocs.io/) to this container https://quay.io/repository/biocontainers/metawrap-mg?tab=tags&tag=1.3.0--hdfd78af_0*

take a look at `dev.sh` to see how to mount the required reference databases

## Singularity Example
```
export XDG_CACHE_HOME="/ws" # snakemake temp dir
singularity run -B ./:/ws,<path/to/checkm_database>:/checkm_db <image>.sif snakemake --version
```