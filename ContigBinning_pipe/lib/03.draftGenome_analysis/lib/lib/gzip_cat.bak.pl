#!/usr/bin/perl -w
use strict;
use PerlIO::gzip;
@ARGV<2 && die"Uage: perl $0 <in1.gz> <in2.gz> ... <out.gz>\n";
my $outfile = pop;
($outfile =~ /\.gz$/) ? open OUT,">:gzip",$outfile || die$! : open OUT,">$outfile" || die$!;
for my $f(@ARGV){
    (-s $f) || next;
    ($f =~ /\.gz$/) ? open IN,"<:gzip",$f || die$! : open IN,$f || die$!;
    while(<IN>){
        print OUT;
    }
    close IN;
}
close OUT;
