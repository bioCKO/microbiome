#!/usr/bin/perl

use Cwd qw(abs_path);

my $minCsize = shift;
my $maxCsize = shift;
my $cov_file = shift;
my $concoct_file = shift;
my $allcontigs = shift;
my $outdir = shift;
$outdir = abs_path($outdir);
$outdir ||= ".";

my %scaf2len;
open F, $cov_file;
<F>;
while(<F>){
    chomp;
    my ($scafid, $len) = (split/\s+/,$_)[0..1];
    $scaf2len{$scafid} = $len;
}close F;

my %cluster2len;
my %cluster2scaf;
open F, $concoct_file;
while(<F>){
    chomp;
    my ($scafid, $index) = split/,/,$_;
    $cluster2len{$index} += $scaf2len{$scafid};
    $cluster2scaf{$index}{$scafid} = 1;
}close F;

my %scaf2seq;
open F, $allcontigs;
$/ = "\n>";
while(defined($seq=<F>)){
    chomp $seq;
    $seq=~s/^>//;
    my $id=$1 if $seq=~/^(\S+)/;
    $seq=~s/^.*//;
    $seq=~s/\s+//g;
    $scaf2seq{$id} = $seq;
}
close F;

my %chooseBins;
foreach my $index (keys %cluster2len){
    if($cluster2len{$index} >= $minCsize && $cluster2len{$index} <= $maxCsize){
        open O, ">$outdir/$index.fa";
        foreach my $id(keys $cluster2scaf{$index}){
            print O ">$id\n$scaf2seq{$id}\n"; 
        }
        close O;
    }
}


