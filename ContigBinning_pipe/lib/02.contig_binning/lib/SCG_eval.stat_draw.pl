#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);

@ARGV >= 3 || die"<SCG_stat> <coverage_table> <bins_directary> must be input!\n";

my $SCG_stat = shift;
my $cov_table = shift;
my $bins_dir = shift;
my $outdir = shift; 
$outdir ||= ".";
(-d $outdir) && `mkdir $outdir`;

my $cmd;
$cmd .= "perl $Bin/SCGeval_stat.pl $SCG_stat $cov_table $bins_dir $outdir\n".
"perl $Bin/Bin_GC-Depth.stat.pl $cov_table $bins_dir >$outdir/Bin_GC-Depth.stat.xls\n".
"Rscript $Bin/Bin_GC-Depth.draw.R $outdir/Bin_GC-Depth.stat.xls $outdir\n".
"perl $Bin/Bin_stat2.pl $bins_dir\n\n";
open O, ">$bins_dir/bins_stat1.sh";
print O $cmd;
system("sh $bins_dir/bins_stat1.sh");
