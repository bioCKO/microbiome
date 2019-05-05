#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
# set default options
my %opt = (outdir=>'./',outfile=>'assembly.stat.xls');

#get options from screen
GetOptions(
    \%opt,"outdir:s","outfile:s","data_list:s","mf:s",
);

#===========================================================================================================================================
($opt{data_list} && -s $opt{data_list})  || die "Name: $0
Description: Script to get xls for scaf
Version: 0.1  Date: 2014-11-18 
Connector: chenjunru[AT]novogene.cn
Usage1: perl $0 --data_list scaf.ss.list [-options]
   *--data_list <file>   input files of different kmers, must be *.scafSeq
    --mf <file>          input file for sort sample order
    --outdir <dir>       output directory, default is ./
    --outfile <file>     output file, deault is assembly.stat.xls\n\n";
#===========================================================================================================================================
if($opt{mf}){ $opt{mf}=abs_path($opt{mf});}
$opt{outdir}=abs_path($opt{outdir});
(-s $opt{outdir}) ||`mkdir -p $opt{outdir}`;
#===========================================================================================================================================
# main script
my %sample2xls;
open(STAT,">$opt{outdir}/$opt{outfile}");
print STAT "SampleID\tTotal len.(bp)\tNum.\tAverage len.(bp)\tN50 Len.(bp)\tN90 Len.(bp)\tMax len.(bp)\n";
		for  my $file (`less -S $opt{data_list}\n`){
			my $sample=$1 if($file=~/.*\/(.*)\.scaf(Seq|tigs)\.\d+\.ss\.txt$/);
			open(OR,"$file");
			my($Average,$N50,$N90,$max,$total_number,$total_length);
			while(<OR>){
				chomp;
			    my $tmp_line=$_;
				$tmp_line=~s/^\s+//;
			    $tmp_line=~s/\s+$//;
				$Average=&digitize($2) if($tmp_line=~/^Average length \(bp\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
				$N50=&digitize($2) if($tmp_line=~/^N50 Length \(bp\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
				$N90=&digitize($2) if($tmp_line=~/^N90 Length \(bp\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
				$max=&digitize($2) if($tmp_line=~/^Maximum length \(bp\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
				$total_number=&digitize($2) if($tmp_line=~/^Total number \(>\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
				$total_length=&digitize($2) if($tmp_line=~/^Total length of \(bp\):(\s+[\d\.]+){3}\s+([\d\.]+)/);
			}
			close OR;
			$sample2xls{$sample}="$sample\t$total_length\t$total_number\t$Average\t$N50\t$N90\t$max\n";
			print STAT "$sample\t$total_length\t$total_number\t$Average\t$N50\t$N90\t$max\n" if(!$opt{mf})
		}
if ($opt{mf}) {
	open(OR,"$opt{mf}");
	while (my $or=<OR>) {
		chomp $or;
		my @or=split/\s+/,$or;
		print STAT "$sample2xls{$or[0]}" if($sample2xls{$or[0]});
	}
}
close STAT;
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
