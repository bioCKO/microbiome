#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
@ARGV>=2 || die"Name: PCAcluster.pl
Author: lihang, lihang\@novogene.cn
Version: 1.0, Date: 2014-07-01
Usage: perl PCAcluster.pl <indir> <group> [outdir] input_prefix
Example: perl PCAcluster.pl 03.Make_OTU/otu97/Relative/ all.mf PCA/ input_prefix\n";
my ($indir,$group,$outdir,$prefix) = @ARGV;
$indir = abs_path($indir);
$group = abs_path($group);
$outdir ||= ".";
(-d $outdir) || mkdir($outdir);
$outdir = abs_path($outdir);
my @sign = qw(phylum class order family genus species);
my @sign2 = qw(p c o f g s);
for my $i(0..$#sign){
    (-d "$outdir/$sign[$i]") || mkdir"$outdir/$sign[$i]";
    system"perl $Bin/PCA.R.pl $indir/$prefix.$sign2[$i].xls  $group  $outdir/$sign[$i] -T 2> $outdir/$sign[$i]/log";
}
