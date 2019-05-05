#!/usr/bin/perl -w
use strict;
use PerlIO::gzip;
use Cwd qw(abs_path);
use Data::Dumper;
@ARGV>=2 || die "usage:perl $0 <fq1> <fq2> <unmapping> <output prefix>\n";
my ($fq1,$fq2,$unmapping,$prefix)=@ARGV;
$prefix||='Unmapped';

($unmapping =~ /\.gz$/) ? open IN,"gzip -dc $unmapping |"|| die$! : open IN,$unmapping || die$!;
$/="\n>";
my %peorse;
while(my$seq=<IN>){
    chomp$seq;
    $seq=~s/^>//;
    my $seqid=$1 if($seq=~/^(.*)/);
    $seq=~s/^.*//;
    $seq=~s/\s+//g;
    ${$peorse{$seqid}}[0]++;
    print $peorse{$seqid};
#   ${$peorse{$seqid}}[1]=$seq;	
}
close IN;	
  
$/="\n";
($fq1 =~ /\.gz$/) ? open FQ1,"gzip -dc $fq1|" || die$! : open FQ1,$fq1 || die$!;
($fq2 =~ /\.gz$/) ? open FQ2,"gzip -dc $fq2|" || die$! : open FQ2,$fq2 || die$!;
open(OUT1,">:gzip","$prefix.fq1.gz");
open(OUT2,">:gzip","$prefix.fq2.gz");
while (my$seqi=<FQ1>) {
    chomp$seqi;
    my$seqid=(split/\s+/,$seqi)[0];
    my$seqid2=(split/\s+/,<FQ2>)[0];
    $seqid=~s/^\@//;
    $seqid2=~s/^\@//;
    my $seq=<FQ1>;
    chomp$seq;
    my $seq2=<FQ2>;
    chomp$seq2;
    <FQ1>;
    <FQ2>;
    my $qual=<FQ1>;
    my $qual2=<FQ2>;
    if ($peorse{$seqid}) {
        print OUT1 "\@$seqid\n$seq\n+\n$qual";
        print OUT2 "\@$seqid2\n$seq2\n+\n$qual2";
    }
}
close FQ1;
close FQ2;
close OUT1;
close OUT2;
