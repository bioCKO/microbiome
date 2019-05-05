#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set options
my ($data_list, $clean_list, $binCov_list, $insertsize, $vf, $dvf, $threads, $outdir, $shdir, $notrun, );

GetOptions("data_list:s" => \$data_list,
        "clean_list:s" => \$clean_list,
        "binCov_list:s" => \$binCov_list,
        "insertsize:s" => \$insertsize,
        "vf:s" => \$vf,
        "dvf:s" => \$dvf,
        "threads:s" => \$threads,
        "outdir:s" => \$outdir,
        "shdir:s" => \$shdir,
        "notrun" => \$notrun,
);

#set default options
$insertsize ||= 350;
$vf ||= "20g";
$dvf ||= "2g";
#$threads ||= "10";
$threads = "1";
$outdir ||= ".";
$shdir ||= "./Shell";


## get software's path
use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($super_worker, $filt_ref_reads, $fqcheck) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER FILTER_REF_READS Fqcheck)],$Bin, $lib);

#===============================================================================================================================
my $help = "Name: $0
Description: Script for draft-genome assembly and annotation for contig bins. 
Version: V1.0
Date:
Connector: lindan[AT]novogene.com
Usage: perl $0 -data_list ass.list -clean_list reads.list --binCov_list bin2sample.list --insertsize 350
[options for version1]
        *-data_list        [str] sample assembly seq(after chimera correction) list, with format:
                                  sample1ID   assembly seq path
                                  sample2ID   assembly seq path
                                  ...
        *-clean_list       [str] clean data fq list, with format:
                                  sample1ID   reads1 fq, reads2 fq
                                  sample2ID   reads1 fq, reads2 fq
                                  ...
                                  fq could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
        --binCov_list      [str] with the first column for the binID and the last column for the most abundant sampleID of the bin. 
                                 Format:
                                 #binID(First Column)   sampleID(Last Column)
                                 bin1                   sample1
                                 bin2                   sample2
                                 ... 
        --insertsize       [str] set insert size, default=350
        --vf               [str] set vf for qsub step2 spades assembly.
        --dvf              [str] set dvf for qsub step2 spades assembly.
        --threads          [str] set threads for qsub step2 spades assembly.          

[other options]
        --outdir           [str] project directory,default is ./
        --shdir            [str] output shell script directory, default is ./Shell
        --notrun           [str] just produce shell script, not run  

";
($data_list && -s $data_list && $clean_list && -s $clean_list && $binCov_list && -s $binCov_list) || die "$help\n";
#===============================================================================================================================
$data_list = abs_path($data_list);
$clean_list = abs_path($clean_list);
my $min_insertsize = $insertsize-100;
my $max_insertsize = $insertsize+100;
$outdir =~ s/\/$//g;
$shdir =~ s/\/$//g;
(-d $outdir) || `mkdir -p $outdir`;
(-d $shdir) || `mkdir -p $shdir`;
$outdir = abs_path($outdir);
$shdir = abs_path($shdir);

my @clusterIDs;
open SH, ">$shdir/qsub_Step1.binReadsMapping.sh";
    #step1: data combine    
    open SH1, ">$shdir/step1.1.dataCombine.sh";
    open F, $clean_list;
    my ($fq1s, $fq2s);
    my $sampleNum = 0;
    while(<F>){
        chomp;
        my $fqs = (split/\s+/,$_)[-1];
        my ($fq1, $fq2) = split/,/,$fqs;
        $fq1s .= "$fq1 "; $fq2s .= "$fq2 ";
        $sampleNum++;
    }close F;
    print SH1 
"cd $outdir; mkdir $outdir/01.dataCombine
perl $Bin/lib/gzip_cat.pl $fq1s $outdir/01.dataCombine/combine.fq1.gz
perl $Bin/lib/gzip_cat.pl $fq2s $outdir/01.dataCombine/combine.fq2.gz\n";
    my $binfas;
    open F, $data_list;
    while(<F>){
        chomp;
        my ($clusterID,$fa) = split/\s+/,$_;
        push @clusterIDs, $clusterID; 
        $binfas .= "$fa ";
    }close F; 
    print SH1
"mkdir $outdir/02.reads_Mapping; cd $outdir/02.reads_Mapping; 
cat $binfas >allbins.fa; 
ln -s $outdir/01.dataCombine/combine.fq1.gz . 
ln -s $outdir/01.dataCombine/combine.fq2.gz .\n"; 
    close SH1;
    
    #step2: reads mapping and abstraction
    open SH2, ">$shdir/step1.2.reads_mapping.sh";
    #abstract reads mapping to all bins from all sample reads.
    print SH2
"#bins reads mapping and abstract
cd $outdir/02.reads_Mapping;
$filt_ref_reads combine.fq1.gz combine.fq2.gz -d allbins.fa -c -m $min_insertsize -x $max_insertsize -b soap_mapping -s ' -l 32 -s 40 -v 8 -r 1 '\n";
    #abstract reads mapping to each bin from all sample reads.  
    print SH2
"perl $Bin/lib/reads.abstract.pl $data_list $outdir/02.reads_Mapping/soap_mapping/combine.fq1.gz.PE.soap $outdir/02.reads_Mapping/soap_mapping/combine.fq2.gz.SE.soap $outdir/02.reads_Mapping/combine.fq1.gz.out.gz $outdir/02.reads_Mapping/combine.fq2.gz.out.gz $insertsize\n";
    open O, ">$outdir/bin_clean.allsample.list"; 
    open QC, ">$outdir/qc.allsample.list";
    foreach(@clusterIDs){
        print O "$_ $outdir/02.reads_Mapping/$_\_AllSample/$_.L$insertsize\_libname_1.fq.clean.gz,$outdir/02.reads_Mapping/$_\_AllSample/$_.L$insertsize\_libname_2.fq.clean.gz\n";
        print QC "$_ libname $insertsize\n";
    }
    close O;
    close QC;
    print SH2
"perl $Bin/lib/cleandata.draw_stat.pl $outdir/bin_clean.allsample.list $insertsize AllSample $outdir/02.reads_Mapping\n";
    #abstract reads mapping to each bin from single sample(the most abundant one).
    print SH2 
"perl $Bin/lib/OneSample_reads.abstract.pl $clean_list $binCov_list $outdir/bin_clean.allsample.list $insertsize $outdir/02.reads_Mapping
perl $Bin/lib/cleandata.draw_stat.pl $outdir/bin_clean.onesample.list $insertsize OneSample $outdir/02.reads_Mapping\n";
    print SH2 
"mkdir  $outdir/02.reads_Mapping/stat
cd $outdir/02.reads_Mapping/stat
perl $Bin/lib/qc_stat.pl --list $outdir/qc.allsample.list --dir_type AllSample --cleandir $outdir/02.reads_Mapping --outdir .
perl $Bin/lib/qc_stat.pl --list $outdir/qc.onesample.list --dir_type OneSample --cleandir $outdir/02.reads_Mapping --outdir .\n";
    close SH2;

print SH 
"cd $shdir/
$super_worker --splitn 1 --resource 10g --qopts=\"-l num_proc=1\" step1.1.dataCombine.sh
$super_worker  --resource $vf --dvf $dvf --qopts=\"-l num_proc=$threads\" --splitn 1 step1.2.reads_mapping.sh\n"; 
close SH;

$notrun && exit; 
system "cd $shdir\nsh qsub_Step1.binReadsMapping.sh "; 
