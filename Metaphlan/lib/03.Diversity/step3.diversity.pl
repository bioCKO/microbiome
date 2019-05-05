#!/usr/bin/perl -w
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use strict;

#set options
my($step, $relative_dir, $top_heatmap, $top_bar, $mf, $lefse_vs, $locate, $qsub, $locate_run, $qsub_run, $notrun, $shdir, $outdir, $help);
#set default options
$step ||= '1234';
$top_bar ||= "10";
$top_heatmap ||=35;
$shdir ||= "./Shell";
$outdir ||= ".";

#get options
GetOptions("step:s" => \$step,
        "relative_dir:s" => \$relative_dir,
#"absolute_dir:s" => \$absolute_dir,
        "top_bar:s" => \$top_bar,
        "top_heatmap:s" => \$top_heatmap,
        "mf:s" => \$mf,
        "lefse_vs:s" => \$lefse_vs,
#"Vslist_t:s" => \$Vslist_t,
        "locate" => \$locate,
        "qsub" => \$qsub,
        "notrun" => \$notrun,
        "shdir:s" => \$shdir,
        "outdir:s" => \$outdir,
        "help" => \$help,
        );

(-d $shdir) || system("mkdir -p $shdir");
$shdir=abs_path($shdir);
(-d $outdir) || system("mkdir -p $outdir");
$outdir=abs_path($outdir);
$mf && ($mf=abs_path($mf));
$lefse_vs && ($lefse_vs=abs_path($lefse_vs));
#$Vslist_t=abs_path($Vslist_t);

# get software's path
use lib "$Bin/../../lib/00.Commbin";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin, $!\n";
my ($super_worker, $graphlan_source, $lefse_plot, $lefse_source) = get_pathway("$Bin/../../bin/Pathway_cfg.txt", [qw(SUPER_WORK GRAGPHLAN_SOURCE LEFSE_PLOT LEFSE_SOURCE)]); 

$help = "Name: $0
Description: script for diversity analysis
Version:1.0
Date: 2016-06-08,the day before Dragon Boat Festival.
Usage: perl step3.diversity.pl --relative_dir relativePath --mf group.list --lefse_vs lefse.list --shdir Shell --outdir . --notrun 

    --relative_dir[dir]   dir of metaphlan anno result: the relative abundance tables of k p c o f g s
    --step        [str]   default:1234. 
                          step1: TopN heatmap and bar diagram
                          step2: GraPhlAn 
                          step3: LEfSe
                          step4: Wilcox test 
    --top_bar     [n]     for step1, topN drawing for bar diagram,default=10
    --top_heatmap [n]     for step1, topN drawing for heatmap,default=35
    --mf          [file]  set sample group, form: sample_name group_name
    --lefse_vs    [file]  for step3 LEfSe, the specified Comparison group info,look like: a  b
    --shdir       [dir]   mainly shell script directory
    --outdir      [dir]   output directory, default=.
    --notrun              only write the shell, but not run
    --locate              just run locate, not qusb
    --qusb                run qsub
    --help                help info
";
#=============================================================================================================================

($relative_dir && -d $relative_dir) || die "$help";

#top N for heatmap and bar diagram 
if($step =~ /1/){
#draw heatmap
open SH, ">$shdir/step1.heatmap.sh";
print SH "mkdir $outdir/step1.heatmap\ncd $outdir/step1.heatmap\n";
foreach(qw(k p c o f g s)){
print SH "
mkdir $outdir/step1.heatmap/$_;cd $outdir/step1.heatmap/$_; 
perl $Bin/lib/Amplication_cluster.pl $relative_dir/metaphlan.$_.relative.mat $_\_\_ $_.heatmap $top_heatmap\n";
}
close SH;
#draw bar
open SH, ">$shdir/step1.bar.sh";
print SH "
mkdir $outdir/step1.bar
cd $outdir/step1.bar
perl $Bin/lib/top.choose.pl $top_bar $relative_dir $outdir/step1.bar
perl $Bin/lib/Tran_table.pl $outdir/step1.bar $top_bar\n";
foreach(qw(k p c o f g s)){
    print SH "
perl $Bin/lib/bar_diagram.pl -table $outdir/step1.bar/$_/metaphlan.$_.top$top_bar.relative.trans.mat -right -grid -rotate='-45' -x_title 'Sample Name' -y_title 'RelativeAbundance' -rev_sym --y_mun 0.25,4 >$outdir/step1.bar/$_/$_.relative.top$top_bar.svg
convert $outdir/step1.bar/$_/$_.relative.top$top_bar.svg $outdir/step1.bar/$_/$_.relative.top$top_bar.png\n";
}
close SH;
}
$locate_run .= "sh step1.heatmap.sh &\nsh step1.bar.sh &\n";
$qsub_run .= "$super_worker step1.heatmap.sh --resource 1g --prefix step1.heatmap --splitn 1 --workdir $shdir/step1.heatmap\n$super_worker step1.bar.sh --resource 1g --prefix step1.bar --splitn 1 --workdir $shdir/step1.bar.sh\n";

#Graphlan analysis
if($step =~ /2/){
    open SH, ">$shdir/step2.Graphlan.sh";
    print SH "
mkdir -p $outdir/step2.Graphlan/tmp
mkdir -p $outdir/step2.Graphlan/outdir_images
cd $outdir/step2.Graphlan/
$graphlan_source
for file in $outdir/../02.MetaPhlAn/profiled_samples/*
do
    filename=\`basename \$\{file\}\`
    samplename=\$\{filename%\\\.*\}
    $Bin/../02.MetaPhlAn/lib/plotting_scripts/metaphlan2graphlan.py \$\{file\}  --tree_file tmp/\$\{samplename\}.tree.txt --annot_file tmp/\$\{samplename\}.annot.txt
    $Bin/lib/graphlan/graphlan_annotate.py --annot tmp/\$\{samplename\}.annot.txt tmp/\$\{samplename\}.tree.txt tmp/\$\{samplename\}.xml
    $Bin/lib/graphlan/graphlan.py --dpi 200 tmp/\$\{samplename\}.xml outdir_images/\$\{samplename\}.png
done\n";
close SH;
}
$locate_run .= "sh step2.Graphlan.sh &\n";
$qsub_run .= "$super_worker step2.Graphlan.sh --resource 5g --prefix step2.Graphlan --splitn 1 --workdir $shdir/step2.Graphlan\n"; 

#LEfSe analysis
if($step =~ /3/ && $lefse_vs && -s $lefse_vs && $mf && -s $mf){
    open SH,">$shdir/step3.LEfSe.sh";
    print SH " 
#LEfSe
mkdir $outdir/step3.LEfSe
cd $outdir/step3.LEfSe
$lefse_source
$lefse_plot --lefse_vs $lefse_vs $relative_dir $mf\n";
close SH;
}
$locate_run .= "sh step3.LEfSe.sh &\n";
$qsub_run .= "$super_worker step3.LEfSe.sh --resource 1g --prefix step3.LEfSe --splitn 1 --workdir $shdir/step3.LEfSe\n"; 

#Wilcox and MetaStat analysis
if($step =~ /4/){
    if($mf && -s $mf){
    open SH, ">$shdir/step4.Wilcox.sh"; 
    print SH "
mkdir $outdir/step4.Wilcox
cd $outdir/step4.Wilcox\n";
    foreach(qw(k p c o f g s)){
       print SH "
mkdir $outdir/step4.Wilcox/$_;cd $outdir/step4.Wilcox/$_;
perl $Bin/lib/compair_group.pl --wilcox $relative_dir/metaphlan.$_.relative.mat $mf >$_.wilcox.test.xls
awk -F '\\t' '{if(\$6 <= 0.05){print \$0}}' $_.wilcox.test.xls >$_.significant.group.wilcox.test.xls\n";
    }
    close SH;
    }
}
$locate_run .= "sh step4.Wilcox.sh &\n";
$qsub_run .= "$super_worker step4.Wilcox.sh --resource 1g --prefix step4.Wilcox --splitn 1 --workdir $shdir/step4.Wilcox\n";

if(!$locate){
open SH, ">$shdir/qsub.sh"|| die"Error:cannot creat $shdir/qsub.sh\n";
print SH $qsub_run;close SH;
}else{
open SH, ">$shdir/locate.sh"|| die"Error:cannot creat $shdir/locate.sh\n";
print SH $locate_run;close SH;
}

$notrun && exit;
$locate ? system"cd $shdir
$locate_run" :
system"cd $shdir
$qsub_run";



