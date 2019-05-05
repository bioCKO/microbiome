#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
#use Cwd qw(absway_str);

#set options
my ($data_list, $clean_list, $binCov_list, $insertsize, $VF, $threads, $outdir, $shdir, $notrun, $kmer_range,);

GetOptions("data_list:s" => \$data_list,
        "clean_list:s" => \$clean_list,
        "binCov_list:s" => \$binCov_list,
        "insertsize:s" => \$insertsize,
        "kmer_range:s" => \$kmer_range,
        "VF:s" => \$VF,
        "threads:s" => \$threads,
        "outdir:s" => \$outdir,
        "shdir:s" => \$shdir,
        "notrun" => \$notrun,
);

#set default options
$insertsize ||= 350;
$VF ||= "20g/2g;10g/2g";
$threads ||= "10;5";
$outdir ||= ".";
$shdir ||= "./Shell";


## get software's path
use lib "$Bin/../00.Commbin/";
my $lib = "$Bin/../";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my ($super_worker, $genome_component, $genome_function) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER GENOME_COMPONENT GENOME_FUNCTION)],$Bin, $lib);;

#===============================================================================================================================
my $help = "Name: $0
Description: Script for draft-genome assembly and annotation for contig bins. 
Version: V1.0
Date:
Connector: lindan[AT]novogene.com
Usage: perl $0 -data_list ass.list -clean_list reads.list --insertsize 350
[options for version1]
        *-data_list        [str] binning clusters list, with format:
                                  bin1ID   the absolute path of the seq
                                  bin2ID   the absolute path of the seq
                                  ...
        *-clean_list       [str] clean data fq list, with format:
                                  sample1ID   reads1 fq, reads2 fq
                                  sample2ID   reads1 fq, reads2 fq
                                  ...
                                  note: fq could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
        *-binCov_list      [str] bin coverarge stat list, containing: bin id, average bin coverage in each sample, total bin coverage in all samples, and the sample id with the biggest average coverage, with format:
                                 BinID Sample1ID Sample2ID .. avgDepth  maxCov_SampleID #head
                                 ...
                                 ...
        --insertsize       [str] set insert size, default=350
        --kmer_range       [str] set the range of kmers for spades assembly, default: 17:77:10, i.e., 17,21,25,29,...77.
        --VF               [str] default: 20g/2g;10g/2g. set vf and dvf for step1:reads mapping and step2:spades assembly, respectively.  

[other options]
        --outdir           [str] project directory,default is ./
        --shdir            [str] output shell script directory, default is ./Shell
        --notrun           [str] just produce shell script, not run  

";
($data_list && -s $data_list && $clean_list && -s $clean_list && $binCov_list && -s $binCov_list) || die "$help\n";
#===============================================================================================================================
$data_list = absway_str($data_list);
$clean_list = absway_str($clean_list);
$outdir =~ s/\/$//g;
$outdir = absway_str($outdir);
$shdir = absway_str($shdir);
(-d $outdir) || `mkdir -p $outdir`;
(-d $shdir) || `mkdir -p $shdir`;
my @VF = split/;/,$VF;
my (@vfs,@dvfs);
foreach(@VF){my ($vf, $dvf) = split/\//,$_; push @vfs, $vf; push @dvfs, $dvf;}
my @threads = split/;/,$threads;

foreach(qw(step1.binReadsMapping step2.draft_assembly step3.genome_component step4.genome_fuction)){
    (-d "$outdir/$_") || `mkdir $outdir/$_`;
    (-d "$shdir/$_") || `mkdir $shdir/$_`; 
}
#step1: bins reads mapping and abstract
my @clusterIDs;
open SH1, ">$shdir/step1.binReadsMapping.sh";
print SH1 
"perl $Bin/lib/step1.binReadsMapping.pl -data_list $data_list -clean_list $clean_list -binCov_list $binCov_list --insertsize $insertsize --vf $vfs[0] --dvf $dvfs[0] --threads $threads[0] --outdir $outdir/step1.binReadsMapping --shdir $shdir/step1.binReadsMapping
date >$outdir/step1.binReadsMapping/Bin_ReadsMapping.finish\n";
close SH1;

#step2: draft_assembly
open SH2, ">$shdir/step2.draft_assembly.sh";
print SH2
"perl $Bin/lib/step2.draft_assembly.pl --clean_list $outdir/step1.binReadsMapping/bin_clean.allsample.list --kmer_range $kmer_range --vf $vfs[1] --dvf $dvfs[1] --threads $threads[1] --outdir $outdir/step2.draft_assembly --shdir $shdir/step2.draft_assembly &
perl $Bin/lib/step2.draft_assembly.pl --clean_list $outdir/step1.binReadsMapping/bin_clean.onesample.list --kmer_range $kmer_range --vf $vfs[1] --dvf $dvfs[1] --threads $threads[1] --outdir $outdir/step2.draft_assembly_onesample --shdir $shdir/step2.draft_assembly_onesample &
wait
perl $Bin/lib/lib/chooseBestBinAss.pl $data_list $outdir/step2.draft_assembly/02.stat/ncbifa.lst $outdir/step2.draft_assembly_onesample/02.stat/ncbifa.lst $outdir/step2.final_assembly
date >$outdir/step2.final_assembly/Genome_Assembly.finish\n";
close SH2;

#step3: genome component annotation
open SH3, ">$shdir/step3.genome_component.sh";
print SH3
"$genome_component --step 12356 --spe_type B --repbase --trf --repeat_stat --ncRNA_type rRNAd-tRNA-sRNA --ncRNA_stat --ass_list $outdir/step2.final_assembly/draft.assembly.list --outdir $outdir/step3.genome_component --shdir $shdir/step3.genome_component
date >$outdir/step3.genome_component/Genome_Component.finish\n";
close SH3;

#step4: genome function annotation
open SH4, ">$shdir/step4.genome_fuction.sh";
print SH4
"$genome_function --spe_type B --function nr-swissprot-trembl-kegg-go-phi-cazy-tcdb-secretory-gi-secondary-t3ss-tnss-cog-vfdb-ardb --num_each 500 -e 1e-5 --secretory_type gram- --ass_list $outdir/step2.final_assembly/draft.assembly.list --pep_list $outdir/step3.genome_component/02.stat/pep.list --gff_list $outdir/step3.genome_component/02.stat/gff.list --cds_list $outdir/step3.genome_component/02.stat/cds.list --outdir $outdir/step4.genome_fuction --shdir $shdir/step4.genome_fuction
date >$outdir/step4.genome_function/Genome_Function.finish\n"; 
close SH4;

my $run_shell = 
"nohup sh step1.binReadsMapping.sh >step1.binReadsMapping.sh.o 2>step1.binReadsMapping.sh.e\nnohup sh step2.draft_assembly.sh >step2.draft_assembly.sh.o 2>step2.draft_assembly.sh.e\nnohup sh step3.genome_component.sh >step3.genome_component.sh.o 2>step3.genome_component.sh.e\nnohup sh step4.genome_fuction.sh >step4.genome_fuction.sh.o 2>step4.genome_fuction.sh.e\n";
open SH, ">$shdir/draftGenome.analysis.sh";
print SH "$run_shell";

$notrun && exit; 
system "cd $shdir\n$run_shell";

sub absway_str{
    my @arr;
    chomp(my $pwd = `pwd`);
    for(split/\s+/,$_[0]){
        ($_ ne ".") && ($_ ne '..') && (-s $_) && !(m#^/#) && ($_ = "$pwd/$_");
        push @arr,$_;
    }
    $_[0] = join(" ",@arr);
}

