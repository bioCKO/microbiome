#!/usr/bin/perl -w
use strict;
my @otu_num;
@ARGV == 2 || die "Usage:perl $0 <otu_table.even.txt> <outfile>\n";
my ($otu,$outfile) = @ARGV;
open IN,$otu || die"Can't open file:$otu";
open OUT,">$outfile" || die $!;
while(<IN>){
    chomp;
    @otu_num =/\t/ ? split /\t/ : split;
    pop @otu_num;
    $otu_num[0]=~s/^.*\b// if $.==1;
    $otu_num[0]=~s/\.//g;
    $otu_num[0]=~s/[\[\]\(\)\"\'\#\@\$]//g;
    $otu_num[0] =~ s/[\;\:\s+]/_/g;
    print OUT "@otu_num\n";

    }
close IN;
close OUT;
