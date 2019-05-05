#!/usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use PerlIO::gzip;
use File::Basename;
### Set options
my %opt = (out=>'.',prefix=>'output');
GetOptions(
#\%opt,"fqlist:s","out:s","merge","prefix:s"
        \%opt,"outdir:s","merge","prefix:s",
);
@ARGV || die"
Name: fq2fa.pl
Description: Convert fastq file to fasta file.
Contacts: yelei\@novogene.com
Usage: perl $0  fq1.gz fq2.gz --outdir ./ --prefix outout [--options]
    --merge             merge the output fasta into a single file
    --outdir <str>      set output dir,default ./    
    --prefix            set output prefix,default=output
\n";

(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
my $outdir=abs_path($opt{outdir});

### Main scripts
if($opt{merge}){
    open FA, ">$outdir/$opt{prefix}.fa";
    foreach my $file (@ARGV){
        $file =~ /gz$/ ? open FQ1, "<:gzip",$file || die $! : open FQ1,$file || die $!;
		my $f = (split /\//,$file)[-1];
		my $l=$1 if($f=~/.+?\.fq(\d)\.gz/);
        my $i;
		while(my $head1 = <FQ1>){
            my $seq1 = <FQ1>;  <FQ1>;  <FQ1>;
			$i++;
            $head1 =~ s/^\@//;
            $head1 = "$opt{prefix}\_$i/$l";
			print FA ">$head1\n$seq1";
        }
        close FQ1;
    }
    close FA;
}else{
    open FA1,">$outdir/$opt{prefix}_1\.fa";
    open FA2,">$outdir/$opt{prefix}_2\.fa";
    my@fqs=@ARGV;
    for (my $i = 0; $i < $#fqs+1;$i+=2){
        my $fq1 = $fqs[$i];
        my $fq2 = $fqs[$i+1];
        $fq1 =~ /gz$/ ? open FQ1, "<:gzip",$fq1 || die $! : open FQ1,$fq1 || die $!;
        $fq2 =~ /gz$/ ? open FQ2, "<:gzip",$fq2 || die $! : open FQ2,$fq2 || die $!;
        while(my $head1 = <FQ1>){
            my $seq1 = <FQ1>;  <FQ1>;  <FQ1>;
            my $head2 = <FQ2>;
            my $seq2 = <FQ2>;  <FQ2>;  <FQ2>;
            $head1 =~ s/^\@//;$head2 =~ s/^\@//;
            print FA1 ">$head1",$seq1;
            print FA2 ">$head2",$seq2;
        }
        close FQ1;
        close FQ2;
    }
    close FA1;
    close FA2;
}
