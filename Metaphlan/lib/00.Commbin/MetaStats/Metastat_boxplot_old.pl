#! /usr/bin/perl -w

=head1 Name

    metastat_boxplot.pl -- script for metastats analysis and draw boxplot picture

=head1 Version

    Author: Lifeng Li, lilifeng@novogene.com
    Version: 1.0  Date: 2015-06-18

=head1 Usage

  perl metastat_boxplot.pl --input <input absolute table> --relative <input relative table> --mf all.mf --vs vs.list [options]
                
     *-input   [file]   set the input absolute table for metastats
     *-relative[file]   set the input relative table for drawing boxplot 
     *-mf      [file]   set the group information
     *-vs      [file]   set The Comparison group info,look like: a  b
     --cutoff  [num]    set the cutoff value or sig for MetaStats,[default 0.05]
     --prefix  [str]    set the output prefix, default=un
     --top     [num]    set the top number of the top difference,default=12
     --og               output og trees for metastats
     --colour  [str]    choose colour for groups,default=#cb4154,#1dacd6,#66ff00
     --outdir  [dir]    set the output directory, default is ./MetaStats
     --notrun           just output shell script, not qsub
     --help    [str]    output help information to the screen
                          ms: output MetaStats help information to the screen


=cut

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
my %opt = (outdir=>'./MetaStats',prefix=>'un',top=>12,cutoff=>0.05);
GetOptions(
    \%opt,"outdir:s","input:s","relative:s","prefix:s","mf:s","vs:s","top:n","cutoff:n","notrun","help:s","colour:s","og",
);

#get software pathway
use lib "$Bin/../";
my $lib = "$Bin/../../";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin, $!\n";
my ($rscript,$heatmap,$pca) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(Rscript HEATMAP PCA_R)],$Bin,$lib);
my $metastats="$rscript $Bin/lib/MetaStats/MetaStat1.3.fun.R ";
my $totalpsig="perl  $Bin/lib/boxplot/total_qsig.pl";
my $diffabsolute="perl $Bin/lib/boxplot/get_diff_absolute.pl";
my $diffxls="perl $Bin/lib/boxplot/get_diff_xls.pl"; 
my $funboxplot="perl $Bin/lib/boxplot/draw_fun_boxplot2.0.pl";
my $og_tree="perl $Bin/lib/get.og.tree.pl ";

#output help information
if($opt{help}){
    ($opt{help} eq 'ms') ? system"$metastats -h" :
    die"error: --help just can be selected from ms\n";
    exit;
}
#====================================================================================================================
die `pod2text $0` unless($opt{input} && -s $opt{input} && $opt{relative} && -s $opt{relative} && $opt{mf} && -s $opt{mf} && $opt{vs} && -s $opt{vs});
#options set
(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
(-s "$opt{outdir}/boxplot") || `mkdir -p $opt{outdir}/boxplot`;
$opt{outdir}=abs_path($opt{outdir});
$metastats .= " --outdir $opt{outdir} ";
$opt{input} && ($opt{input}=abs_path($opt{input}));
$metastats .= " --infilepath $opt{input} ";
$opt{prefix} && ($metastats .= " --output $opt{prefix} ");
$opt{mf} && ($opt{mf}=abs_path($opt{mf}));
$metastats .= " --group $opt{mf} ";
$funboxplot .= " --mf $opt{mf} ";
$opt{vs} && ($opt{vs}=abs_path($opt{vs}));
$metastats .= " --Vslist $opt{vs} ";
$opt{cutoff} && ($metastats .= " --threshold $opt{cutoff} ");
$opt{colour} && ($funboxplot .= " --colour $opt{colour} ");
$opt{relative} && ($opt{relative}=abs_path($opt{relative}));

## main script
my $main_shell="$opt{outdir}/$opt{prefix}.metastats.sh";
open(SH,">$opt{outdir}/$opt{prefix}.metastats.sh");
print SH "cd $opt{outdir}
$metastats    
$totalpsig ./ $opt{prefix}\_qsig.xls
[ `less $opt{prefix}\_qsig.xls|wc -l` -eq 1 ] &&  exit
$diffabsolute $opt{prefix}\_qsig.xls $opt{relative} $opt{prefix}\_diff_relative
$diffxls $opt{mf} $opt{outdir}/$opt{prefix}\_diff_relative.xls $opt{vs} $opt{outdir}/boxplot/files
$funboxplot --dir $opt{outdir}/boxplot/files -qsig $opt{outdir}/$opt{prefix}\_qsig.xls --outdir $opt{outdir}/boxplot --top $opt{top}
$heatmap $opt{outdir}/$opt{prefix}\_diff_relative.heatmap.xls level__  cluster.$opt{prefix}.diff\n";
print  SH "mkdir -p $opt{outdir}/PCA/\ncd $opt{outdir}/PCA/\n",
    'perl -ne \'chomp;$_=~s/^Ortholog_Group// unless($i);@or=split/\t/;$i++;print join("\t",@or)."\n";\'',
    " $opt{outdir}/$opt{prefix}\_diff_relative.xls > $opt{outdir}/PCA/$opt{prefix}.relative.og.xls\n",
    "$pca $opt{outdir}/PCA/$opt{prefix}.relative.og.xls $opt{mf} $opt{outdir}/PCA/ 2>pca.log\n";
print SH "$og_tree $opt{outdir}/$opt{prefix}\_diff_relative.xls $opt{outdir}/og.trees\n" if $opt{og};
close SH;

$opt{notrun} && exit;
system"cd $opt{outdir}\n
nohup sh $main_shell\n";

#====================================================================================================================

