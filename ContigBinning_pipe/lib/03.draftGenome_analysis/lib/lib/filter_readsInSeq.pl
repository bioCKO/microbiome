#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use PerlIO::gzip;
use Getopt::Long;
my %opt = (s=>'-l 32 -m 460 -x 540 -s 40 -v 3 -r 1',b=>"soap_result");
GetOptions(\%opt,"1:s","2:s","3:s","4:s","o:i","d:s","s:s","m:i","x:i","b:s","f:f","l:i","p:s","c","h","5:s","6:s");
(@ARGV>2 || (@ARGV>1 && $opt{d})) ||
die "Name: filter_fosmid.pl
Version: 1.0,  Date: 2012-06-06
Author: Wenbin Liu, liuwenbin\@genomics.org.cn
Usage: 
    1. perl filter_fosmid.pl <fq1> <fq2> -d <del.fa> [-options]
    2. perl filter_fosmid.pl <fq1> <fq2> -d <del.fa> -p <hom.fa> [-options]
    3. perl filter_fosmid.pl <fq1> <fq2> <soap1_result> [soap2_result...]
	-d <file>       sequence file to delete reads contained
	-p <file>       sequence file to pick up homologous reads in reads set which deleted by -d option.
	-s <str>        soap options for del.fa and fq1,2, default='-l 32 -m 460 -x 540 -s 40 -v 3 -r 1'
	-b <dir>        soap result directory, default=soap_result
	-c              soap result is to select fq, not to del fq data
	-f <num>        select rawdata(Mbp) to run soap, default use all data
	-h              only deal PE with both reads1 and reads2 map del.fa
	-m <num>        to re-set soap -m, default not set
	-x <num>        to re-set soap -x, default not set
	-1 <str>        output fq1, defualt=<fq1>.out.gz
	-2 <str>        output fq2, default=<fq2>.out.gz
	-3 <str>        output fq1 saved by -p, defualt=<fq1>.hom.gz
	-4 <str>        output fq2 saved by -p, default=<fq2>.hom.gz
	-5 <str>        set file name to output unselect reads1 fq data
	-6 <str>        set file name to output unselect reads2 fq data
	-o <num>        output data limit(Mbp), defautl output all data
	-l <num>        reads1+reads2 length, default caculate from fq file\n
Note:
    1 the process will not qsub, you should qsub by your self.
    2 del.fa and soap_result can set together, than filter both input soap and del.fa soap result.\n";
#===========================================================================================
# need soap and bwt pathway at Bin
my ($bwt,$soap) = ("$Bin/2bwt-builder","$Bin/soap2.21");
foreach($bwt,$soap){(-s $_) || die"error: can't find script $_, $!";}
foreach(@ARGV){(-f $_) || die"error: input $_ isn't an able file, $!";}
my $fq1 = shift;
my $fq2 = shift;
$opt{1} ||= "$fq1.out.gz";
$opt{2} ||= "$fq2.out.gz";
$opt{3} ||= "$fq1.hom.gz";
$opt{4} ||= "$fq2.hom.gz";
$opt{m} ||= 200;
foreach($opt{1},$opt{2},$opt{3},$opt{4}){ m/\.gz$/ || ($_ .= ".gz");}
abs_path($opt{b},$fq1,$fq2,$opt{d},$opt{p});
select_raw($opt{d},$opt{f},\$fq1,\$fq2,$opt{1},$opt{2},$opt{l});#sub3
del_soap($fq1,$fq2,$opt{d},\@ARGV,$opt{b},$opt{s},$opt{m},$opt{x},$bwt,$soap);#sub1
my %filter_id;
foreach(@ARGV){
    get_soap(\%filter_id,$_);#sub2
}
if($opt{h}){ foreach (values %filter_id){$_ = ($_ > 1) ? 1 : 0;}}
else { foreach (values %filter_id){$_ = 1;}}

my ($del_1, $del_2)=("$opt{1}.del.gz","$opt{2}.del.gz");
%filter_id ? filter_soap(\%filter_id,$fq1,$fq2,$opt{1},$opt{2},$opt{l},$opt{o},$opt{c} ? 1:0,$opt{p},$del_1,$del_2,$opt{5},$opt{6}) :#sub4
system"cp $fq1 $opt{1}; cp $fq2 $opt{2}";

if (-s $del_1 && -s $del_2) {
	print "$del_1,$del_2\n\n";
	my $arg;
	foreach ('m','x','l') {$opt{$_} && ($arg .= " -$_ $opt{$_}");}
	$opt{s} && ($arg .= " -s=\"$opt{s}\"");
	system ("perl $0 $del_1 $del_2 $arg -d $opt{p} -b $opt{b}2 -c -1 $opt{3} -2 $opt{4} > log 2> err");
	system ("cat $opt{3} >> $opt{1}");
	system ("cat $opt{4} >> $opt{2}");
	system ("rm -f $del_1 $del_2");
}

#===========================================================================================
# SUB
#sub1
sub del_soap{
    my ($fq1,$fq2,$index,$argv,$dir,$s,$m,$x,$bwt,$soap) = @_;
    $index || return(0);
    (-d $dir) || `mkdir -p $dir`;
    if($index =~ /\.index$/ && -s "$index.sai"){
    }elsif(-s "$index.index.sai"){
        $index .= ".index";
    }elsif(-s $index){
        my $indir = "$dir/index";
        my $bname = (split/\//,$index)[-1];
        (-d $indir) || mkdir"$indir";
        (-s "$indir/$bname") || system"ln -s $index $indir";
        if(-s "$indir/$bname.index.sai"){
            $index = "$indir/$bname.index";
        }else{
            system"cd $indir; $bwt $bname 2> bwt.log";
            $index = "$indir/$bname.index";
        }
    }else{
        die"error: can't find -d set file: $index, $!";
    }
    if($m){$s =~ s/-m\s+\d+//;$s .= " -m $m";}
    if($x){$s =~ s/-x\s+\d+//;$s .= " -x $x";}
    my $b1 = (split/\//,$fq1)[-1];
    my $b2 = (split/\//,$fq2)[-1];
    system"cd $dir; $soap -D $index -a $fq1 -b $fq2 $s -o $b1.PE.soap -2 $b2.SE.soap 2> soap.log";
    push @{$argv},("$dir/$b1.PE.soap","$dir/$b2.SE.soap");
}
#sub2
sub get_soap{
    my ($id_h,$soap) = @_;
    ($soap && -s $soap) || return(0);
    ($soap =~ /\.gz$/) ? (open IN,"<:gzip",$soap || die$!) : (open IN,$soap || die $!);
    while (<IN>){
    	chomp;
	    my $id = (split /\t/)[0];
	    $id =~ s/\/\d$//;
	    $id_h->{$id} ++;
    }
    close IN;
}
#sub3
sub select_raw{
    my ($delseq,$fsel,$fq1,$fq2,$o1,$o2,$len) = @_;
    ($fsel && $delseq && -s $delseq) || return(0);
    foreach($o1,$o2){
       s/\.out\.gz$|\.gz$//;
       $_ .= ".fsel.gz";
    }
    $fsel *= 10**6;
    my $get = 0;
    $$fq1 =~ /gz$/ ? open IN1,"<:gzip", $$fq1  || die $! : open IN1,$$fq1 || die $!;
    $$fq2 =~ /gz$/ ? open IN2,"<:gzip", $$fq2  || die $! : open IN2,$$fq2 || die $!;
    open OUT1,">:gzip", $o1 || die $!;
    open OUT2,">:gzip", $o2 || die $!;
    while (my $info1 = <IN1>, my $info2 = <IN2>){
		$info1 .= <IN1> . <IN1> . <IN1>;
		$info2 .= <IN2> . <IN2> . <IN2>;
        if(!$len){$len = length((split /\n/,$info1)[1]) + length((split /\n/,$info2)[1]);}
        print OUT1 $info1;
        print OUT2 $info2;
        $get += $len;
        ($get >= $fsel) && last;
    }
    close IN1;
    close IN2;
    close OUT1;
    close OUT2;
    ($$fq1, $$fq2) = ($o1, $o2);
}
#sub4
sub filter_soap{
    my ($id_h,$fq1,$fq2,$o1,$o2,$len,$lim,$sel,$del,$del_1,$del_2,$fq5,$fq6) = @_;
	if ($del) {
		open DEL1,">:gzip", $del_1 || die $!;
		open DEL2,">:gzip", $del_2 || die $!;
	}
    $lim &&= $lim * 10**6;
    my $get = 0;
    $fq1 =~ /gz$/ ? open IN1,"<:gzip", $fq1  || die $! : open IN1,$fq1 || die $!;
    $fq2 =~ /gz$/ ? open IN2,"<:gzip", $fq2  || die $! : open IN2,$fq2 || die $!;
	if($fq5 && $fq6){
    	$fq5 =~ /gz$/ ? open IN5,">:gzip", $fq5  || die $! : open IN5,$fq5 || die $!;
    	$fq6 =~ /gz$/ ? open IN6,">:gzip", $fq6  || die $! : open IN6,$fq6 || die $!;
	}
    open OUT1,">:gzip", $o1 || die $!;
    open OUT2,">:gzip", $o2 || die $!;
    while (my $info1 = <IN1>,my $info2 = <IN2>){
        my $index_r1 = (split /\s/,$info1)[0];
        $index_r1 =~ s/\/\d$//;
		$index_r1 =~ s/^\@//;
		$info1 .= <IN1> . <IN1> . <IN1>;
		$info2 .= <IN2> . <IN2> . <IN2>;
		#($sel ^ $id_h->{$index_r1}) && next;
		$id_h->{$index_r1} = 0 if (! exists $id_h->{$index_r1});
        if ($sel ^ $id_h->{$index_r1}) {
			if ($del) {
				print DEL1 $info1;
				print DEL2 $info2;
			}elsif($fq5 && $fq6){
				print IN5 $info1;
				print IN6 $info2;
			}
		} else {
			print OUT1 $info1;
			print OUT2 $info2;
			if($lim){
				if(!$len){$len = length((split /\n/,$info1)[1]) + length((split /\n/,$info2)[1]);}
				$get += $len;
				($get >= $lim) && last;
			}
		}
		eof IN1 && last;
    }
    close IN1;
    close IN2;
    close OUT1;
    close OUT2;
	if ($fq5 && $fq6) { close IN5; close IN6; }
	if ($del) {close DEL1; close DEL2;}
}
sub abs_path{
    chomp(my $pwd = `pwd`);
    foreach(@_){
        (!$_ || /^\//) && next;
         $_ = "$pwd/$_";
    }
}
