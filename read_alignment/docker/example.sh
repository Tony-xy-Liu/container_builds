BAM=coverage.bam
SRR=SRR10053317
GENOME=/ws/bins/${SRR}_bin00.fa
READS=/ws/reads/${SRR}.fastq.gz

# https://github.com/lh3/minimap2
# http://www.htslib.org/doc/samtools-sort.html
minimap2 -a $GENOME $READS | samtools sort -o $BAM --write-index -

# # https://broadinstitute.github.io/picard/explain-flags.html
# samtools view -u  -f 4 -F 264 $BAM  > unmapped1.bam   # single unaligned
# samtools view -u  -f 8 -F 260 $BAM  > unmapped2.bam   # other unaligned
# samtools view -u -f 12 -F 256 $BAM > unmapped3.bam    # both
# samtools merge -u - unmapped[123].bam | samtools sort -n - -o unmapped.bam
samtools view -u -f 12 -F 256 $BAM > unmapped.bam    # both
bamToFastq -i unmapped.bam -fq unmapped_1.fq -fq2 unmapped_2.fq

# https://bedtools.readthedocs.io/en/latest/content/tools/genomecov.html
bedtools genomecov -ibam $BAM -d >report.txt
