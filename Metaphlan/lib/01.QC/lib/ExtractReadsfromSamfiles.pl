#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use PerlIO::gzip;
use File::Basename;


#GetOptions( "read1:s", "read2:s", "samfile:s", "outdir:s" );


######################################################################################################
if ( @ARGV < 4 ) {
	print "Name: ExtractReadsfromSamfiles.pl
Description: Separate reads data from sam format file.
Version: 0.2  Date: 2014-7-16
Contacts: wangxiaohong\@novogene.cn
Usage:  $0 <reads1.fq> <reads2.fq> <soap.[PE/SE].file1 soap.[PE/SE].file2 soap.[PE/SE].file3...> <outdir>
Note:
	1£ºHowever mean your life is, meet it and live it do not shun it and call it hard names.\n";
	exit;
}
######################################################################################################
my ( $reads1, $reads2, $samfile, $outdir);
my $samtools="share/MetaGenome_pipeline/MetaGenome_pipeline_V5.1/software/samtools/samtools-1.3/samtools";
$reads1=shift;
$reads2=shift;
$outdir=pop;

my $outnameprefix=basename($reads1);
$outnameprefix=~s/\.fq[12].gz$//;
my %readIDinsam;

for my $samfile(@ARGV){
	&readsam($samfile,\%readIDinsam);
}
$outdir =~ s/^\s+//;
$outdir =~ s/\s+$//;
-d $outdir || mkdir  $outdir;
$outdir=abs_path($outdir);
open NOSAMFQ1,">:gzip","$outdir/$outnameprefix.nohost.fq1.gz" || die $!;
open NOSAMFQ2,">:gzip","$outdir/$outnameprefix.nohost.fq2.gz"|| die $!;
open SAMFQ1,">:gzip","$outdir/$outnameprefix.host.fq1.gz"|| die $!;
open SAMFQ2,">:gzip","$outdir/$outnameprefix.host.fq2.gz"|| die $!;
#print ">$outdir/$outnameprefix.nonsam.fq1"."\n";

$reads1 =~ /gz$/ ? open FQ1, "<:gzip", $reads1 || die $! : open FQ1,  $reads1 || die $! ;
$reads2 =~ /gz$/ ? open FQ2, "<:gzip", $reads2 || die $! : open FQ2,  $reads2 || die $! ;
while(my $head1 = <FQ1>){
    my $seq1 = <FQ1>;my $stand1 = <FQ1>; my $que1 = <FQ1>;
    my $head2 = <FQ2>;my $seq2 = <FQ2>; my $stand2 = <FQ2>; my $que2 = <FQ2>;
    #$head1 =~ s/^\s+//;
	#$head1 =~ s/\s+$//;
	my $temp=(split/\s+/,$head1)[0];
	
	$temp =~ s/^\@//;
	#print $temp."\n";
	if(exists $readIDinsam{$temp}){
		print SAMFQ1  $head1,$seq1,$stand1,$que1;
		print SAMFQ2 $head2,$seq2,$stand2,$que2;
	}
	else{
		print NOSAMFQ1 $head1,$seq1,$stand1,$que1;
		print NOSAMFQ2 $head2,$seq2,$stand2,$que2;
	}
	#last;
}
close FQ1;close FQ2;
close NOSAMFQ1;close NOSAMFQ2;
close SAMFQ1;close SAMFQ2;

sub readsam(){
	my ( $samfile,$readIDinsam) = @_;
    (-B "$samfile") ? open SAM, "$samtools view $samfile | " || die $! :
	$samfile =~ /gz$/ ? open SAM, "<:gzip", $samfile || die $! : open SAM,  $samfile || die $!;
	#my %readIDinsam;
	while(<SAM>){
		next if /^\@/;
		chomp;
		my @temp=split(/\s+/,);
		if($temp[2] && $temp[2] eq "*"){
			next;
		}
		$readIDinsam->{$temp[0]}=1;
		#print $temp[0]."\n";
		#last;
	}
	close SAM;
}
