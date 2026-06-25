# external_pathofact  — SCAFFOLD (not yet buildable)

PathoFact 2.0 — integrated ARG + virulence-factor + toxin + MGE prediction from
assembled contigs. Used by the spanish-lakes-metagenomics metasmith transform
`transforms/functionalAnnotation/pathofact.py`
(`containers::pathofact.oci` → `docker://quay.io/hallamlab/external_pathofact:2.0`).

PathoFact 2.0 is a **Snakemake pipeline** (https://gitlab.lcsb.uni.lu/ESB/PathoFact),
not a single tool — it orchestrates several sub-tools each with its own conda env
and bundled models/HMMs. There is no clean biocontainer, hence this build.

## Remaining work (this is a scaffold)

1. **Dockerfile** — clone the pipeline into `/app/PathoFact` and pre-solve its
   per-rule conda envs (`snakemake --use-conda --conda-create-envs-only`) so the
   image runs offline on Sockeye compute nodes.
2. **Databases** — PathoFact ships / downloads HMMs + models. Either bake them
   into the image or expose them as the metasmith `annotation::pathofact_db`
   product (downloader TODO). The transform binds that DB at `/pathofact_db`.
3. **`src/pathofact` wrapper** — translate the transform contract
   `pathofact --input <contigs> --db <dir> --outdir <out> --threads <n>` into the
   pipeline's `config.yaml` + `snakemake` invocation, and lay the four result
   tables (AMR / virulence / toxin / MGE) where the transform globs for them.

Until the above is done the transform `pathofact.py` resolves in the DAG but
cannot run.

## Build (once finalised)

```bash
./dev.sh -bd && ./dev.sh -ud && ./dev.sh -bs
```
