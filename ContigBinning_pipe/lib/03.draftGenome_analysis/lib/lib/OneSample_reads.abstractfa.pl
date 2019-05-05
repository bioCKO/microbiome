#!/usr/bin/perl
use File::Basename;
use Cwd qw(abs_path);
use PerlIO::gzip;

my $DataList = shift;
my $bin2sample = shift;
my $binReadsList = shift;
my $insertsize = shift;
my $outdir = shift;

$outdir = abs_path($outdir);

my (%choosebin2sample,%choose_sample);
my %bin2sample;
open F, $bin2sample;
<F>;
while(<F>){
    chomp;
    my ($binID, $coverage, $sampleID) = (split/\s+/,$_)[0,-2,-1];
    if($coverage >= 10){
        $choosebin2sample{$binID} = 1;
        $choose_sample{$sampleID} = 1;
        $bin2sample{$binID} = $sampleID;
    }
}close F;

my %sample2fq;
#open F, $DataList;
#while(<F>){
for(`less $DataList`){
    chomp;
    my ($sampleID, $fqs) = split/\s+/,$_;
    if(not exists $choose_sample{$sampleID}){ next;}
    my ($fq1, $fq2) = split/,/,$fqs;
    open IN1,  $fq1 || die $!;
    open IN2,  $fq2 || die $!;
    while(my $info1 = <IN1>,my $info2 = <IN2>){
        my $readID1 = $info1;
        my $readID2 = $info2;
        $readID1 =~ s/\/\d$//g; $readID1 =~ s/^\@//;$readID1 =~ s/^\>//;
        $readID2 =~ s/\/\d$//g; $readID2 =~ s/^\@//;$readID2 =~ s/^\>//;
        $info1 .= <IN1> ;
        $info2 .= <IN2> ;
        $sample2fq{$sampleID}{$readID1} = $info1;
        $sample2fq{$sampleID}{$readID2} = $info2;
    }
    close IN1;close IN2;
}
#close F;

open O, ">$outdir/../bin_clean.onesample.list";
open QC, ">$outdir/../qc.onesample.list";
open F, $binReadsList;
while(<F>){
     chomp;
     my ($bin, $fqs) = split/\s+/,$_;
     my ($fq1, $fq2) = split/,/,$fqs;
     if(not exists $choosebin2sample{$bin}){next;}
     my $readID;
     open O1, ">:gzip","$outdir/$bin.L$insertsize\_libname_1.fq.clean.gz"||die $!;
     open O2, ">:gzip","$outdir/$bin.L$insertsize\_libname_2.fq.clean.gz"||die $!;
     foreach(split/\n/, `gzip -dc $fq1 |grep \'^>\'`){
         my $readID = $_;
         $readID =~ s/\/\d$//g; $readID =~ s/^\@//;$readID =~ s/^\>//;
         if(exists $sample2fq{$bin2sample{$bin}}{$readID}){
             print O1 "$sample2fq{$bin2sample{$bin}}{$readID}";
         }
     }
     foreach(split/\n/, `gzip -dc $fq2 |grep \'^>\'`){
         my $readID = $_;
         $readID =~ s/\/\d$//g; $readID =~ s/^\@//;$readID =~ s/^\>//;
         if(exists $sample2fq{$bin2sample{$bin}}{$readID}){
             print O2 "$sample2fq{$bin2sample{$bin}}{$readID}";
         }
     }

     print O "$bin\t$outdir/$bin\_OneSample/$bin.L$insertsize\_libname_1.fq.clean.gz,$outdir/$bin\_OneSample/$bin.L$insertsize\_libname_2.fq.clean.gz\n";
     print QC "$bin\tlibname\t$insertsize\n";
}
close F;
close O;
close QC;
