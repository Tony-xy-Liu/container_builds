#########################################################################################
# setup

NAME    = "scadc_cov2"
CPU     = 4
MEM     = 16
TIME    = "2:00:00"

# # sockeye
# USER    = "txyliu"
# ALLOC   = "st-shallam-1"
# TEMP_VAR= "SLURM_TMPDIR"
# CONSTRAINT = None
# # CONSTRAINT = '[cascade]'

# cedar
USER    = "phyberos"
ALLOC   = "rpp-shallam"
TEMP_VAR= "SLURM_TMPDIR"
CONSTRAINT = None
# CONSTRAINT = '[cascade]'

# returns a list of dict
# each dict holds information for the job as is given to RunJob()
def MakeJobs():
    import os
    from pathlib import Path
    root = Path("/home/phyberos/project-rpp/fosmids/data/scadc/sacdc_fosmid_reads")

    def _make(asm, name, include_fos):
        def get_reads(d):
            dir = root.joinpath(d).joinpath("filtered")
            return sorted([f"{dir.joinpath(f)}" for f in os.listdir(dir) if "1.fastq" in f or "2.fastq" in f])

        def get_name(d):
            return d.split(".")[3]
        
        if include_fos:
            fos = [
                dict(
                    name=f"{get_name(d)}.{name}",
                    asm=asm,
                    reads=get_reads(d),
                )
            for d in os.listdir(root)]
        else:
            fos = []

        return fos + [
            dict(
                name=f"metag.{name}",
                asm=asm,
                reads=[
                    "/home/phyberos/project-rpp/fosmids/data/scadc/scadc_metagenomic_reads/ScaDC_1.fastq.gz",
                    "/home/phyberos/project-rpp/fosmids/data/scadc/scadc_metagenomic_reads/ScaDC_2.fastq.gz",
                ],
            ),
        ]

    context = []
    for a, n, fos in [
        ("/home/phyberos/project-rpp/fosmids/data/scadc/ScaDC.fna", "fosmids", True),
        ("/home/phyberos/project-rpp/fosmids/data/scadc/scadc_metag.fna", "metag", False),
        # ("/home/phyberos/project-rpp/fosmids/data/scadc/metawrap_50_10_bins.contigs", "bins", False),
        # ("/home/phyberos/project-rpp/fosmids/data/scadc/scadc_fosmid_library_end_seqs/all.fna", "ends", True),
    ]:
        context += _make(a, n, fos)
    return context

def RunJob(DATA, OUT_DIR, job_num, cpus, mem, log):
    import os, sys, stat
    from pathlib import Path

    job_name = DATA["name"]
    asm_path = Path(DATA["asm"])
    read_files = DATA["reads"]

    # get inputs and dependencies
    READS = Path("./reads")
    ASM = Path(f"./{job_name}.fa")
    out = OUT_DIR.joinpath(job_name)
    os.system(f"""\
        date
        echo "setup"

        cp /scratch/phyberos/lx_ref/read_alignment.sif ./
        cp /scratch/phyberos/lx_ref/quast.sif ./

        mkdir -p {READS}
        cp {read_files[0]} {READS}/
        cp {read_files[1]} {READS}/
        cp {asm_path} {ASM}

        find .

        mkdir -p {out}
    """)

    READ_FILES = sorted([READS.joinpath(f) for f in os.listdir(READS)])
    # sr_params = f"-x sr"
    # get_unmapped = f"""\
    #     samtools view -u  -f 4 -F 8 $BAM  > unmapped1.bam   # single unaligned
    #     samtools view -u  -f 8 -F 4 $BAM  > unmapped2.bam   # other unaligned
    #     samtools view -u  -f 12 $BAM > unmapped3.bam        # both
    #     samtools merge -u - unmapped[123].bam | samtools sort -n - -o unmapped.bam
    #     bamToFastq -i unmapped.bam -fq /out/{job_name}_unmapped_1.fq -fq2 /out/{job_name}_unmapped_2.fq 2>/dev/null
    # """
    get_unmapped = ""

    bounce = "./bounce.sh"
    cov_tsv = f"{job_name}.coverage.tsv"
    stats_tsv = f"{job_name}.stats.txt"
    # https://lh3.github.io/minimap2/minimap2.html
    # minimap2 options:
    # -x sr makes alignment super strict
    # --sr Enable short-read alignment heuristics, more sensitivity
    # -2 use two io threads, more peak memory
    # -a SAM format
    # --secondary=no Whether to output secondary alignments [no]
    # --sam-hit-only 	In SAM, don’t output unmapped reads.
    # --heap-sort=no|yes    Heap merge is faster for short reads, but slower for long reads. [no]
    # --frag=yes
    with open(bounce, "w") as f:
        f.write(f"""\
            cd /ws
            BAM=./temp.coverage.bam
            minimap2 -a --sr -2 -t --sam-hit-onl {cpus-1} --secondary=no \
                --heap-sort=yes --frag=yes \
                {ASM} {' '.join([str(f) for f in READ_FILES])} | samtools sort -o $BAM --write-index -
            
            {get_unmapped}

            bedtools genomecov -ibam $BAM -bg >/ws/{cov_tsv}
            samtools flagstat $BAM >/ws/{stats_tsv}
        """)
    os.chmod(bounce, stat.S_IRWXU|stat.S_IRWXG|stat.S_IRWXO)

    os.system(f"""\
        date
        echo "coverage"
        cat {bounce}
        mkdir -p {out}
        singularity run -B ./:/ws ./read_alignment.sif \
            /ws/{bounce}
        cp ./{cov_tsv} {out}/
        cp ./{stats_tsv} {out}/

        date
        echo "aggregate coverage"
    """)

    contig2length = {}
    with open(ASM) as fa:
            current = None
            length = 0
            def _submit():
                contig2length[current] = length
            for l in fa:
                if l[0] == ">":
                    if current is not None: _submit()
                    current = l[1:-1].split(" ")[0]
                    length = 0
                else:
                    length += len(l)-1 # minus 1 for "\n"
            _submit()
    agg_out = f"{job_name}.cov_per_contig.tsv"
    with open(f"./{cov_tsv}") as f:
        with open(agg_out, "w") as of:
            last_k = None
            entry = []
            def _submit():
                nonlocal entry
                total = contig2length[last_k]
                c = 0.0
                for span, val in entry:
                    c += (span/total)*val
                # assume no overlap, so total == total span of contig
                of.write("\t".join(str(x) for x in [last_k, c, total])+"\n")
                entry = []

            for l in f:
                k, s, e, val = l[:-1].split("\t")
                s, e, val = [int(x) for x in [s, e, val]]
                if k != last_k:
                    if last_k is not None: _submit()
                    last_k = k
                entry.append((e-s, val))
            _submit()
    os.system(f"""\
        cp ./{agg_out} {out}/

        date
        echo "quast"
        singularity run -B ./:/ws ./quast.sif \
        quast -t {cpus} \
            -o /ws/quast \
            /ws/{ASM}
        cp ./quast/transposed_report.tsv {out}/{job_name}.quast.tsv
        tar -cf - ./quast | pigz -7 -p {cpus} >{out}/{job_name}.quast.tar.gz
    """)


#########################################################################################

#########################################################################################
# hpc submit

_VER    = "5.4"
# if this script is called directly, then submit witn _INNER flag
# if _INNER is in the arguments, then I'm running on a compute node
# so continue with workflow
import os, sys, stat
import json
import time
import uuid
from pathlib import Path
from datetime import datetime
_INNER = "inner"
SCRIPT = os.path.abspath(__file__)
SCRIPT_DIR = Path("/".join(SCRIPT.split("/")[:-1]))

if not (len(sys.argv)>1 and sys.argv[1] == _INNER):
    now = datetime.now() 
    date_time = now.strftime("%Y-%m-%d-%H-%M")
    run_id = f'{uuid.uuid4().hex[:3]}'
    print("run:", NAME)
    print("run id:", run_id)
    OUT_DIR = Path(f"/home/{USER}/scratch/runs/{run_id}.{NAME}.{date_time}")
    internals_folder = OUT_DIR.joinpath(f"_internals")
    logs_folder = OUT_DIR.joinpath(f"_logs")

    context = MakeJobs()
    assert isinstance(context, list) and len(context)>0

    # ---------------------------------------------------------------------------------
    # prep commands & workspaces

    if len(context) == 0:
        print(f"no jobs, stopping")
        exit()

    os.makedirs(internals_folder)
    os.makedirs(logs_folder)
    os.chdir(internals_folder)

    run_context_path = internals_folder.joinpath("context.json")
    with open(run_context_path, "w") as j:
        json.dump(context, j, indent=4)

    os.makedirs(OUT_DIR, exist_ok=True)

    # ---------------------------------------------------------------------------------
    # submit

    print(f"N: {len(context)}")
    notes_file = f"notes.{run_id}.txt"
    run_cmd = f"python {SCRIPT} {_INNER} {run_context_path} {OUT_DIR} {CPU} {MEM} {TIME} {run_id}"

    #########
    # slurm
    arr_param = f"--array=0-{len(context)-1}" if len(context)>1 else " "
    cons_param = f"--constraint={CONSTRAINT}" if CONSTRAINT is not None else " "
    _log_index = ".%a" if len(context)>1 else ""
    sub_cmd = f"""\
    sbatch --job-name "{run_id}-{NAME}" \
        --account {ALLOC} \
        --nodes=1 --ntasks=1 \
        --error {logs_folder}/err{_log_index}.log --output {logs_folder}/out{_log_index}.log \
        --cpus-per-task={CPU} --mem={MEM}G --time={TIME} \
        {cons_param} \
        {arr_param} \
        --wrap="{run_cmd}" &>> {internals_folder}/{notes_file}
    """.replace("  ", "")
    # ln -s {internals_folder} {SCRIPT_DIR}/{NAME}.{date_time}.{run_id}
    #########
    with open(notes_file, "w") as log:
        log.writelines(l+"\n" for l in [
            f"name: {NAME}",
            f"id: {run_id}",
            f"array size: {len(context)}",
            f"output folder: {OUT_DIR}",
            f"submit command:",
            sub_cmd,
            "",
        ])
    os.system(f"ln -s {OUT_DIR} {SCRIPT_DIR}/{OUT_DIR.name}")
    if not (len(sys.argv)>1 and sys.argv[1] in ["--mock", "mock", "-m"]):
        os.chdir(OUT_DIR)
        os.system(sub_cmd)
        try:
            with open(f"{internals_folder}/{notes_file}") as f:
                notes = [l for l in f.readlines() if l != "\n"]
                jid = notes[-1][:-1]
                print(f"scheduler id: {jid}")
        except:
            pass
        print("submitted")

    exit() # the outer script

#########################################################################################
# on the compute node...

_, run_context_path, _out_dir, cpus, mem, given_time, run_id = sys.argv[1:] # first is just path to this script
cpus = int(cpus)
mem = int(mem)
setup_errs = []
ARR_VAR = "SLURM_ARRAY_TASK_ID"
if ARR_VAR in os.environ:
    job_i = int(os.environ[ARR_VAR])
else:
    _e = f'not in array, defaulting to the first context'
    setup_errs.append(_e)
    os.system(f'echo "{_e}"')
    job_i = 0
with open(run_context_path) as f:
    run_context = json.load(f)
assert run_context is not None
DATA = run_context[job_i]
OUT_DIR = Path(_out_dir)

def _print(x=""):
    now = datetime.now() 
    date_time = now.strftime("%H:%M:%S")
    os.system(f"""echo "{date_time}> {x}" """)
for _e in setup_errs:
    _print(_e)

# ---------------------------------------------------------------------------------------
# setup workspace in local scratch

salt = uuid.uuid4().hex
WS = Path(os.environ.get(TEMP_VAR, '/tmp')).joinpath(f"{NAME}-{salt}"); os.makedirs(WS)
os.chdir(WS)

# ---------------------------------------------------------------------------------------

_print(sys.executable)
_print(f"{sys.version}".replace("\n", ""))
_print(WS)
_print("\n"+json.dumps(DATA, indent=4))
_print(f"job:{job_i+1}/{len(run_context)} cpu:{cpus} mem:{mem} time:{given_time} script_ver:{_VER}")
_print("-"*50)

RunJob(DATA, OUT_DIR, job_i+1, cpus, mem, _print)

# ---------------------------------------------------------------------------------------
# done
_print('end of wrapper')
