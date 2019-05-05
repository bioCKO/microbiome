#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use PerlIO::gzip;
# set default options
my %opt = (outdir=>'.',prefix=>'qc');
#get options from screen
GetOptions(
    \%opt,"stat:s","fq1_check:s","fq2_check:s","prefix:s","outdir:s"
);
my $super_worker="perl $Bin/../../00.Commbin/super_worker.pl --resource 0.5g --sleept 100 ";

#====================================================================================================================

#$opt{data_list} must be set
(($opt{stat}) && $opt{fq1_check} && $opt{fq2_check}) || die "Name: $0
Description: script to QC statics
Version: 0.1  Date: 2014-07-15
Connector: chenjunru[AT]novogene.cn
Usage: perl statics_qc.pl --stat *.out.stat --fq1_check *.fq1.gz.check --fq2_check *.fq2.gz.check
   *--stat <file>            input *.out.stat file, result from readfq.v8_meta
   *--fq1_check <file>       input fq1.check file
   *--fq2_check <file>       input fq2.check file
    --prefix <str>           set output file prefix
    --outdir                 set output dir, default is .
Note:the output is 'Raw Reads(M bp)\\t Clean Reads(M bp)\\tQ20(%)\\tQ30(%)\\tGC(%)\\tEffective Rate (%)' now\n\n";
#===========================================================================================================================================
###get options
$opt{stat}=abs_path($opt{stat});
(-s $opt{stat}) || die "cann't find file $opt{stat}\n";
$opt{fq1_check}=abs_path($opt{fq1_check});
(-s $opt{fq1_check}) || die "cann't find file $opt{fq1_check}\n";
$opt{fq2_check}=abs_path($opt{fq2_check});
(-s $opt{fq2_check}) || die "cann't find file $opt{fq2_check}\n";
$opt{outdir}=abs_path($opt{outdir});
(-d $opt{outdir}) || mkdir $opt{outdir};

#====================================================================================================================

## 
my(%stat,);
for (`tail -n 1 $opt{stat}`){
    chomp;
    s/^\s+//;
    my @or=split /\s+/;
    $stat{'total_size'}=$or[0];
    $stat{'total_reads'}=$or[1];
    $stat{'low_quality'}=$or[2];
    $stat{'N-num_size'}=$or[3];
    $stat{'is_adapter'}=$or[4];
    $stat{'duplication'}=$or[5];
    $stat{'poly'}=$or[6];
    $stat{'read_length'}=$or[7];
    $stat{'output_size'}=$or[8];
    $stat{'single_size'}=$or[9];
}

my(%check1,%check2);
for (`tail -n 1 $opt{fq1_check}`){
    chomp;
    my @or=split /\s+/;
    $check1{'GC'}=$or[1];
    $check1{'Q20'}=$or[2];
    $check1{'Q30'}=$or[3];
}
for (`tail -n 1 $opt{fq2_check}`){
    chomp;
    my @or=split /\s+/;
    $check2{'GC'}=$or[1];
    $check2{'Q20'}=$or[2];
    $check2{'Q30'}=$or[3];
}
my $raw_reads=&digitize(sprintf("%.2f",$stat{total_reads}/1000000));
my $clean_reads=&digitize(sprintf("%.2f",$stat{output_size}/1000000));
my $gc=($check1{GC}+$check2{GC})/2;
my $q20=($check1{Q20}+$check2{Q20})/2;
my $q30=($check1{Q30}+$check2{Q30})/2;
my $effective_rate=sprintf("%.2f",($stat{output_size}/$stat{total_reads}));
open(OUT,">$opt{outdir}/$opt{prefix}.statics.xlsx");
print OUT "Raw Reads(M bp)\tClean Reads(M bp)\tQ20(%)\tQ30(%)\tGC(%)\tEffective Rate (%)\n";
print OUT "$raw_reads\t$clean_reads\t$q20\t$q30\t$gc\t$effective_rate\n";
close OUT;

sub digitize{
    my $v = shift or return '0';
    $v =~ s/(?<=^\d)(?=(\d\d\d)+$)   #for not contain decimal point
            |
            (?<=^\d\d)(?=(\d\d\d)+$) #for not contain decimal point
            |
            (?<=\d)(?=(\d\d\d)+\.)   #s for integer
            |
            (?<=\.\d\d\d)(?!$)       #s for static after decimal point
            |
            (?<=\G\d\d\d)(?!\.|$)   
            /,/gx;
    return $v;
}
