#!/bin/bash

# START ARGUMENT PARSING
while getopts 'hi:b:d:t:' VOLBA; do
case "$VOLBA" in
i)	INPUT=$OPTARG;;
b)	BARCODE=$OPTARG;;
d)	DIRECTORY=$OPTARG;;
t)      TOOLS=$OPTARG;;
h)      echo "Mandatory options: -i <input_directory_with_reads> -b <barcode_number> -d <working_directory> -t <directory_with_all_tools_required>"
        exit 0;;
esac
done
if [ "$#" -lt 8 ]; then
	echo "Mandatory options: -i <input_directory_with_reads> -b <barcode_number> -d <working_directory> -t <directory_with__all_tools_required>"
	exit 1
fi
# END ARGUMENT PARSING


# START BASECALLING
READS=${DIRECTORY}/barcode${BARCODE}

if [ ! -d $READS ]; then
  mkdir $READS
  scp ${INPUT}/barcode${BARCODE}* $READS
fi

BC_OUTPUT=${DIRECTORY}/basecalling_output

if [ ! -d $BC_OUTPUT ]; then
  mkdir $BC_OUTPUT
fi

nice -n 12 ${TOOLS}/guppy/bin/guppy_basecaller -i ${READS} -s ${BC_OUTPUT} -c dna_r9.4.1_450bps_hac.cfg
# END BASECALLING


# START OUTPUT CONCAT
touch ${DIRECTORY}/all_reads.fastq
if [ ! -d ${BC_OUTPUT}/pass/barcode${BARCODE} ]; then
  echo "No passed sequencies of given barcode"
  exit 1
fi
for FILE in ${BC_OUTPUT}/pass/barcode${BARCODE}/*; do
  cat ${FILE} >> ${DIRECTORY}/all_reads.fastq
done
# END OUTPUT CONCAT


# START RAW QUALITY REPORT
${TOOLS}/FastQC/fastqc -o ${DIRECTORY} ${DIRECTORY}/all_reads.fastq
# END RAW QUALITY REPORT


# START TRIMMING ADAPTERS
python3 ${TOOLS}/Porechop/porechop-runner.py -i ${DIRECTORY}/all_reads.fastq -o ${DIRECTORY}/porechop_out.fastq --no_split
# END TRIMMING ADAPTERS


# START TRIMMED QUALITY REPORT
${TOOLS}/FastQC/fastqc -o ${DIRECTORY} ${DIRECTORY}/porechop_out.fastq
# END TRIMMED QUALITY REPORT


# START QUALITY IMPROVMENT
${TOOLS}/fastp/fastp -i ${DIRECTORY}/porechop_out.fastq -o ${DIRECTORY}/porechop_fastp_out.fastq --average_qual 20
# END QUALITY IMPROVMENT


# START IMPROVED QUALITY REPORT
${TOOLS}/FastQC/fastqc -o ${DIRECTORY} ${DIRECTORY}/porechop_fastp_out.fastq
# END IMPROVED QUALITY REPORT


# START TAXONOMIC ANALYSIS
${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/krakenDBmax --classified-out ${DIRECTORY}/max_classified.fastq --output ${DIRECTORY}/tmp ${DIRECTORY}/porechop_fastp_out.fastq
${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/krakenDBmax --output ${DIRECTORY}/kraken_max_out ${DIRECTORY}/max_classified.fastq

${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/hugeDB --classified-out ${DIRECTORY}/huge_classified.fastq --output ${DIRECTORY}/tmp ${DIRECTORY}/porechop_fastp_out.fastq
${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/hugeDB --output ${DIRECTORY}/kraken_huge_out ${DIRECTORY}/huge_classified.fastq

${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/SilvaDB --classified-out ${DIRECTORY}/silva_classified.fastq --output ${DIRECTORY}/tmp ${DIRECTORY}/porechop_fastp_out.fastq
${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/SilvaDB --output ${DIRECTORY}/kraken_silva_out ${DIRECTORY}/silva_classified.fastq

${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/GreengenesDB --classified-out ${DIRECTORY}/green_classified.fastq --output ${DIRECTORY}/tmp ${DIRECTORY}/porechop_fastp_out.fastq
${TOOLS}/kraken2/kraken2 --db ${TOOLS}/kraken2/databases/GreengenesDB --output ${DIRECTORY}/kraken_green_out ${DIRECTORY}/green_classified.fastq

if [ -e ${DIRECTORY}/tmp ]; then
  rm ${DIRECTORY}/tmp
fi

touch ${DIRECTORY}/kraken_all_out
cat ${DIRECTORY}/kraken_max_out >> ${DIRECTORY}/kraken_all_out
cat ${DIRECTORY}/kraken_huge_out >> ${DIRECTORY}/kraken_all_out
cat ${DIRECTORY}/kraken_silva_out >> ${DIRECTORY}/kraken_all_out
cat ${DIRECTORY}/kraken_green_out >> ${DIRECTORY}/kraken_all_out
# END TAXONOMIC ANALYSIS



# START TAXONOMIC REPORT
touch ${DIRECTORY}/kraken_all_out_samples
cat ${DIRECTORY}/kraken_all_out | cut -f 2,3,4 > ${DIRECTORY}/kraken_all_out_samples

touch ${DIRECTORY}/log
${TOOLS}/krona/ktImportTaxonomy --tax ${TOOLS}/krona/taxonomy -o ${DIRECTORY}/all_prereduction_piechart.html ${DIRECTORY}/kraken_all_out_samples 2> ${DIRECTORY}/log


MISMATCHED=${DIRECTORY}/mismatched
touch $MISMATCHED
python3 ${TOOLS}/parser.py -i ${DIRECTORY}/log -o ${MISMATCHED}
if [ -e ${DIRECTORY}/log ]; then
  rm ${DIRECTORY}/log
fi

OUTPUT=${DIRECTORY}/kraken_all_matched_out_samples
BACKUP=${DIRECTORY}/backup
touch $OUTPUT
touch $BACKUP
cat ${DIRECTORY}/kraken_all_out_samples > $OUTPUT

while read line; do
  line=$(echo -e $line|tr -d '\n')
  patern="/.*[^a-zA-Z0-9]${line}[^a-zA-Z0-9].*/d"
  sed $patern $OUTPUT > $BACKUP
  cat $BACKUP > $OUTPUT
  echo "" > $BACKUP
done < $MISMATCHED

if [ -e ${BACKUP} ]; then
  rm ${BACKUP}
fi

${TOOLS}/krona/ktImportTaxonomy --tax ${TOOLS}/krona/taxonomy -o ${DIRECTORY}/all_reduced_piechart.html ${OUTPUT}
# END TAXONOMIC REPORT
