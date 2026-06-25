# external_feast  — SCAFFOLD (not yet buildable)

FEAST — fast expectation-maximisation microbial source tracking (R package,
github cozygene/FEAST). Used by the spanish-lakes-metagenomics metasmith
transform `transforms/metagenomics/taxonomy/feast.py`
(`containers::feast.oci` → `docker://quay.io/hallamlab/external_feast:1.0`).

No biocontainer exists, hence this build. `envs/base.yml` pulls R + FEAST's CRAN
deps; FEAST itself installs from GitHub.

## Remaining work (this is a scaffold)

1. **Dockerfile** — after the conda env is created, install FEAST:
   `R -e 'remotes::install_github("cozygene/FEAST", upgrade="never")'`.
2. **`src/FEAST` wrapper** — translate the transform contract
   `FEAST --sink <metaphlan_profile> --sources <dir> --out <tsv>` into an Rscript
   that builds the FEAST OTU table (sources + the sink sample) + metadata and
   runs `FEAST::FEAST(...)`, writing the proportions table.
3. **External source data** — FEAST needs curated source community profiles
   (human gut / livestock / wildlife / soil / freshwater) from MGnify / EMP.
   These are the metasmith `annotation::feast_sources` product, currently only
   stubbed by `transforms/logistics/downloadFeastSources.py`. Finalise that
   dataset before running FEAST for real.

Until the above is done the transform `feast.py` resolves in the DAG but cannot
run.

## Build (once finalised)

```bash
./dev.sh -bd && ./dev.sh -ud && ./dev.sh -bs
```
