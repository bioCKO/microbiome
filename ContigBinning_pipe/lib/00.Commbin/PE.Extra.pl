#!/usr/bin/perl -w
use strict;
use PerlIO::gzip;
use Cwd qw(abs_path);
use Data::Dumper;
@ARGV>=2 || die "usage:perl $0 <fq1> <fq2> <output prefix>\n";
my ($fq1,$fq2,$prefix)=@ARGV;

$prefix||='Unmapped';

($fq1 =~ /\.gz$/) ? open IN,"<:gzip",$fq1 || die$! : open IN,$fq1 || die$!;
$/="\n@";
my %peorse;
while(my$seq=<IN>){
    chomp$seq;
    my $seqid=$1 if($seq=~/^(.*)/);
    $seqid=~s/\/[12]//;
    $peorse{$seqid}=1;
}
close IN;	

my %peorse2;
open(OUT2,">:gzip","$prefix\_2.fq.gz");
($fq2 =~ /\.gz$/) ? open IN,"<:gzip",$fq2 || die$! : open IN,$fq2 || die$!;
$/="\n\@";
while(my$seq=<IN>){
    chomp$seq;
    my $seqid=$1 if($seq=~/^(.*)/);
    $seqid=~s/\/[12]//;
    $seq=~s/^\@//;
    if( $peorse{$seqid}){
        print OUT2 "\@$seq\n";
        $peorse2{$seqid}=1;
    }
}
close IN;   
close OUT2;

open(OUT1,">:gzip","$prefix\_1.fq.gz");
($fq1 =~ /\.gz$/) ? open IN,"<:gzip",$fq1 || die$! : open IN,$fq1 || die$!;
$/="\n\@";
while(my$seq=<IN>){
    chomp$seq;
    my $seqid=$1 if($seq=~/^(.*)/);
    $seqid=~s/\/[12]//;
    $seq=~s/^\@//;
    print OUT1"\@$seq\n" if $peorse2{$seqid};
}
close IN;
close OUT1;
