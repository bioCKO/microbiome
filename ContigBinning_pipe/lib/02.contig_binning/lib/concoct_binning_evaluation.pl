#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set options
my($total_contigs, $binning_evalue_method, $specific_type, $insertsize, $clusters, $length_threshhold, $minClsSize, $maxClsSize, $read_length, $outdir, $shdir, $super_worker, $notrun, $vf, $dvf, $thread, $h);

GetOptions(
    "total_contigs:s" => \$total_contigs,
    "binning_evalue_method:s" => \$binning_evalue_method, 
    "specific_type:s" => \$specific_type,
    "clusters:s" => \$clusters, 
    "length_threshhold:s" => \$length_threshhold,
    "minClsSize:s" => \$minClsSize, 
    "maxClsSize:s" => \$maxClsSize, 
    "read_length:s" => \$read_length, 
    "outdir:s" => \$outdir, 
    "shdir:s" => \$shdir, 
    "notrun" => \$notrun, 
    "vf:s" => \$vf, 
    "dvf:s" => \$dvf,
    "thread:s" => \$thread,
    "h" => \$h,
); 

#set default options
$total_contigs ||= "$outdir/../../step1.1.bowtiebuild/total.contigs.fasta";
$binning_evalue_method ||= "3";
($length_threshhold ||= 1000) && ($clusters ||= 500) && ($read_length ||= 150);
$minClsSize ||= 500000;
$maxClsSize ||= 12000000;
$outdir ||= "."; 
$shdir ||= "./Shell";
$vf ||= "250g";
$dvf ||= "50g";
$thread ||= "30";


## get software's path
use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($super_worker, $sh_control, $python2_7, $concoct_source, $concoct, $checkM_source, $prodigal, $Rscript) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SUPER_WORKER SH_CONTROL PYTHON2_7 CONCOCT_SOURCE CONCOCT CHECKM_SOURCE PRODIGAL Rscript)],$Bin, $lib);

#======================================================================================================================
my $help = "Name: $0
Description: Script for Concoct Binning and Evaluation
Version: V1.0
Date:
Connector: lindan[AT]novogene.com
Usage1: perl $0 --clusters 300 --length_threshhold 1000 --minClsSize 500000 --maxClsSize 12000000 --read_length 125 --binning_evalue_method 3
Usage2: perl $0 --clusters 300 --length_threshhold 1000 
[options for version1]
        --total_contigs     [str] total assembly contigs after removing redundancy. 
        --length_threshhold [str] the contig length cuffoff threshhold for both contig binning methods,default: 1500 for MetaBAT(ideally >=2500); 1000 for concoct.
        --binning_evalue_method   [str] choose contig-binning and binning clusters'quality evaluation methods combination for step2 concoct binning, 3: Concoct and ChechM; 4: Concoct and SCG. Default=1. If set=34, then the concoct binning result will be checked by both the clusters'quality evaluation methods (ChechM and SCG). 
        --minClsSize        [str] Minimum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=500000.
        --maxClsSize        [str] Maxmum size(bp) of a bin to be chosen for CheckM/SCGs evaluation, default=12000000.
        --clusters          [str] for concoct, set binning cluster numbers -- the estimated species numbers,default=500
        --read_length       [str] for concoct, the reads length set for concoct,default=150

[other options]
        --outdir      [str]       project directory,default is ./
        --shdir       [str]       output shell script directory, default is ./Shell
        --vf          [str]       set vf for concoct binning. 
        --threads     [str]       set number of threads for concoct binning. 
        --notrun                  just produce shell script, not run
\n";
#================================================================================================================================================================================
($h) && die "$help\n";

#set options
$outdir =~ s/\/$//g; 
$shdir =~ s/\/$//g;
(-d $outdir) || `mkdir -p $outdir`; 
(-d $shdir) || `mkdir -p $shdir`;
$outdir = abs_path($outdir); 
$shdir = abs_path($shdir);


open SH, ">$shdir/concoct_binning_evaluation.sh" || die $!;

#step1: concocct binning
write_file("$shdir/step1.concoct_binning.sh",
"mkdir -p $outdir/step1.concoct_binning
cd $outdir/../../step1.2.bowtie
$python2_7 $Bin/gen_input_table.py --isbedfiles --samplenames <(for s in *; do echo \$s ; done)  $total_contigs */bowtie2/*.coverage  > $outdir/step1.concoct_binning/concoct_inputtable.tsv
cut -f1,3- $outdir/step1.concoct_binning/concoct_inputtable.tsv >$outdir/step1.concoct_binning/concoct_inputtableR.tsv
$concoct_source
$python2_7 $concoct -c $clusters -r $read_length -l $length_threshhold --coverage_file $outdir/step1.concoct_binning/concoct_inputtableR.tsv --composition_file $total_contigs -b $outdir/step1.concoct_binning --total_percentage_pca 80 --iterations 100
#rm $outdir/step1.concoct_binning/*dim*.csv
$Rscript $Bin/ClusterPlot.R -c $outdir/step1.concoct_binning/clustering_gt$length_threshhold.csv -p $outdir/step1.concoct_binning/PCA_transformed_data_gt$length_threshhold.csv -m $outdir/step1.concoct_binning/pca_means_gt$length_threshhold.csv -r $outdir/step1.concoct_binning/pca_variances_gt$length_threshhold\_dim -l -o $outdir/step1.concoct_binning/ClusterPlot.pdf\n");
shell_box(*SH, "1)concoct binning", "step1.concoct_binning.sh", "--resource $vf --dvf $dvf -splitn 1 --qopts=\"-l num_proc=$thread -q mem3.q -P mem3\" --prefix step1.concoct_binning --workdir $shdir/step1.concoct_binning"); 

#step2: LCA tax annotation and evaluation
write_file("$shdir/step2.concoct.taxAnno_eval.sh",
"mkdir -p $outdir/step2.concoct.taxAnno_eval
mkdir -p $shdir/step2.concoct.taxAnno_eval
perl $Bin/Taxonomy/lib/get_len_fa.pl $total_contigs >$outdir/step2.concoct.taxAnno_eval/query_len.list
perl $Bin/Taxonomy/TaxAnnotationFlow.binning.pl --split 100 --file $total_contigs --prefix allbins.Scaftigs --query_len $outdir/step2.concoct.taxAnno_eval/query_len.list --outdir $outdir/step2.concoct.taxAnno_eval --shdir $shdir/step2.concoct.taxAnno_eval
perl $Bin/Taxonomy/lib/2.concoct.trans.pl $outdir/step2.concoct.taxAnno_eval/MicroNT/MicroNT_stat/allbins.Scaftigs.lca.tax.xls $outdir/step2.concoct.taxAnno_eval/MicroNT/MicroNT_stat/clustering_gt$length_threshhold\_s.csv
perl $Bin/Validate.pl --cfile=$outdir/step1.concoct_binning/clustering_gt$length_threshhold.csv --sfile=$outdir/step2.concoct.taxAnno_eval/MicroNT/MicroNT_stat/clustering_gt$length_threshhold\_s.csv --ofile=$outdir/step2.concoct.taxAnno_eval/clustering_gt$length_threshhold\_conf.csv --ffile=$total_contigs >$outdir/step2.concoct.taxAnno_eval/TaxValidate.info\n");
shell_box(*SH, "2) LCA tax annotation", "step2.concoct.taxAnno_eval.sh");

#step3: Linkage incorporation of the bins
write_file("$shdir/step3.concoct.clusterLinkage_eval.sh",
"mkdir -p $outdir/step3.concoct.clusterLinkage_eval
cd $outdir/../../step1.2.bowtie
$python2_7 $Bin/bam_to_linkage.py -m 8 --regionlength 500 --fullsearch --samplenames <(for s in *; do echo \$s | cut -d'_' -f1; done) $total_contigs */bowtie2/ReadsMapping.bowtie-s.bam > $outdir/step3.concoct.clusterLinkage_eval/concoct_linkage.tsv
cd $outdir/step3.concoct.clusterLinkage_eval
perl $Bin/ClusterLinkNOverlap.pl --cfile=$outdir/step1.concoct_binning/clustering_gt$length_threshhold.csv --lfile=$outdir/step3.concoct.clusterLinkage_eval/concoct_linkage.tsv --covfile=$outdir/step1.concoct_binning/concoct_inputtableR.tsv --ofile=$outdir/step3.concoct.clusterLinkage_eval/clustering_gt$length_threshhold\_l.csv >ClusterLinkNOverlap.log
perl $Bin/Validate.pl --cfile=$outdir/step3.concoct.clusterLinkage_eval/clustering_gt$length_threshhold\_l.csv --sfile=$outdir/step2.concoct.taxAnno_eval/MicroNT/MicroNT_stat/clustering_gt$length_threshhold\_s.csv --ofile=clustering_gt$length_threshhold\_conf.csv >ClusterLinkNOverlap.info
perl $Bin/linkage.eval.pl $outdir/step2.concoct.taxAnno_eval/TaxValidate.info $outdir/step3.concoct.clusterLinkage_eval/ClusterLinkNOverlap.info $length_threshhold $outdir
sed -i \"/NA/d\" $outdir/clustering_gt$length_threshhold\_conf.csv
$Rscript $Bin/ConfPlot.R -c $outdir/clustering_gt$length_threshhold\_conf.csv -o $outdir/clustering_gt$length_threshhold\_conf.pdf\n");
shell_box(*SH, "3) Linkage incorporation evaluation", "step3.concoct.clusterLinkage_eval.sh", "--resource 10g --prefix step3.concoct.clusterLinkage_eval --splitn 1 --workdir $shdir/step3.concoct.clusterLinkage_eval");

#step4: binning clusters' evaluation
####if choose binning evalutaion methodn: CheckM
if($binning_evalue_method =~ /3/){
    write_file("$shdir/step4.concoct_binning.CheckM_eval.sh",
"mkdir -p $outdir/step4.concoct.CheckM_eval/concoct_bin1;
mkdir $outdir/step4.concoct.CheckM_eval/concoct_bin1/SCG; rm -rf $outdir/step4.concoct.CheckM_eval/concoct_bin1/SCG/*;
cd $outdir/step4.concoct.CheckM_eval; 
perl $Bin/concoct.bins.len.choose.pl $minClsSize $maxClsSize $outdir/step1.concoct_binning/concoct_inputtable.tsv $outdir/clustering_gt$length_threshhold.csv $outdir/../../step1.1.bowtiebuild/total.contigs.fasta $outdir/step4.concoct.CheckM_eval/concoct_bin1
$checkM_source
checkm lineage_wf -f concoct_bin1/CheckM.txt -t 8 -x fa concoct_bin1 concoct_bin1/SCG
perl $Bin/CheckM.choose.pl concoct_bin1/CheckM.txt $outdir/step1.concoct_binning/concoct_inputtable.tsv concoct_bin1/ $outdir/step4.concoct.CheckM_eval/concoct_choosebins 
perl $Bin/CheckM_eval.stat_draw.pl $outdir/step4.concoct.CheckM_eval/CheckM.substantial_bin.stat.xls $outdir/step1.concoct_binning/concoct_inputtable.tsv $outdir/step4.concoct.CheckM_eval/concoct_choosebins/ $outdir/step4.concoct.CheckM_eval/\n"); 
    shell_box(*SH, "4) CheckM evaluation", "step4.concoct_binning.CheckM_eval.sh", "--resource 50g --dvf 10G --qopts=\"-l num_proc=15 -q mem3.q -P mem3\" --prefix step4.concoct_binning.CheckM_eval --splitn 1 --workdir $shdir/step4.concoct.CheckM_eval", "step4.concoct.CheckM_eval.finish");
}
####if choose binning evalutaion method: SCG
if($binning_evalue_method =~ /4/){
    write_file("$shdir/step4.concoct_binning.SCG_eval.sh",
"mkdir -p $outdir/step4.concoct.SCG_eval/concoct_choosebins;
cd $outdir/step4.concoct.SCG_eval;
$prodigal -a $outdir/step4.concoct.SCG_eval/Uniq.Scaftigs.faa -i $outdir/../../step1.1.bowtiebuild/total.contigs.fasta -f gff -p meta  > $outdir/step4.concoct.SCG_eval/Uniq.Scaftigs.gff
$Bin/RPSBLAST.sh -f $outdir/step4.concoct.SCG_eval/Uniq.Scaftigs.faa -p -c 8 -r 1
$python2_7 $Bin/COG_table.py -b $outdir/step4.concoct.SCG_eval/Uniq.out -m $Bin/scg_cogs_min0.97_max1.03_unique_genera.txt -c $outdir/clustering_gt$length_threshhold.csv --cdd_cog_file $Bin/cdd_to_cog.tsv >$outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.tab
perl $Bin/SCG.choose.pl $outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.tab > $outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab
$Rscript $Bin/COGPlot.R -s $outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab -o $outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.pdf
convert -density 200 clustering_gt$length_threshhold\_scg.pdf clustering_gt$length_threshhold\_scg.png 
perl $Bin/scaffolds.abstract.pl $outdir/step4.concoct.SCG_eval/clustering_gt$length_threshhold\_scg.choose.tab $outdir/step4.concoct.SCG_eval/concoct_choosebins $outdir/../../step1.1.bowtiebuild/total.contigs.fasta
perl $Bin/SCG_eval.stat_draw.pl $outdir/step4.concoct.SCG_eval/SCG.stat.xls $outdir/step1.concoct_binning/concoct_inputtable.tsv $outdir/step4.concoct.SCG_eval/concoct_choosebins/ $outdir/step4.concoct.SCG_eval\n"); 
    shell_box(*SH, "4) SCG evaluation", "step4.concoct_binning.SCG_eval.sh", "--resource 5g --dvf 1G --prefix step4.concoct_binning.SCG_eval --splitn 1 --workdir $shdir/step4.concoct.SCG_eval", "step4.concoct.SCG_eval.finish");
}

#step5: check concoct binning and evaluation 
check_task(*SH, "concoct binning and evaluation", "$outdir/step4.concoct.CheckM_eval/step4.concoct.CheckM_eval.finish $outdir/step4.concoct.SCG_eval/step4.concoct.SCG_eval.finish", "$shdir/step5.concoct.binning_evaluation.check.sh", "$shdir/step5.concoct.binning_evaluation.check");

close SH;

$notrun || system"cd $shdir\nnohup sh concoct_binning_evaluation.sh";

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
      print MSH "$sh_control $rec --notsend --sleept 100 \n";
      print $handel "#== check $STEP\ndate +\"\%D \%T -> Checking $STEP\"\nnohup $super_worker --workdir $workdir --resource vf=500M -qopts ' -V ' $filename >& $filename.log\n",
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
         $middle .= " &";
         $end = " ";
    }
    print $handel "##$STEP\ndate +\"\%D \%T -> Start  $STEP\"\n$middle\n$end\n\n";
}

