#!/usr/bin/perl -w
use strict;
use warnings;
@ARGV==3 || die"Name: topN sort script
Usage: perl $0 <TopN> <Intable_Dir> <Outdir>\n";
#my @table = glob "o_abundance_table.txt";
my $top = shift;
my $indir = shift;
my $outdir = shift;
my $head;
#foreach(@table){
my @rank = qw(k p c o f g s);
foreach(@rank){
    my $infile = "$indir/metaphlan.$_.relative.xls";
    open F, $infile;
    my $head = <F>;
    open O, ">$outdir/$_.top$top.relative.xls";
    print O $head;
    my %hash; my %ha_record;
    while(<F>){
        chomp;
        my @arr = split /\t/, $_;
        my $taxid = $arr[0];
        $ha_record{$taxid} = "$_";
        my @abu = @arr[1..$#arr-1];
        my $max;
        foreach my $i(1..$#abu){
            if($abu[0]<$abu[$i]){
                $max = $abu[$i];
            }else{
                $max = $abu[0];
            }
        }
        $hash{$taxid} = $max;
    }
    close F; 
    my @keys = sort{$hash{$b}<=>$hash{$a}} keys %hash;
    if($#keys>$top-2){
        foreach(0..$top-1){
            print O $ha_record{$keys[$_]}."\n"; 
        }
    }else{
        foreach(0..$#keys){
            print O $ha_record{$keys[$_]}."\n";
        }
    }
    close O;
}


