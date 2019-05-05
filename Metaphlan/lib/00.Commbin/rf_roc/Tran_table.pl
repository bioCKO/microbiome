#!/usr/bin/perl -w
use strict;
@ARGV || die"Name: Tran_table.pl
Description: script to tran table data
Connector: liuwenbin, liuwenb\@novogene.cn
Usage: perl Tran_table.pl <in.table> > out.table\n";
my $intable = shift;
(-s $intable) || die"Error: can't fiand able input file $intable, $!";#die $!;
my $i = 0;
my @data;
open IN,$intable || die$!;
while(<IN>){
    chomp;
    my @l = /\t/ ? split/\t/ : split;
    for my $j(0 .. $#l){
        $data[$j][$i] = $l[$j];
    }
    $i++;
}
close IN;
for (@data){
    print join("\t",@{$_}),"\n";
}
