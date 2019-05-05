#!usr/bin/perl -w
use strict;

(@ARGV==3)||die "Usage:perl $0 <total_psig.xls> <Uniq.Scaftigs.relative.c.xls> <outfile>\n";

my ($infile1,$infile2,$outfile)=@ARGV;

my @diff;
open IN,$infile1||die$!;
<IN>;
my %exists;
while(<IN>){
    chomp;
    my @tmp=split /\t/;
    $exists{$tmp[0]}=1;
 }
close IN;

open IN,$infile2||die$!;
open OUT,">$outfile.xls";
open OUT2,">$outfile.heatmap.xls";
my $sample = <IN>;
print OUT "$sample";
print OUT2 "$sample";
while (my $line = <IN>){
    chomp $line;
    my @tmp=split /\t/ ,$line;
    pop@tmp;
    if ( $exists{$tmp[0]} ){
    print OUT join("\t",@tmp)."\n";
    print OUT2 "level__".join("\t",@tmp)."\n";
  }
}
close IN;
close OUT;
close OUT2;
