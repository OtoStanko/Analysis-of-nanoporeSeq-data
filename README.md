# Analysis-of-nanoporeSeq-data
Basecalling and follow-up processing and analysis of water sample from a pond near Studentka town (Czech Republic)

This file describes functionality of bash script "workflow.sh".
Description includes what tools we used in the script and why.
Structure of the directories with input files is strict and must be followed in order to recreate our process.
Directory must contain:
	1. subdirectories for every tool used {guppy, Porechop, FastWC, fastp, krona, kraken2}
	2. in every subdirectory for the tools, there must be executable for that tool alongside all the files and databases that are used by the tool
	3. in the directory with the kraken2 tool, there must be a directory with the databases used by kraken2
	4. in the directory with the krona tool, there must be a directory with taxonomical database
	
Parameter -d directory to which all the output files will be saved (including the output files from the tools during the process)
Parameter -i directory containing input fast5 files from the nanopore sequencing
Parameter -b number of the Barcode of the sample

The script automizes process of identification of organisms in the sample of water (in our case from a pond in Moravia). Structure of the directory tree is quite strict and we acknowledge that it may be hard to reproduce. Its main purpose is to show out workflow. Tools we used and the results obtained from the analysis.


BASECALLING:
Reads tagged with our Barcode are copied to the working directory.
creating the dir for supporting output files.
Basecalling is run on the copied data. We used high=accuracy config file "dna_r9.4.1_450bps_hac.cfg"

OUTPUT CONCAT:
We have joint all the output fastq sequences tagged as "pass" with our Barcode into one file for better manipulation.

RAW QUALITY REPORT:
We have created quality report from the raw data after basecalling.

TRIMMING ADAPTERS:
We cut out adapters from the sequences. Tool Guppy has a database of some known adapters used in nanopore sequencing.
With the parameter --no_split we forbid the cutting of adapters from the middle of the sequences.

TRIMMED QUALITY REPORT:
We created another quality report after the adapters are removed.

QUALITY IMPROVMENT:
We have set phred score threshhold to 20 to filter out sequences of poor quality.

IMPROVED QUALITY REPORT.
...

TAXONOMIC ANALYSIS:
Taxonomical analysis is done using 4 databases. Each is better at detecting some groups of organisms.
In the first run of the Krake2, we specify --classified-out to filter only the sequences that the database was able to identify.
In the second run we use these sequences, so that we would only be left with the identified seqs for the analysis.
All 4 files are joint together. There may be sequences that have been identified by multiple databases and thus may appear multiple times in the joint file.

TAXONOMIC REPORT:
We take only some collumns from the Taxonomic analysis, needed for the krona.
2. column - querry ID
3. column - taxonomy ID
4. column - quality score

Krona is run 2 times. With the parameter --tax, we specify path to the taxonomical database from NCBI.
In the first run we redirect the error messages to the file. It contains the list of taxIDs taht were not found in the NCBI database.
"parser.py" copies these IDs to the file that is used for filtering out these rows from the input file to the second run of Krona.
In the filtered input data we run the Krona for the second time to obtain the pie-chart containing organisms from the original sample.
