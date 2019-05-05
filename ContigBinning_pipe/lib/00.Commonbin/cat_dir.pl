#!/usr/bin/perl -w
use strict;
use PerlIO::gzip;
(@ARGV==2) || die"usage: perl $0 <indir>  <outfile/outfile.gz>\n";

my ($file_find,$outfile)=@ARGV;
($outfile =~ /\.gz$/) ? open OUT,">:gzip",$outfile || die$! : open OUT,">$outfile" || die$!;
my @files= `ls $file_find`;
@files || die" No file named '$file_find`\n";
for my $file (@files){
    chomp $file;
    (-s $file) || next;
    ($file =~ /\.gz$/) ? open IN,"<:gzip",$file || die$! : open IN,$file || die$!;     
    while(<IN>){
    print OUT;
    }
    close IN;
}
close OUT;
