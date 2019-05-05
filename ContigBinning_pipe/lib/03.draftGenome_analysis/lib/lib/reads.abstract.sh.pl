#!/usr/bin/perl
use strict;
use FindBin qw($Bin);

my $indir1 = shift;
my $indir2 = shift;
my @len_files = glob "$indir1/*.CDS.fa.len.xls";
foreach(@len_files){
    my $prefix = (split/\//,$_)[-1];
    $prefix = (split/\./,$prefix)[0];
    print "perl $Bin/reads.abstract.pl $_ $indir2/combine.fq1.gz.PE.soap $indir2/combine.fq2.gz.SE.soap combine.fq1.gz.out.gz combine.fq2.gz.out.gz $prefix\n";
}
