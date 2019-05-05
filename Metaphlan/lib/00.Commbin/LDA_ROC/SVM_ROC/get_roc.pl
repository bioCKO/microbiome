#!/usr/bin/perl -w
use strict;
@ARGV ==3 || die"Usage:perl $0 infile group.list roc_file.xls\n";
my($infile,$group,$outfile)=@ARGV;
my(%group,);
for(`less $group`){
    chomp;
    my @line= split /\t/;
    $group{$line[0]}=$line[1];
}
open IN,"<$infile" || die $!;
open OUT,">$outfile";
my $head=<IN>;
my @head=split /\t/,$head;
shift @head;
print OUT "Sample\tClass\t",join("\t",@head);
while(<IN>){
    chomp;
    my @line = split /\t/;
    my $sample=shift @line;
    print OUT "$sample\t$group{$sample}\t",join("\t",@line),"\n";
}
close IN;
close OUT;
