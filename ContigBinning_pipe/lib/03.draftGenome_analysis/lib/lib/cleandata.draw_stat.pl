#!/usr/bin/perl
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);

my $clean_list = shift;
my $insertsize = shift;
my $prefix = shift;
my $outdir = shift;

$outdir = abs_path($outdir);
$prefix ||= "AllSample";

## get software's path
use lib "$Bin/../../../00.Commbin/";
my $lib = "$Bin/../../..";
use PATHWAY;
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin/, $!\n";
my ($fqcheck,) = get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(Fqcheck)],$Bin, $lib);

open F, $clean_list;
my @clusters;
while(<F>){
    chomp;
    my $cluster = (split/\s+/,$_)[0];
    push @clusters, $cluster;
}
close F;
my $cmd;
#open O, ">$outdir/bin_clean.$prefix.list";
#open QC, ">$outdir/qc.$prefix.list";
foreach(@clusters){
    $cmd .= "mkdir -p $outdir/$_\_$prefix;
mv -f $outdir/$_.L$insertsize\_libname_*.fq.clean.gz $outdir/$_\_$prefix;
cd $outdir/$_\_$prefix
$fqcheck -r $_.L$insertsize\_libname_1.fq.clean.gz -c $_.L$insertsize\_libname_1.fq.clean.check &
$fqcheck -r $_.L$insertsize\_libname_2.fq.clean.gz -c $_.L$insertsize\_libname_2.fq.clean.check & wait
perl $Bin/distribute_fqcheck_ng_v3.pl $_.L$insertsize\_libname_1.fq.clean.check $_.L$insertsize\_libname_2.fq.clean.check -o $_.L$insertsize.libname.fq.clean -id $_
rm -f *.GC *.QD *.QM *.R\n\n";
#  print O "$_ $outdir/$_\_$prefix/$_.L$insertsize\_libname_1.fq.clean.gz,$outdir/$_\_$prefix/$_.L$insertsize\_libname_2.fq.clean.gz\n";
}
close O;
#print $cmd;
system("$cmd");
