#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# set default options
my %opt = ("dir_type","AllSample","outdir",".");

#get options from screen
GetOptions(
    \%opt,"list:s","dir_type:s","cleandir:s","outdir:s"
);
    
#====================================================================================================================
$opt{cleandir} ||  
die "Name: $0
Description: Perl to get QC table and clean table.
output: qc_stat.xls  cleandata.xls; input: 1.raw.check 2.raw.check  1.clean.check 2.clean.check readfq.log
Date:  20170329  Connector: lindan[AT]novogene.com
Version: v1.0
Usage1: perl $0  --list qc.list --cleandir 00.run_clean/ -outdir .
        qc.list form:  binname	lib_size 
        e.g.: 
            F10		libname 350     
        [options]
        *--list         [str]	qc list for input
        *--cleandir 	[str]	pathway for 01.Cleandata
        --dir_type      [str]   type of the cleandata directory, 'AllSample' or 'OneSample', default = 'AllSample'. 
        --outdir 	    [str] 	pathway for output. default = ./
\n";
#====================================================================================================================
(-s $opt{list}) || die`Can't open $opt{list}.\n`;
(-d $opt{outdir}) || `mkdir -p $opt{outdir}`;
open CLEAN, ">$opt{outdir}/$opt{dir_type}.clean_data.xls"|| die$!;
print CLEAN "Sample ID\tInsert Size(bp)\tClean Reads Length(bp)\tClean Data(Mb)\tClean Data GC(%)\tClean Data Q20(%)\tClean Data Q30(%)\n";
my %bins;
`rm -f $opt{cleandir}/*/*.Cleandata.stat.xls`; 
for (`less $opt{list}`)  {
	my ($bin, $lib, $libsize ) = split;
    $libsize ||= "err"; 
	my @ins = ("$bin.L$libsize\_$lib\_1.fq.clean.check", "$bin.L$libsize\_$lib\_2.fq.clean.check");
	my ($clean_ck1, $clean_ck2) = map { $_ = "$opt{cleandir}/$bin\_$opt{dir_type}/".$_; } @ins;
    for ($clean_ck1, $clean_ck2) {(-s $_) || die"Not exist: $_\n";}
	my @qc = ($bin, $libsize);
	#cleancheck
	my ($read_pair, $clean_readlen_1) = ($1, $2) if (`head -1 $clean_ck1` =~ /sequence\s+number:\s+(\d+).+read\s+length:\((\d+):\d+\)/);  #read length:(150:150)
	my $clean_readlen_2 = $1 if (`head -1 $clean_ck2` =~ /read\s+length:\((\d+):\d+\)/);  #read length:(150:150)
	$qc[2] = "($clean_readlen_1:$clean_readlen_2)";
    $qc[3] = $read_pair*2*$libsize;
    my $gc_read1 = (split /\s+/, `tail -1 $clean_ck1`)[2]; my $gc_read2 = (split /\s+/, `tail -1 $clean_ck2`)[2];
    $qc[4] = ($gc_read1+$gc_read2)/2;
    my $q20_read1 = (split /\s+/, `tail -1 $clean_ck1`)[3]; my $q20_read2 = (split /\s+/, `tail -1 $clean_ck2`)[3];
    $qc[5] = ($q20_read1+$q20_read2)/2;
    my $q30_read1 = (split /\s+/, `tail -1 $clean_ck1`)[4]; my $q30_read2 = (split /\s+/, `tail -1 $clean_ck2`)[4];
    $qc[6] = ($q30_read1+$q30_read2)/2;

	$qc[3] /= 10**6; $qc[3] = sprintf "%.0f", $qc[3]; while (/^(\d+)(\d\d\d)/){$qc[3] =~ s/^(\d+)(\d\d\d)/$1,$2/;}
	for (@qc[4,5,6]) {$_ = sprintf "%.2f", $_;}
	print CLEAN join "\t", @qc, "\n";
	open OUT,">>$opt{cleandir}/$bin\_$opt{dir_type}/$bin.Cleandata.stat.xls"||die $!;
	print OUT join "\t", @qc, "\n";
	close OUT;
	$bins{$bin} = 1;
}
close CLEAN;
my $head = "Sample ID\tInsert Size(bp)\tClean Reads Length(bp)\tClean Data(Mb)\tClean Data GC(%)\tClean Data Q20(%)\tClean Data Q30(%)\n";
foreach(keys %bins){
	`sed -i '1i\\$head' $opt{cleandir}/$_\_$opt{dir_type}/$_.Cleandata.stat.xls`;
}
#  $head_qc = "0 Sample ID\t1 Library Size(bp)\t2 Reads Length(bp)\t3 Raw Data(Mb)\t4 Raw Read1 Q20(%)\t5 Raw Read2 Q20(%)\t6 Clean Data(Mb)\t7 Clean Read1 Q20(%)\t8 Clean Read2 Q20(%)\t9 Clean_date/Raw_data(%)\t10 Clean Data GC(%)\t11 Duplication Rate(%)\t12 N-Rate";
#  $head_clean = "0 Sample ID\t1 Library Size(bp)\t2 Reads Length(bp)\t3 Raw Data(Mb)\t4 Clean Data(Mb)\t5 Filtered Reads(%)\t6 Clean reads_num\t7 Clean Data GC(%)\t8 Clean Data Q20(%)\t9 Clean Data Q30(%)\n";
