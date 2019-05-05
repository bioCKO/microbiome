#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set options
my($data_list, $clean_list, $binning_evalue_method, $specific_type, $insertsize, $clusters, $length_threshhold, $minClsSize, $maxClsSize, $read_length, $outdir, $shdir, $super_worker, $notrun, $VF, $threads);

GetOptions("data_list:s" => \$data_list, 
    "clean_list:s" => \$clean_list,
    "binning_evalue_method:s" => \$binning_evalue_method, 
    "specific_type:s" => \$specific_type,
    "insertsize:s" => \$insertsize, 
    "clusters:s" => \$clusters, 
    "length_threshhold:s" => \$length_threshhold,
    "minClsSize:s" => \$minClsSize, 
    "maxClsSize:s" => \$maxClsSize, 
    "read_length:s" => \$read_length, 
    "outdir:s" => \$outdir, 
    "shdir:s" => \$shdir, 
    "notrun" => \$notrun, 
    "VF:s" => \$VF, 
    "threads:s" => \$threads,
); 

#set default options
$binning_evalue_method ||= "1";
$insertsize ||= 350;
($binning_evalue_method =~ /[12]/) && ($specific_type ||= "specific");
($binning_evalue_method =~ /[34]/) && ($clusters ||= 500) && ($read_length ||= 150);
$minClsSize ||= 500000;
$maxClsSize ||= 12000000;
$outdir ||= "."; 
$shdir ||= "./Shell";
$VF ||= "20g/2g;50g/10g";
$threads ||= "10;25";


## get software's path
use lib "$Bin/../00.Commbin/";
use PATHWAY;
my $lib = "$Bin/../";
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my ($super_worker, $uparse, $bowtie2_build, $bowtie2, $samtools, $genomeCoverageBed, $sh_control) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER UPARSE BWT_BUILD BOWTIE2 SAMTOOLS GENOMECOVERAGEBED SH_CONTROL)], $Bin, $lib);

#======================================================================================================================
my $help = "Name: $0
Description: Script for Contig Binning
Version: V2.0
Date:
Connector: lindan[AT]novogene.com
Usage1: perl $0 -data_list ass.list --clean_list reads.list --insertsize 350 --clusters 300 --length_threshhold 1000 --minClsSize 500000 --maxClsSize 12000000 --read_length 125 --binning_evalue_method 1
Usage2: perl $0 -data_list ass.list --clean_list reads.list --insertsize 350 --clusters 300 --length_threshhold 1000 
[options for version2]
        *-data_list        [str] sample assembly seq(after chimera correction) list, with format: 
                                  sample1ID   assembly seq path
                                  sample2ID   assembly seq path
                                  ...
        *-clean_list       [str] clean data fq list, with format:
                                  sample1ID   reads1 fq, reads2 fq
                                  sample2ID   reads1 fq, reads2 fq
                                  ...
                                  fq could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).

        --insertsize        [str] set insert size(bp), default=350
        --length_threshhold [str] the contig length cuffoff threshhold for both contig binning methods,default: 1500 for MetaBAT(ideally >=2500); 1000 for concoct.
        --binning_evalue_method   [str] choose contig-binning and binning clusters'quality evaluation methods combination for step2, 1: MetaBAT and CheckM; 2: MetaBAT and SCG; 3: Concoct and ChechM; 4: Concoct and SCG. Default=1. If set=1234, then the both contig-binning methods (MetaBAT and Concoct) will be run and each will be checked by both the clusters'quality evaluation methods (ChechM and SCG). 
        --minClsSize        [str] Minimum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=500000.
        --maxClsSize        [str] Maxmum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=12000000.
        --specific_type     [str] \"verysensitive\", \"specific\", or \"superspecific\", for metabat binning criteria. \"verysensitive\" for simple samples, \"specific\" for >=10 samples or moderately complex samples, \"superspecific\" for <10 samples or complex samples. default: \"specific\". 
        --clusters          [str] for concoct, set binning cluster numbers -- the estimated species numbers,default=500
        --read_length       [str] for concoct, the reads length set for concoct,default=150

[other options]
        --outdir      [str]       project directory,default is ./
        --shdir       [str]       output shell script directory, default is ./Shell
        --VF          [str]       set vf and dvf for step1 bowtie mapping and step2 metabat contig binning,default=20g/2g;50g/10g, the vf/dvf of concoct contig-binning will be set fourfold of MetaBAT.  
        --threads     [str]       set qsub threads for step1 bowtie mapping and step2 contig binning,defatult=10;25, the threads number of concoct contig-binning will be set twice of MetaBAT.
        --notrun                  just produce shell script, not run
\n";
#================================================================================================================================================================================
($data_list && -s $data_list && $clean_list && -s $clean_list) || die "$help\n";

#set options
$data_list = abs_path($data_list);
$clean_list = abs_path($clean_list);
$outdir =~ s/\/$//g; 
$shdir =~ s/\/$//g;
(-d $outdir) || `mkdir -p $outdir`; 
(-d $shdir) || `mkdir -p $shdir`;
$outdir = abs_path($outdir); 
$shdir = abs_path($shdir);
my @VF = split/;/,$VF;
my (@vfs,@dvfs);
foreach(@VF){my ($vf, $dvf) = split/\//,$_; push @vfs, $vf; push @dvfs, $dvf;}
my @threads = split/;/,$threads;

foreach(qw(step1.1.bowtiebuild step1.2.bowtie step2.contig_binning_evaluation)){
    (-d "$outdir/$_") || `mkdir $outdir/$_`;
}

my $splits = '\n\n';
open SH, ">$shdir/contig_binning.run.sh";

#step1: bowtie bulid and mapping
my ($total_contigs, %ass);
$total_contigs = "$outdir/step1.1.bowtiebuild/total.contigs.fasta";
open(F, $data_list);
while(<F>){
    chomp;
    my ($sampleID, $ass_path) = split /\s+/, $_;
    $ass{$sampleID} = $ass_path;
}
close F;
my @ass = values %ass;
my $cat_ass = join(" ", @ass);
write_file("$shdir/step1.1.bowtie-build.sh",
"cat $cat_ass > $total_contigs.ori
$uparse -derep_prefix $total_contigs.ori -output $total_contigs -sizeout
rm $total_contigs.ori
cd $outdir/step1.1.bowtiebuild
$bowtie2_build --large-index $total_contigs $total_contigs >bwt.log\n");
shell_box(*SH, "1) bowtie build", "step1.1.bowtie-build.sh", "--resource $vfs[0] --dvf $dvfs[0] --qopts=\"-l num_proc=$threads[0]\" --prefix step1.1.bowtie-build --splitn 1 --workdir $shdir/step1.1.bowtie-build");  

open(F, $clean_list);
my $min_insertsize = $insertsize-60; 
my $max_insertsize = $insertsize+60;
open SH1, ">$shdir/step1.2.bowtie.sh";
while(<F>){
    chomp;
    my ($sampleID, $reads_path) = split /\s+/, $_;
    my @reads = split /,/, $reads_path;
    (-d "$outdir/step1.2.bowtie/$sampleID/bowtie2/") || `mkdir -p "$outdir/step1.2.bowtie/$sampleID/bowtie2/"`;
print SH1
"cd $outdir/step1.2.bowtie/$sampleID/bowtie2/
$bowtie2 -x $total_contigs -1 $reads[0] -2 $reads[1] --sensitive -I $min_insertsize -X $max_insertsize --threads 8 -S ReadsMapping.bowtie.sam
$samtools view -bS ReadsMapping.bowtie.sam > ReadsMapping.bowtie.bam
$samtools sort ReadsMapping.bowtie.bam ReadsMapping.bowtie-s
$samtools index ReadsMapping.bowtie-s.bam
$genomeCoverageBed -ibam ReadsMapping.bowtie-s.bam > taxid.PESE.coverage\n\n";
}
close F;
close SH1;
shell_box(*SH, "1) bowtie mapping", "step1.2.bowtie.sh", "--resource $vfs[0] --dvf $dvfs[0] --qopts=\"-l num_proc=$threads[0]\" --prefix step1.2.bowtie -splits '$splits' --workdir $shdir/step1.2.bowtie"); 

(-d "$shdir/step2.contig_binning_evaluation") &&`mkdir -p $shdir/step2.contig_binning_evaluation`;
my ($metabat_binningflag, $concoct_binningflag);
################################################################################ If choose binning method: MetaBAT ##############################################################
if($binning_evalue_method =~ /[12]/){
#step2: MetaBAT binning
    $length_threshhold ||= 1500;
    my $metabat_evaluate_method = $binning_evalue_method;
    $metabat_evaluate_method =~ s/[34]//g;
    (-d "$shdir/step2.contig_binning_evaluation/metabat_binning_evaluate") && `mkdir -p $shdir/step2.contig_binning_evaluation/metabat_binning_evaluate`;
    (-d "$outdir/step2.contig_binning_evaluation/metabat_binning_evaluate") && `mkdir -p $outdir/step2.contig_binning_evaluation/metabat_binning_evaluate`;
    write_file("$shdir/step2.metabat_binning_evaluate.sh",
"perl $Bin/lib/metabat_binning_evaluation.pl --binning_evalue_method $metabat_evaluate_method --data_list $data_list --specific_type $specific_type --length_threshhold $length_threshhold --minClsSize $minClsSize --maxClsSize $maxClsSize --outdir $outdir/step2.contig_binning_evaluation/metabat_binning_evaluate --shdir $shdir/step2.contig_binning_evaluation/metabat_binning_evaluate\n");
    shell_box(*SH, "2) MetaBAT Binning and Evaluation", "step2.metabat_binning_evaluate.sh", 0, "$outdir/step2.contig_binning_evaluation/step2.metabat_binning_evaluate.finish");
    $metabat_binningflag = 1; 
}

################################################################################ If choose binning method: Concoct ##############################################################
if($binning_evalue_method =~ /[34]/){
#step2: Concoct binning
    $length_threshhold ||= 1000;
    my $concoct_evaluate_method = $binning_evalue_method;
    $concoct_evaluate_method =~ s/[12]//g;
    my $vf = $vfs[1]; $vf =~ s/g//g;
    my $dvf = $dvfs[1]; $dvf =~ s/g//g;
    my $concoct_vf = $vf*4; $concoct_vf .= "g"; 
    my $concoct_dvf = $dvf*4; $concoct_dvf .= "g";
    my $concoct_threads = $threads[1]*2;
    (-d "$shdir/step2.contig_binning_evaluation/concoct_binning_evaluate") && `mkdir -p $shdir/step2.contig_binning_evaluation/concoct_binning_evaluate`;
    (-d "$outdir/step2.contig_binning_evaluation/concoct_binning_evaluate") && `mkdir -p $outdir/step2.contig_binning_evaluation/concoct_binning_evaluate`;
    write_file("$shdir/step2.concoct_binning_evaluate.sh",
"perl $Bin/lib/concoct_binning_evaluation.pl --binning_evalue_method $concoct_evaluate_method --vf $concoct_vf --dvf $concoct_dvf --thread $concoct_threads --length_threshhold $length_threshhold --minClsSize $minClsSize --maxClsSize $maxClsSize --clusters $clusters --read_length $read_length --outdir $outdir/step2.contig_binning_evaluation/concoct_binning_evaluate --shdir $shdir/step2.contig_binning_evaluation/concoct_binning_evaluate\n");
    shell_box(*SH, "2) concoct Binning and Evaluation", "step2.concoct_binning_evaluate.sh", 0, "$outdir/step2.contig_binning_evaluation/step2.concoct_binning_evaluate.finish");
    $concoct_binningflag = 1;
}

($metabat_binningflag eq "1") && ($concoct_binningflag eq "1") ?
check_task(*SH, "3) Contig-binning and Evaluation", "$outdir/step2.contig_binning_evaluation/step2.metabat_binning_evaluate.finish $outdir/step2.contig_binning_evaluation/step2.concoct_binning_evaluate.finish", "$shdir/step3.contig_binning_evaluate.check.sh", "step3.concoct_binning_evaluate.check") :
($metabat_binningflag eq "1") ?
check_task(*SH, "3) Contig-binning and Evaluation", "$outdir/step2.contig_binning_evaluation/step2.metabat_binning_evaluate.finish", "$shdir/step3.contig_binning_evaluate.check.sh", "$shdir/step3.concoct_binning_evaluate.check") :
($concoct_binningflag eq "1") ?
check_task(*SH, "3) Contig-binning and Evaluation", "$outdir/step2.contig_binning_evaluation/step2.concoct_binning_evaluate.finish", "$shdir/step3.contig_binning_evaluate.check.sh", "$shdir/step3.concoct_binning_evaluate.check") :
0;

close SH;

$notrun || system"cd $shdir\nnohup sh contig_binning.run.sh"; 

#==============
sub write_file{
#==============
     my $file = shift;
     open SSH,">$file" || die$!;
     for(@_){
         print SSH;
     }
     close SSH;
}

#==============
sub check_task{
#==============
      my ($handel,$STEP,$rec,$outputsh,$workdir) = @_;
      open(MSH,">$outputsh");
      my $filename=$1 if($outputsh=~/.*\/(.*)/);
      print MSH "$sh_control $rec --notsend --sleept 300 \n";
      print $handel "#== check $STEP\ndate +\"\%D \%T -> Checking $STEP\"\nnohup $super_worker --workdir $workdir --resource     vf=1G -qopts ' -V ' $filename >& $filename.log\n",
            "date +\"\%D \%T -> Finished checking $STEP\"\n\n";
      close MSH;

}

#==============
sub shell_box{
#=============
     my ($handel,$STEP,$shell,$qopt,$bgrun) = @_;
     my $middle= $qopt ? "nohup $super_worker $qopt --head=\"cd `pwd`\" $shell" : "nohup sh $shell >& $shell.log";
     my $end = "date +\"\%D \%T -> Finish $STEP\"";
     if($bgrun){
         (-s $bgrun) && `rm $bgrun`;
         if($qopt && $qopt !~ /-splitn\s+1\b/){
         $middle .= " --endsh '$end > $bgrun'";
         }else{
        ($shdir && $shell !~ m#^/#) && ($shell = "$shdir/$shell"); 
        `echo '$end > $bgrun' >> $shell`;
         }
         $STEP .= " background";
#$middle .= " &";
#        $end = " ";
    }
    print $handel "##$STEP\ndate +\"\%D \%T -> Start  $STEP\"\n$middle\n$end\n\n";
}




