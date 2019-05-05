#!/usr/bin/perl -w
use strict;
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;

use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../../";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($fqcheck,) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(Fqcheck)],$Bin,$lib);

my $distribute_fqcheck = "$Bin/distribute_fqcheck.pl";

my ( $fqslist, $statlist, $indir, $nohostlist, $nohostdir, $shdir, $outdir, $perfix, $fq_pattern, $fsp, $nohostp, $runsh, $drawpic, $help );
GetOptions(
	"h!"        => \$help,
	"fql=s"     => \$fqslist,
	"stl=s"     => \$statlist,
	"nohl=s"    => \$nohostlist,
	"indir=s"   => \$indir,
	"shdir=s"   => \$shdir,
	"nohdir=s"  => \$nohostdir,
	"outdir=s"  => \$outdir,
	"perfix=s"  => \$perfix,
	"fqp=s"     => \$fq_pattern,
	"fsp=s"     => \$fsp,
	"nohp=s"    => \$nohostp,
	"runsh=s"   => \$runsh,
	"drawpic=s" => \$drawpic
);

die &usage if $help;
die &usage if ( !$fqslist && !$indir );

my ( @fqslist, @fstats, @nohost, %path_fqs, %sample_stats );
$fq_pattern ||= "fq[12].gz";
$fsp        ||= "out.stat";
$nohostp    ||= "nohost.fq[12].gz";
$runsh      ||= "Y";
$indir      ||= abs_path("./");
$outdir     ||= $indir;
$outdir     ||= abs_path($outdir);
$perfix     ||= basename($indir);
$drawpic    ||= "";

chomp( @fqslist = `find $indir -name "*$fq_pattern"` )  if ( $fq_pattern && $indir );
chomp( @fstats  = `find $indir -name "*$fsp"` )         if ( $fsp        && $indir );
chomp( @nohost  = `find $nohostdir -name "*$nohostp"` ) if ( $nohostp    && $nohostdir );
&getlist( $fqslist,    \@fqslist ) if $fqslist;
&getlist( $statlist,   \@fstats )  if $statlist;
&getlist( $nohostlist, \@nohost )  if $nohostlist;

foreach my $element (@fqslist) {
	chomp $element;
	$path_fqs{ dirname($element) } .= basename($element) . "\t";
}

#print( join( "\n", @fqslist ) );
die "There is no elements in your -indir or -fqslist, please confirm it. \n" if ( length( keys %path_fqs ) == 0 );

my ( %sample_check, %cleanQC, %RawQC, %nohostQC );

foreach my $key ( keys %path_fqs ) {

	#print $key."\t".$path_fqs{$key}."\n";
	my @tmp = split( "\t", $path_fqs{$key} );    #./SystemClean/DNA144/    DNA144_500.fq1.gz       DNA144_500.fq2.gz
	foreach my $element (@tmp) {
		my $tmp = $element;

		#$element =~ s/\.gz$//;
		$tmp =~ s/$fq_pattern//;
		my $checkname = "$key/$element";
		$checkname =~ s/gz$/check/;
		`$fqcheck -r $key/$element -c $checkname ` if !-s $checkname;
		$sample_check{$tmp} .= "$checkname\t";
	}
}
&getstat( \%cleanQC, \%sample_check, $indir );
&filteroutstats( \@fstats, \%RawQC );
&nohostcheckstst( \@nohost, \%nohostQC ) if ( scalar(@nohost) > 0 );
`mkdir -p $outdir` if ( !-d $outdir );
if ( scalar( keys %nohostQC ) == 0 ) {
	open STAT, ">$outdir/$perfix.QCstat.info.xls" or die " Can not open $outdir/$perfix.QCstat.info.xls";
	print STAT "#Sample\tInsertSize(bp)\tSeqStrategy\tRawData\tRawReads(#)\tLow_Q\tN_num\tAdapter\tDuplication\tPoly\tCleanData\tClean_Q20\tClean_Q30\tClean_GC(%)\tEffective(%)\n";
}
else {
	open STAT, ">$outdir/$perfix.NonHostQCstat.info.xls" or die " Can not open $outdir/$perfix.NonHoststat.info.xls";
	print STAT
"#Sample\tInsertSize(bp)\tSeqStrategy\tRawData\tRawReads(#)\tLow_Q\tN_num\tAdapter\tDuplication\tPoly\tCleanData\tClean_Q20\tClean_Q30\tClean_GC(%)\tEffective(%)\tNonHostData\n";
}
if ( scalar( keys %RawQC ) == scalar( keys %cleanQC ) ) {

	foreach my $key ( keys %RawQC ) {
		my @raw = split( /\s+/, $RawQC{$key} );  #0 total_size,1 total_reads,2 low_quality,3 N-num_size,4 is_adapter,5 duplication,6 poly,7 read_length, 8 output_size,9 single_size
		my @clean = split( /\s+/, $cleanQC{$key} );    #Sample\tInsertSize(bp)\tDataSize(M bp)\tQ20\tQ30\tGC(\%);
		my $temp = join( "\t",
			$clean[0],
			$clean[1],
			$raw[7],
			&digitize( sprintf( "%.2f", $raw[0] / 1000000 ) ),
			&digitize( $raw[1] ),
			&digitize( sprintf( "%.2f", $raw[2] / 1000000 ) ),
			&digitize( sprintf( "%.2f", $raw[3] / 1000000 ) ),
			&digitize( sprintf( "%.2f", $raw[4] / 1000000 ) ),
			&digitize( sprintf( "%.2f", $raw[5] / 1000000 ) ),
			&digitize( sprintf( "%.2f", $raw[6] / 1000000 ) ),
			$clean[2],
			$clean[3],
			$clean[4],
			$clean[5],
            sprintf( "%.3f", ( $raw[8] * 100 / $raw[0] ) ) );
		!exists $nohostQC{$key} ? print STAT $temp . "\n" : print STAT $temp . "\t" . &digitize( $nohostQC{$key} ) . "\n";
	}
}
close STAT;

&drawpic( \%sample_check ) if $drawpic;

sub usage() {
	print "Name: MetaGenomics.fqcheck.v3.pl
	Description: script to parse   
	Version: 0.3  Date: 2014-08-16
	Connector: wangxioahong[AT]novogene.cn
	Usage1: perl $0  -indir  -outdir
	-fql	input fastqs file list 
	-stl	input astq filter(readfq) stat output file list
	-nohl	input nonhost filter list 
	-indir	given a specific path for find the fastqs
	-outdir	output directory, defult [./]
	-nohdir	given a specific path for find the nonhost fastqs
	-perfix output file perfix mark,defult [basename(indir)]
	-shdir	shell script otuput directory,the default is the same as the -outdir
	-fqp	the fastaq files regular expression，defult [fq[12].gz]
	-fsp	the fastq filter(readfq) stat output file regular expression，defult [out.stat]
	-nohp	the nonhost fastaq files regular expression，defult [nohost.fq[12].gz]
	-runsh	qsub blast task,Y/N,defult [Y],qsub your jobs
for exsample: 
	perl $0 -indir /PROJ/GR/MICRO/metagenomics/NHT130001/TestClean/01.Cleandata -shdir ./ \n";
	exit;
}

sub getlist() {
	my ( $listfile, $fqlist ) = @_;
	open LIST, $listfile or die "Can not opoen file $listfile $! .";
	while (<LIST>) {
		chomp;
		push( @{$fqlist}, $_ );
	}
	close LIST;
}

sub getstat() {
	my ( $cleanQC, $sample_check, $indir ) = @_;
	foreach my $key ( keys %$sample_check ) {
		if ( $sample_check->{$key} && $sample_check->{$key} ne "" ) {
			my $tempstr = $key;
			$tempstr =~ s/\.$//;
			my @temparray = split( /_/, $tempstr );
			my ( $samplename, $insertsize );
			$insertsize = pop @temparray;
			$samplename = join( "_", @temparray );
			my @temp  = split( "\t", $sample_check->{$key} );
			my $head0 = `head -n 1 $temp[0]`;
			my $tail0 = `tail -n 1 $temp[0]`;
			my $head1 = `head -n 1 $temp[1]`;
			my $tail1 = `tail -n 1 $temp[1]`;

			my @head0 = split( /,\s+/, $head0 );
			my @tail0 = split( /\s+/,  $tail0 );
			my @head1 = split( /,\s+/, $head1 );
			my @tail1 = split( /\s+/,  $tail1 );

			$head0[2] =~ s/\s+total\s+length//;
			$head1[2] =~ s/\s+total\s+length//;
			my $totalLen = sprintf( "%.2f", ( $head0[2] + $head1[2] ) / 1000000 );
			$totalLen = &digitize($totalLen);
			my $q20 = sprintf( "%.2f", ( $tail0[2] + $tail1[2] ) / 2 );
			my $q30 = sprintf( "%.2f", ( $tail0[3] + $tail1[3] ) / 2 );
			my $gc  = sprintf( "%.2f", ( $tail0[1] + $tail1[1] ) / 2 );
			$cleanQC->{$tempstr} = "$samplename\t$insertsize\t$totalLen\t$q20\t$q30\t$gc";    ## %cleanQC key: $samplename_$insertsize
			                                                                                  #print STAT "$samplename\t$insertsize\t$totalLen\t$q20\t$q30\t$gc\n";
		}
	}
}

sub drawpic() {
	my ($sample_check) = @_;
	foreach my $key ( keys %{$sample_check} ) {
		my $tempstr = $key;
		$tempstr =~ s/\.$//;
		my @temp = sort { $a cmp $b } split( /\t/, $sample_check->{$key} );
		my $path = dirname( $temp[0] );
		system "perl $distribute_fqcheck $temp[0] $temp[1] -o $path/$tempstr &";
	}
}

sub filteroutstats() {
	my ( $statlist, $RawQC ) = @_;
	foreach my $element (@$statlist) {
		next if $element eq "";
		chomp $element;
		my $tempstr = basename($element);
		$tempstr =~ s/$fsp//ig;
		$tempstr =~ s/\.$//;
		open TEMP, "<$element" or die " Can not open file $element $! .";
		<TEMP>;
		<TEMP>;
		<TEMP>;
		my $tempstr1 = <TEMP>;
		$tempstr1 =~ s/^\s+//;
		$tempstr1 =~ s/\s+$//;
		my @temp = split( /\s+/, $tempstr1 );    #total_size,total_reads,low_quality,N-num_size,is_adapter,duplication,poly,read_length,output_size,single_size
		$RawQC->{$tempstr} = join( "\t", @temp );
	}
}

sub nohostcheckstst() {
	my ( $nohostchecklist, $nohastQC ) = @_;
	foreach my $element (@$nohostchecklist) {
		next if $element eq "";
		chomp $element;
		my $tempstr = basename($element);
        $tempstr =~ s/\.$nohostp//ig;
        $tempstr =~ s/(\.nohost)+$//; #add 2014-12-18,for multiple host stat

		#$element=~s/gz$/check/ if $element=~/\.gz$/;
		my $checkname = $element;
		$checkname =~ s/gz$/check/ if $checkname =~ /\.gz$/;
		`$fqcheck -r $element -c $checkname` if !-s $checkname;
		#print $tempstr."\t".$element."\n";
		my $head0 = `head -n 1 $checkname`;
		my @head0 = split( /,\s+/, $head0 );
		$head0[2] =~ s/\s+total\s+length//;
		my $totalLen = sprintf( "%.2f", $head0[2] / 1000000 );
		$nohastQC->{$tempstr} += $totalLen;
	}
}

sub digitize() {
	my $v = shift or return '0';
	$v =~ s/(?<=^\d)(?=(\d\d\d)+$)    #处理不含小数点的情况
            |
            (?<=^\d\d)(?=(\d\d\d)+$)  #处理不含小数点的情况
            |
            (?<=\d)(?=(\d\d\d)+\.)    #处理整数部分
            |
            (?<=\.\d\d\d)(?!$)        #处理小数点后面第一次千分位
            |
            (?<=\G\d\d\d)(?!\.|$)     #处理小数点后第一个千分位以后的内容，或者不含小数点的情况
            /,/gx;
	return $v;
}
