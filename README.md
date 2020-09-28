## SeqConCount

This app counts contaminating sequences fastq files. It uses BLAST and the NCBI nucleotide database to find taxonomy/organism information for sequencing reads.

* Input: raw fast file
* Output: plot about species occurrence

## Installation


* Create a new Rproject using version control in RStudio 

* Download and install BLAST
* Place ```blastn``` executable to the app directory
* source: https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.2.29/

* Download required databases
* Place database files to the app directory
```
wget  ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt*.gz
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/ref_viruses_rep_genomes.tar.gz
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/ref_prok_rep_genomes.*.tar.gz
```

* Run app from RStudio




