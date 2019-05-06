#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set options
my($data_list, $total_contigs, $binning_evalue_method, $specific_type, $length_threshhold, $minClsSize, $maxClsSize, $outdir, $shdir, $super_worker, $vf, $dvf, $thread, $notrun);

GetOptions("data_list:s" => \$data_list,
    "total_contigs:s" => \$total_contigs, 
    "binning_evalue_method:s" => \$binning_evalue_method, 
    "specific_type:s" => \$specific_type,
    "length_threshhold:s" => \$length_threshhold,
    "minClsSize:s" => \$minClsSize, 
    "maxClsSize:s" => \$maxClsSize, 
    "outdir:s" => \$outdir, 
    "shdir:s" => \$shdir, 
    "vf:s" => \$vf,
    "dvf:s" => \$dvf,
    "thread:s" => \$thread,
    "notrun" => \$notrun, 
); 

#set default options
$total_contigs ||= "$outdir/../../step1.1.bowtiebuild/total.contigs.fasta";
$binning_evalue_method ||= "1";
($specific_type ||= "specific") && ($length_threshhold ||= 1500);
$minClsSize ||= 500000;
$maxClsSize ||= 12000000;
$outdir ||= "."; 
$shdir ||= "./Shell";
$vf ||= "50g";
$dvf ||= "10g";
$thread ||= "15";

## get software's path
use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($super_worker, $sh_control, $python2_7, $jgi_summarize_bam_contig_depths, $metabat, $prodigal) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER SH_CONTROL PYTHON2_7 JGI_SAM_DEPTH METABAT PRODIGAL)], $Bin, $lib);
#======================================================================================================================
my $help = "Name: $0
Description: Script for MetaBAT Contig Binning and Evaluation
Version: V1.0
Date:
Connector: lindan[AT]novogene.com
Usage1: perl $0 -data_list ass.list --clean_list reads.list --clusters 300 --length_threshhold 1000 --minClsSize 500000 --maxClsSize 12000000 --read_length 125 --binning_evalue_method 1
Usage2: perl $0 -data_list ass.list --clean_list reads.list  --clusters 300 --length_threshhold 1000 
[options for version1]
        *-data_list        [str] sample assembly seq(after chimera correction) list, with format: 
                                  sample1ID   assembly seq path
                                  sample2ID   assembly seq path
                                  ...
        --total_contigs     [str] total assembly contigs after removing redundancy.
        --length_threshhold [str] the contig length cuffoff threshhold for both contig binning methods,default: 1500 for MetaBAT(ideally >=2500); 1000 for concoct.
        --binning_evalue_method   [str] choose contig-binning clusters'quality evaluation methods combination, 1: MetaBAT and CheckM; 2: MetaBAT and SCG; Default=1. If set=12, then the metabat binning result will be checked by both the clusters'quality evaluation methods (ChechM and SCG). 
        --minClsSize        [str] Minimum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=500000.
        --maxClsSize        [str] Maxmum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=12000000.
        --specific_type     [str] \"verysensitive\", \"specific\", or \"superspecific\", for metabat binning criteria. \"verysensitive\" for simple samples, \"specific\" for >=10 samples or moderately complex samples, \"superspecific\" for <10 samples or complex samples. default: \"specific\". 

[other options]
        --outdir      [str]       project directory,default is ./
        --shdir       [str]       output shell script directory, default is ./Shell
        --notrun                  just produce shell script, not run
        --vf          [str]       set vf for metabat binning.
        --thread      [str]       set the number of threads for metabat binning.
\n";
#================================================================================================================================================================================
($data_list && -s $data_list) || die "$help\n"; 

#set options
$data_list = abs_path($data_list);
$outdir =~ s/\/$//g; 
$shdir =~ s/\/$//g;
(-d $outdir) || `mkdir -p $outdir`; 
(-d $shdir) || `mkdir -p $shdir`;
$outdir = abs_path($outdir); 
$shdir = abs_path($shdir);

my %ass;
#step1: bowtie bulid and mapping
open(F, $data_list);
while(<F>){
    chomp;
    my ($sampleID, $ass_path) = split /\s+/, $_;
    $ass{$sampleID} = $ass_path;
}
close F;

open SH, ">$shdir/metabat_binning_evaluation.sh" || die $!;
my $bam_string;
my @sampleIDs = keys %ass;
foreach(@sampleIDs){
    $bam_string .= "$outdir/../../step1.2.bowtie/$_/bowtie2/ReadsMapping.bowtie-s.bam ";
}
#step1: MetaBAT binning
write_file("$shdir/step1.metabat_binning.sh",
"mkdir -p $outdir/step1.metabat_binning
cd $outdir/../../step1.2.bowtie
$python2_7 $Bin/gen_input_table.py --isbedfiles --samplenames <(for s in *; do echo \$s ; done)  $total_contigs */bowtie2/*.coverage  > $outdir/step1.metabat_binning/concoct_inputtable.tsv
cut -f1,3- $outdir/step1.metabat_binning/concoct_inputtable.tsv >$outdir/step1.metabat_binning/concoct_inputtableR.tsv
cd $outdir/step1.metabat_binning
$jgi_summarize_bam_contig_depths --outputDepth depth.txt --pairedContigs paired.txt $bam_string
mkdir metabat_bin1/;
$metabat -i $total_contigs -a depth.txt -o metabat_bin1/Bin --minContig $length_threshhold --saveTNF saved_$length_threshhold.tnf --saveDistance saved_$length_threshhold.dist -v  -B 20 --keep --$specific_type --pB 20\n"); 
shell_box(*SH, "1)metabat contig binning","step1.metabat_binning.sh", "--resource $vf --dvf $dvf --splitn 1 --qopts=\"-l num_proc=$thread \" --prefix step1.metabat_binning --workdir $shdir/step1.metabat_binning"); 
   
####if choose binning evaluation method: CheckM
if($binning_evalue_method =~ /1/){
#step2: CheckM evaluation
    write_file("$shdir/step2.metabat.CheckM_eval.sh",
"mkdir -p $outdir/step2.metabat.CheckM_eval
cd $outdir/step2.metabat.CheckM_eval
mkdir metabat_bin1/;mkdir metabat_bin1/SCG; rm -rf metabat_bin1/SCG/*;     
perl $Bin/metabat.bins.len.choose.pl $minClsSize $maxClsSize $outdir/step1.metabat_binning/metabat_bin1 $outdir/step2.metabat.CheckM_eval/metabat_bin1
source MetaBAT/activate.sh
checkm lineage_wf -f metabat_bin1/CheckM.txt -t 8 -x fa $outdir/step2.metabat.CheckM_eval/metabat_bin1 metabat_bin1/SCG
perl $Bin/CheckM.choose.pl metabat_bin1/CheckM.txt $outdir/step1.metabat_binning/concoct_inputtable.tsv metabat_bin1/ metabat_choosebins/
perl $Bin/CheckM_eval.stat_draw.pl $outdir/step2.metabat.CheckM_eval/CheckM.substantial_bin.stat.xls $outdir/step1.metabat_binning/concoct_inputtable.tsv $outdir/step2.metabat.CheckM_eval/metabat_choosebins/ $outdir/step2.metabat.CheckM_eval\n"); 
    shell_box(*SH, "2) metabat CheckM evaluation", "step2.metabat.CheckM_eval.sh", "--resource $vf --dvf $dvf --splitn 1 --qopts=\"-l num_proc=$thread \" --prefix step2.metabat.ChechM_eval --workdir $shdir/step2.metabat.CheckM_eval", "step2.metabat.CheckM_eval.finish");        
}
####if choose binning evaluation method: SCG
if($binning_evalue_method =~ /2/){
#step2: SCG evaluation
    write_file("$shdir/step2.metabat.SCG_eval.sh",
"mkdir -p $outdir/step2.metabat.SCG_eval
cd $outdir/step2.metabat.SCG_eval
$prodigal -a $outdir/step2.metabat.SCG_eval/Uniq.Scaftigs.faa -i $outdir/../../step1.1.bowtiebuild/total.contigs.fasta -f gff -p meta  > $outdir/step2.metabat.SCG_eval/Uniq.Scaftigs.gff
$Bin/RPSBLAST.sh -f $outdir/step2.metabat.SCG_eval/Uniq.Scaftigs.faa -p -c 8 -r 1
perl $Bin/clustering.csv.pl $outdir/step1.metabat_binning/metabat_bin1 >clustering_gt$length_threshhold.csv 
$python2_7 $Bin/COG_table.py -b $outdir/step2.metabat.SCG_eval/Uniq.out -m $Bin/scg_cogs_min0.97_max1.03_unique_genera.txt -c $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold.csv --cdd_cog_file $Bin/cdd_to_cog.tsv >$outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.tab
perl $Bin/SCG.choose.pl $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.tab > $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab
Rscript $Bin/COGPlot.R -s $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab -o $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.pdf
convert -density 200 clustering_gt$length_threshhold\_scg.pdf clustering_gt$length_threshhold\_scg.png 
perl $Bin/scaffolds.abstract.pl $outdir/step2.metabat.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab $outdir/step2.metabat.SCG_eval/metabat_choosebins $outdir/../../step1.1.bowtiebuild/total.contigs.fasta
perl $Bin/SCG_eval.stat_draw.pl $outdir/step2.metabat.SCG_eval/SCG.stat.xls $outdir/step1.metabat_binning/concoct_inputtable.tsv $outdir/step2.metabat.SCG_eval/metabat_choosebins/ $outdir/step2.metabat.SCG_eval\n"); 
    shell_box(*SH, "2) metabat SCG evaluation", "step2.metabat.SCG_eval.sh", "--resource 5g --dvf 1G --prefix step2.metabat.SCG_eval --splitn 1 --workdir $shdir/step2.metabat.SCG_eval", "step2.metabat.SCG_eval.finish"); 
}
    
check_task(*SH, "metabat binning and evaluation", "$outdir/step2.metabat.CheckM_eval/step2.metabat.CheckM_eval.finish $outdir/step2.metabat.SCG_eval/step2.metabat.SCG_eval.finish", "$shdir/step3.metabat_binning_evaluation.check.sh", "$shdir/step3.metabat_binning_evaluation.check");

close SH;

($notrun) || system"cd $shdir; nohup sh metabat_binning_evaluation.sh\n";

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

