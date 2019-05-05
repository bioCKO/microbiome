#!/usr/bin/perl -w
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use strict;

my $help = "Name: $0
Description: script for MetaPhlAn TaxAnno 
Version:1.0
Date: 2016-06-08,the day before Dragon Boat Festival.
Connector: lindan[AT]novogene.com
Usage1: perl $0 --data_list data.list --outdir . --shdir Shell --notrun

[options for version1]
        *--data_list    [file]     sample cleandata list, with format1:
                                   sample1ID        fq1,fq2
                                   sample2ID        fq1,fq2
                                   ...
                                   or with format2:
                                   sample1ID        fq
                                   sample2ID        fq
                                   ...
        --min_alignment_len  [str]  option to filter out short alignments in local mode. For long reads (>150) it is now recommended to use local mapping together with \"--min_alignment_len 100\" to filter out very short alignments. default:100
[other options]
         --vf           [str]      vf for metaphlan.anno,default=20G
         --num_proc     [str]      set number of threads for metaphlan.anno, default=10
         --shdir        [str]      output shell script directory, default is ./Shell
         --outdir       [str]      project directory,default is ./
         --notrun                  just produce shell script, not run
         --locate                  locate run, only locate run.
\n";

#set options
my($data_list, $min_alignment_len, $vf, $num_proc, $shdir, $outdir,$notrun, $locate, );

#set default options
$vf ||= "20G";
$num_proc ||= 10;
$shdir ||= "./Shell";
$outdir ||= ".";

#get options
GetOptions(
    "data_list:s" => \$data_list,
    "min_alignment_len:s" => \$min_alignment_len,
    "vf:s" => \$vf,
    "num_proc:s" => \$num_proc,
    "shdir:s" => \$shdir,
    "outdir:s" => \$outdir,
    "notrun" => \$notrun,
    "locate" => \$locate,
);

(-d $shdir) || system("mkdir -p $shdir");
$shdir=abs_path($shdir);
(-d $outdir) || system("mkdir -p $outdir");
$outdir=abs_path($outdir);
$data_list && ($data_list=abs_path($data_list));

# get software's path
use lib "$Bin/../../lib/00.Commbin";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin, $!\n";
my ($super_worker, $bowtie2db_mpa) = get_pathway("$Bin/../../bin/Pathway_cfg.txt", [qw(SUPER_WORK BOWTIE2DB_MPA)]);
my $fq2fa = "$Bin/lib/fq2fa.v2.pl";
my $metaphlan="$Bin/lib/metaphlan.py";

#metaphlan tax anno
my($qsub_run,$locate_run);
my $splits = '\n\n';
if($data_list && -s $data_list || die "$help"){

    (-s "$outdir/00.prepare.bzip2") || `mkdir -p $outdir/00.prepare.bzip2`;
    (-s "$outdir/01.bowtie") || `mkdir -p $outdir/01.bowtie`;
    (-s "$outdir/02.profiled_samples") || `mkdir -p $outdir/02.profiled_samples`;
    
    open SH1, ">$shdir/step1.prepare.bzip2.sh";
    open SH, ">$shdir/step2.metaphlan.sh";

    open F, $data_list;
    while(<F>){
        chomp;
        my ($sampleid,$fqs) = (split /\s+/)[0,1];
        my @fqs=split/,/,$fqs;
        $fqs=join(" ",@fqs);

        #step1. prepare for metaphlan
        #step2, for metaphlan
        print SH1 "perl $fq2fa $fqs --merge --outdir $outdir/00.prepare.bzip2 --prefix $sampleid\n\n";
        print SH "rm $outdir/01.bowtie/$sampleid.bt2out\n";
        if($min_alignment_len){
           print SH "$Bin/lib/metaphlan.py --bowtie2db $bowtie2db_mpa --min_alignment_len $min_alignment_len --bt2_ps sensitive --nproc $num_proc --input_type multifasta --bowtie2out $outdir/01.bowtie/$sampleid.bt2out $outdir/00.prepare.bzip2/$sampleid.fa $outdir/02.profiled_samples/$sampleid.txt\n\n"; 
        }else{
           print SH "$Bin/lib/metaphlan.py --bowtie2db $bowtie2db_mpa --bt2_ps sensitive --nproc $num_proc --input_type multifasta --bowtie2out $outdir/01.bowtie/$sampleid.bt2out $outdir/00.prepare.bzip2/$sampleid.fa $outdir/02.profiled_samples/$sampleid.txt\n\n";
        } 
    }
    close F;
    close SH1;
    close SH;

    $qsub_run .= "$super_worker step1.prepare.bzip2.sh --resource 800M --prefix prepare.bzip2 -splits '$splits' \n";
    $locate_run .= "sh step1.prepare.bzip2.sh\n";

    $qsub_run .="$super_worker step2.metaphlan.sh --resource $vf --prefix metaphlan.anno -splits '$splits'\n";
    $locate_run .= "sh step2.metaphlan.sh\n";

    #step3, merge tables,get relative
    open SH, ">$shdir/step3.stat.sh";
    print SH "mkdir -p $outdir/03.Stat\n" if ! -s "$outdir/03.Stat";
    print SH "mkdir -p $outdir/03.Stat/Relative\n" if ! -s "$outdir/03.Stat/Relative";
    print SH "#abundance table merge
$Bin/lib/utils/merge_metaphlan_tables.py $outdir/02.profiled_samples/*.txt > $outdir/03.Stat/merged_abundance_table.txt
$Bin/lib/plotting_scripts/metaphlan_hclust_heatmap.py -c bbcry --minv 0.1 -s log --in $outdir/03.Stat/merged_abundance_table.txt --out $outdir/03.Stat/abundance_heatmap.png
#relative abundance
perl $Bin/lib/abundance.trans.v2.pl $outdir/03.Stat/merged_abundance_table.txt $outdir/03.Stat/Relative\n";
    close SH;

    $qsub_run .="$super_worker step3.stat.sh --resource 800M --prefix metaphlan.stat -splits '$splits'\n";   
    $locate_run .= "sh step3.stat.sh\n"; 
}

open SH, ">$shdir/qsub.sh";
print SH $qsub_run;
close SH;

$notrun && exit;
$locate ? 
system"cd $shdir 
$locate_run " :
system"cd $shdir
$qsub_run ";


