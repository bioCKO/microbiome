#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my %opt = ("size:s","300M","out","cut.fa");
GetOptions(\%opt,"list:s","size:s","out:s");

$opt{list} ||
die"Description: for one sample, transform fq to fasta, and cut data size to \$opt{size}.
Uasage: perl  $0  --list clean_fq.list --size 300M --out  F10.L450_300M.fa 
    [options]
        *--list     [str]   list of one sample's clean fq or fq.gz
                            Form of list:
	                            F10.L450_1.fq.gz
	                            F10.L450_2.fq.gz
        --size      [str]   data size to get. form: 330M/0.33G/330000000. default use all 
        --outdir    [str]   outdir, default= .
\n";
if ($opt{size} ) {
    $opt{size} = ($opt{size} =~ /(\d+\.*\d*)[Mm]/) ?  $1*10**6 
        :  ($opt{size} =~ /(\d+\.*\d*)[Gg]/) ? $1*10**9 
        :  ($opt{size} =~ /(\d+\.*\d*)[Kk]/) ? $1*10**3 
        :  ($opt{size} =~ /(\d+)b?/) ? $1 
        : "-1";
    ($opt{size} eq "-1") && die "Error: wrong data size.\n";
}
open LIST, "$opt{list}" ||die$!;
open OUT, ">$opt{out}" ||die$!;
my $reads_out = 0;
my $reads_fa = "";
while (<LIST>) {
	chomp;
	/^#/ || !/\S+/ && next;
	 (/\.gz$/) ? (open READS, "<:gzip", $_) : (open READS, $_) || die $!;
	 while (<READS>) {
	 	my $line1= $_;
        if ($opt{size}){
	 	    if ($reads_out < $opt{size}) {
                $line1 =~ s/^@/>/g;
	 		    my $line2 = <READS>;
	 		    $reads_out += (length($line2)-1);
	 		    print OUT "$line1$line2";
	 		    <READS>; <READS>; 
	 	    }else{
	 		    last;
	 	    }
        }else{
            $line1 =~ s/^@/>/g;
            my $line2 = <READS>;
	 		print OUT "$line1$line2";
            <READS>; <READS>; 
        }
	 }
	 close READS;
	 $opt{size} && ($reads_out >= $opt{size}) && last;
}
close OUT;
close LIST;
