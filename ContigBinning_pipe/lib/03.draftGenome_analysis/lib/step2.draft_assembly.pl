#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set options
my ($clean_list, $insertsize, $kmer_cleanlist, $eval_cleanlist, $kmer_range, $vf, $dvf, $threads, $notrun, $outdir, $shdir,);
GetOptions("clean_list:s" => \$clean_list,
        "insertsize:s" => \$insertsize,
        "kmer_range:s" => \$kmer_range,
        "vf:s" => \$vf,
        "dvf:s" => \$dvf,
        "threads:s" => \$threads,
        "notrun" => \$notrun,
        "outdir:s" => \$outdir,
        "shdir:s" => \$shdir,
        );
#set default options
$insertsize ||= 350;
$kmer_range ||= "17:77:10";
$vf ||= "6g";
$dvf ||= "2g";
$threads ||= "6";
$outdir ||= ".";
$shdir ||= "./Shell/detail";

#software's path
use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($super_worker, $spades, $kmer_stat, $ass_stat, $population_soap) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER SPADES KMER_STAT ASS_STAT POPULATION_SOAP)],$Bin, $lib);;

#===============================================================================================================================
my $help = "Name: $0
Description: Script for spades draft-genome assembly
Version: V1.0
Date:
Connector: lindan[AT]novogene.com
Usage: perl $0 --kmer_cleanlist clean1.list --eval_cleanlist clean2.list --kmer_range 17:77:10  
[options for version1]
        *--clean_list      [str] clean fq list used for step1 kmer analysis, with format:
                                    sample1ID     fq1,fq2
                                    sample2ID     fq1,fq2 
                                    ...
                                    Note: should be absolte path.
        --insertsize       [str] set insert size, default=350. 
        --kmer_range       [str] set the range of kmers for step2 spades assembly, default: 17:77:4, i.e., 17,21,25,29,...77.
        --vf               [str] set vf for qsub step2 spades assembly.
        --dvf              [str] set dvf for qsub step2 spades assembly.
        --threads          [str] set threads for qsub step2 spades assembly.

[other options]
        --outdir           [str] project directory,default is ./
        --shdir            [str] output shell script directory, default is ./Shell
        --notrun           [str] just produce shell script, not run  

";
($clean_list && -s $clean_list) || die "$help\n";
#===============================================================================================================================

$outdir = abs_path($outdir);
$shdir = abs_path($shdir);
$outdir =~ s/\/$//g;
$shdir =~ s/\/$//g;
(-d $outdir) || `mkdir -p $outdir`;
(-d $shdir) || `mkdir -p $shdir`;

open CLEAN, "$clean_list";
open KmerClean, ">$outdir/kmer_clean.list";
open EvalClean, ">$outdir/eval_clean.list";
my %cluster2fqs;
while(<CLEAN>){
    chomp;
    my ($index, $fqs) = split/\s+/,$_;
    my ($fq1, $fq2) = split/,/, $fqs;
    push @{$cluster2fqs{$index}}, ($fq1, $fq2);
    print KmerClean "$index $insertsize $fq1\n$index $insertsize $fq2\n";
    
    open SubClean, ">$outdir/$index.reads.lst";
    print SubClean "$fq1\n$fq2\n";
    close SubClean;
    print EvalClean "$index = $outdir/$index.reads.lst\n"; 
}close CLEAN;
close KmerClean;
close EvalClean;

#kmer stat
open SH1, ">$shdir/step1.kmer_stat.sh";
print SH1 
"cd $shdir
$kmer_stat --size 300M --vf 1G -k 15 -r 32 --list $outdir/kmer_clean.list --outdir $outdir --shdir $shdir/step1.kmer_stat
date >step1.kmer_stat.log\n";
close SH1;

#spades assembly
open SH2, ">$shdir/step2.spades_assembly.sh";
my (@kmers,$kmer_string);
my ($kmer_start, $kmer_end, $kmer_step) = split/:/,$kmer_range;
my $num = int(($kmer_end-$kmer_start)/$kmer_step);
foreach(0..$num){
    my $kmer = $kmer_start+($_*$kmer_step);
    push @kmers, $kmer;
}
$kmer_string = join(",",@kmers);
open ASS, ">$outdir/draft.assembly.list";

open INSERT, ">$outdir/new_insert.txt";
foreach my $index(keys %cluster2fqs){
        my ($fq1, $fq2) = @{$cluster2fqs{$index}};
        print SH2
"mkdir -p $outdir/01.run_assembly/$index/02.spades; 
cd $outdir/01.run_assembly/$index/02.spades;
$spades -k $kmer_string --careful --only-assembler -1 $fq1 -2 $fq2 -o .
$ass_stat -r scaffolds.fasta -s all.scafSeq -m > ass_stat.tab
#perl $Bin/lib/WGS_uplod_Seq.pl all.scafSeq -scaftig all.scafSeq.scaftig >all.scafSeq.fna 2>all.scafSeq.agp
#$ass_stat -r all.scafSeq.fna -m > ass_stat.tab.ncbi\n\n";
        print ASS
"$index = $outdir/01.run_assembly/$index/02.spades/all.scafSeq\n";
        print INSERT 
"libname\t$insertsize\n";
}
close ASS;close INSERT;
close SH2;

#assembly evaluation
open SH3, ">$shdir/step3.run_evaluate.sh";
print SH3
"$population_soap --scafl 500 --verbose --add_num 3 --seq_lim 50 --kmer $outdir/02.stat/all_kmer.stat.xls $outdir/eval_clean.list $outdir/draft.assembly.list -step 01247 --gzip --shdir $shdir/step3.run_evaluate -lis_dir $outdir/02.stat -insert $outdir/new_insert.txt --wgs2 --soap_vf 4G --cluster_range 0.001,0.1 --cover_cut 0.5 --len 200 --blast_opts=\"-e 1e-5 -F F -b5\" --outdir $outdir/01.run_assembly -subdir 03.evaluate; 
perl $Bin/lib/contig_gap_info.pl $outdir/02.stat/ncbifa.lst\n";
close SH3;

open SH, ">$shdir/draft_assembly.pipeline.sh";
print SH
"cd $shdir
sh step1.kmer_stat.sh > step1.kmer_stat.sh.o 2> step1.kmer_stat.sh.e &
$super_worker --resource $vf --dvf $dvf --qopts=\"-l num_proc=$threads\" --splits '\\n\\n' --workdir $shdir/step2.spades_assembly/ step2.spades_assembly.sh 
sh step3.run_evaluate.sh >step3.run_evaluate.sh.o 2>step3.run_evaluate.sh.e &\n"; 
close SH;

($notrun) && exit;
system "cd $shdir;sh draft_assembly.pipeline.sh"; 
