# external_mobileelementfinder

MobileElementFinder (CGE) — detects mobile genetic elements / IS-elements in
assembled contigs. Used by the spanish-lakes-metagenomics metasmith library
transform `transforms/functionalAnnotation/mobileelementfinder.py`
(`containers::mobileelementfinder.oci` →
`docker://quay.io/hallamlab/external_mobileelementfinder:1.1.2`).

No biocontainer exists for this tool (PyPI / CGE web service only), hence this
build.

The pip package `MobileElementFinder` bundles its MGE database, so no separate
DB download is needed. Runtime deps `kma`, `blast` (makeblastdb), and `prodigal`
come from bioconda (see `envs/base.yml`).

## Build

```bash
./dev.sh -bd   # docker build  → quay.io/hallamlab/external_mobileelementfinder:1.1.2
./dev.sh -ud   # push to quay.io
./dev.sh -bs   # apptainer .sif from local docker image
```

Smoke test: `mefinder find --contig <contigs.fa> out` should write `out.csv`.
