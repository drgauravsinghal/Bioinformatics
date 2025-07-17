#!/bin/bash                              
#SBATCH --job-name=fastqc+trim                                   # Job name
#SBATCH --mail-type=ALL                                          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=drgauravsinghal@gmail.com                    # Where to send mail
#SBATCH --nodes=1                                                # Numbers of nodes
#SBATCH --ntasks=1                                               # Number of tasks
#SBATCH --cpus-per-task=2                                        # Number CPU
#SBATCH --time=00:30:00 # Time limit                             # Time limit hrs:min:sec
#SBATCH --partition=short                                        # Partition/queue requested on server
#SBATCH --mem=500mb                                              # Memory limit
#SBATCH --output=/home/ubuntu/PracticeAnalysis/eofiles/%x_%j.out # Where to save out files           
#SBATCH --error=/home/ubuntu/PracticeAnalysis/eofiles/%x_%j.err  # Where to save error files

echo "BEGIN: Preprocessing................."

################################################################                                                                                                                      
##Load required modules 
################################################################
## Activate these modules only if needed
##module load fastqc/0.11.5
##module load trimmomatic/0.36
##module load java/1.8.0_101

################################################################
##Initialize folders 
################################################################
wd=/home/ubuntu/PracticeAnalysis/
qc=${wd}/qc
trim=${wd}/trim
fastq=/home/ubuntu/PracticeAnalysis/rawdata/

################################################################
#make folders that may not exist
mkdir -p ${qc} ${trim} ${eofiles}
################################################################

################################################################
##Job information
################################################################
printf "\nFASTQ Directory: ${fastq}"
printf "\nQC Directory: ${qc}"
printf "\nTrimmed FASTQ Directory: ${trim}"
printf "\nRun on: $(hostname)"
printf "\nRun from: $(pwd)"
printf "\nScript: $0\n"
date
##printf "\nYou have requested $SLURM_CPUS_ON_NODE core(s).\n" ##Activate this command when using SLURM

################################################################
##Run script                                                     
################################################################
#create qc subfolders to store intermediate files
mkdir -p ${qc}/trim_log
mkdir -p ${qc}/fastqc

for sample in `ls ${fastq} | tr '.' '\t' | cut -f 1`; 
do
    #1: trim fastq file using trimmomatic
java -jar /home/ubuntu/Tools/Trimmomatic-0.39/trimmomatic-0.39.jar SE \
    -threads 2 \
    -phred33 \
    -trimlog ${qc}/trim_log/${sample}.trimlog \
    ${fastq}/${sample}.fastq.gz \
    ${trim}/${sample}.trimmed.fastq.gz \
    ILLUMINACLIP:/home/ubuntu/Tools/Trimmomatic-0.39/adapters/TruSeq3-SE.fa:2:30:10 \
    LEADING:3 \
    TRAILING:3 \
    SLIDINGWINDOW:4:15 \
    MINLEN:36

    ##Activate/Modify these commands only for low quality data else this will be an unwanted trimming
    ##SLIDINGWINDOW:4:20
    ##LEADING:5
    ##TRAILING:5
    ##HEADCROP:10
    ##CROP:75 ##To clip reads to a fixed length (for uniformity) 
    ##AVGQUAL:20 ##discards reads with average quality below a threshold, only for strict filtering 

    #2: check quality of the fastq files after trimming 
    fastqc --threads=2 ${trim}/${sample}.trimmed.fastq.gz -o ${qc}/fastqc

done
exec > /home/ubuntu/PracticeAnalysis/eofiles/run.out 2> /home/ubuntu/PracticeAnalysis/eofiles/run.err  ## Deactivate this command when using SLURM
echo "DONE: Preprocessing................."
echo Job finished at `date +"%T %a %d %b %Y"`
