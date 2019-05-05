#!/usr/bin/perl -w
use strict;
@ARGV || die"Name: Tran_table.pl
Description: script to tran table data
Connector: liuwenbin, liuwenb\@novogene.cn
Usage: perl Tran_table.pl <in.table> > out.table\n";
my $indir = shift;
my $top = shift;
(-d $indir) || die"Error: can't find table input dir $indir, $!";#die $!;
my @intables;
#foreach(qw(k p c o f g s)){push @intables, "$indir/$_/metaphlan.$_.top$top.relative.mat";}
#foreach(`ls $indir/s/metaphlan.[cfgkops].top$top.relative.mat`){
my @files = glob "$indir/*.relative.xls";
foreach(@files){
chomp;
my $i = 0;
my @data;
my $intable = $_;#print $intable."\n";
#open IN,$intable;
#while(<IN>){
for(`less $intable`){
    chomp;
    my @l = /\t/ ? split/\t/ : split;
    for my $j(0 .. $#l){
        $data[$j][$i] = $l[$j];
    }
    $i++;
}
#close IN;
pop(@data);
my $outtable = "$intable.trans.xls"; $outtable =~ s/\.xls\.trans/\.trans/g;
open O, ">$outtable";
for (@data){
    print O join("\t",@{$_}),"\n";
}close O;
@data = ();
}
