#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
@ARGV>=3 || die"Usage: perl $0 <indir> <group> [outdir] input_prefix
Example: perl Run_NMDS.pl Absolute/ all.mf NMDS/ input_prefix\n";
my ($indir,$group,$outdir,$prefix) = @ARGV;
$indir = abs_path($indir);
$group = abs_path($group);
$outdir ||= ".";
(-d $outdir) || mkdir($outdir);
$outdir = abs_path($outdir);
$prefix ||= "Unigenes.absolute";
my @sign = qw(phylum class order family genus species);
my @sign2 = qw(p c o f g s);
for my $i(0..$#sign){
    (-d "$outdir/$sign[$i]") || mkdir"$outdir/$sign[$i]";
    system"perl $Bin/NMDS.R.pl $indir/$prefix.$sign2[$i].xls  $group  $outdir/$sign[$i] -T 2> $outdir/$sign[$i]/log";
}
