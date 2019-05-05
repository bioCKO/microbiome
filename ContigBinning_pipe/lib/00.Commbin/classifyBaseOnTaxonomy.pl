#! /usr/bin/perl
use strict;
use FindBin qw($Bin);
use warnings;
use Getopt::Long;
use PerlIO::gzip;

# variables
my ($blastFileList, $soapFileList, $taxid, $help, $blastSingle, $soapSingle, $gidTaxid, $time, $name, $node, $result, $append, $row, $count);
my (%hashReadsGid, %hashGidTaxid, %hashGidFlag, %hashTaxid, %hashTaxidClassify);
my (@arrayOfInput);

GetOptions(
    "bl=s" => \$blastFileList,
    "sl=s" => \$soapFileList,
    "bs=s" => \$blastSingle,
    "ss=s" => \$soapSingle,
    "o=s" => \$result,
    "gidTaxid=s" => \$gidTaxid,
    "name=s" => \$name,
    "node=s" => \$node,
    "append=s" => \$append,
    "count=s" => \$count,
    "help" => \$help,
);

$blastFileList ||= "";
$soapFileList ||= "";
$result ||= "";
$blastSingle ||= "";
$soapSingle ||= "";
$append ||= "";
#$gidTaxid ||= "/ifshk1/BC_gag/Group/yusheng/bin/database/20101123/gi_taxid_nucl.dmp.gz";
#$name ||= "/ifshk1/BC_gag/Group/yusheng/bin/database/20101123/names.dmp";
#$node ||= "/ifshk1/BC_gag/Group/yusheng/bin/database/20101123/nodes.dmp";
#$gidTaxid ||= "$Bin/database/gi_taxid_nucl.dmp.gz";
#$name ||= "$Bin/database/names.dmp";
#$node ||= "$Bin/database/nodes.dmp";
$gidTaxid ||= "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp";
$name ||= "$Bin/database/taxonomy_taxid_20141020/names.dmp.short";
$node ||= "$Bin/database/taxonomy_taxid_20141020/nodes.dmp.short";

die `pod2text $0` if ($help || ($blastFileList eq "" && $soapFileList eq "" && $blastSingle eq "" && $soapSingle eq "") || $result eq "");

# read in blastFileList
if ($blastFileList ne ""){
    $time = localtime;
    print STDERR "Begin processing blast result at $time\n";
    open BLAST, "<$blastFileList" || die "$!\n";
    while(<BLAST>){
        chomp;
	next if ($_ =~ /^\s+$/);
        open IN, "<$_" || die "$!\n";
        my $rm = $_;
        while(<IN>){
            chomp;
	    next if ($_ =~ /^\s+$/);
            my @array = split /\s+/, $_;
            if (!$array[1]) {die "$rm has the wrong blast file\n";}
            my @arrayRef = split /\|/, $array[1];
            if (-exists $hashReadsGid{$array[0]}){
                next;
            }
	    $arrayOfInput[$row++] = $_ if ($append ne "");
            unless(-exists $hashReadsGid{$array[0]}{$arrayRef[1]}){
                $hashReadsGid{$array[0]}{$arrayRef[1]}++;
		$hashGidFlag{$arrayRef[1]}++;
            }
        }
        close IN;
    }
    close BLAST;
    $time = localtime;
    print STDERR "Finish processing blast result at $time\n";
}

# read in soapFileList
if ($soapFileList ne ""){
    $time = localtime;
    print STDERR "Begin processing SOAP alignment result at $time\n";
    open SOAP, "<$soapFileList" || die "$!\n";
    while(<SOAP>){
        chomp;
	next if ($_ =~ /^\s+$/);
        open IN, "<$_" || die "$!\n";
        while(<IN>){
            chomp;
            my @array = split /\s+/, $_;
            my @arrayRef = split /\|/, $array[7];
            if(-exists $hashReadsGid{$array[0]}){
                next;
            }
	    $arrayOfInput[$row++] = $_ if ($append ne "");
            unless(-exists $hashReadsGid{$array[0]}{$arrayRef[1]}){
                $hashReadsGid{$array[0]}{$arrayRef[1]}++;
		$hashGidFlag{$arrayRef[1]}++;
            }
        }
        close IN;
    }
    close SOAP;
    $time = localtime;
    print STDERR "Finish processing with SOAP alignment result at $time\n";
}

# read in blastSingle file
if ($blastSingle ne ""){
    $time = localtime;
    print STDERR "Begin processing blast result at $time\n";
    open IN, "<$blastSingle" || die "$!\n";
    while(<IN>){
        chomp;
	next if ($_ =~ /^\s+$/);
        my @array = split /\s+/, $_;
        my @arrayRef = split /\|/, $array[1];
        if (-exists $hashReadsGid{$array[0]}){
            next;
        }
	$arrayOfInput[$row++] = $_ if ($append ne "");
        unless(-exists $hashReadsGid{$array[0]}{$arrayRef[1]}){
            $hashReadsGid{$array[0]}{$arrayRef[1]}++;
	    $hashGidFlag{$arrayRef[1]}=1;
        }
    }
    close IN;
    $time = localtime;
    print STDERR "Finish processing blast result at $time\n";
}

# read in soapSingle file
if ($soapSingle ne ""){
    $time = localtime;
    print STDERR "Begin processing SOAP align result at $time\n";
    open IN, "<$soapSingle" || die "$!\n";
    while(<IN>){
        chomp;
	next if ($_ =~ /^\s+$/);
        my @array = split /\s+/, $_;
        my @arrayRef = split /\|/, $array[7];
        if (-exists $hashReadsGid{$array[0]}){
            next;
        }
	$arrayOfInput[$row++] = $_ if ($append ne "");
        unless(-exists $hashReadsGid{$array[0]}{$arrayRef[1]}){
            $hashReadsGid{$array[0]}{$arrayRef[1]}++;
	    $hashGidFlag{$arrayRef[1]}++;
        }
    }
    close IN;
    $time = localtime;
    print STDERR "Finish processing SOAP align result at $time\n";
}

# read in gi_taxid_nucl.dmp file
$time = localtime;
print STDERR "Begin read in gidTaxid at $time\n";
if($gidTaxid =~ /\.gz$/){
    open GIDTAXID,"<:gzip","$gidTaxid" or die $!;
}
else{
    open GIDTAXID, "<$gidTaxid" || die "$!\n";
}
while(<GIDTAXID>){
    chomp;
    my @array = split /\s+/, $_;
    $hashGidTaxid{$array[0]} = $array[1] if (exists $hashGidFlag{$array[0]});
}
close GIDTAXID;
$time = localtime;
print STDERR "Finish read in gidTaxid at $time\n";

# store taxid in %hashTaxid
for my $read (keys %hashReadsGid){
    for my $gid(keys %{ $hashReadsGid{$read} } ) {
#	{$hashTaxid{$hashGidTaxid{$gid}}++;$count++;} if (exists $hashGidTaxid{$gid});
	if (exists $hashGidTaxid{$gid}){
	    $hashTaxid{$hashGidTaxid{$gid}}++;
	}
    }
}

# this part of script is from xujm's tax_by_taxid.pl

open NAME,"<$name" or die "NAME: $!\n";
open NODE,"<$node" or die "NODE $!\n";
#######store tax info into hash##
my (%pare_id,%rank,%level,%id_to_name,%name_to_id,%access_to_id,%s_len);
%level = ('superkingdom'=>0,
                'phylum'=>1,
                'class'=>2,
                'order'=>3,
                'family'=>4,
                'genus'=>5,
                'species'=>6);

# read in names.dmp file
while(<NAME>){
        chomp;
        my @temp = split /[|]/;
        $temp[0]=~s/^\s+|\s+$//;
        $temp[1]=~s/^\s+|\s+$//;
        $temp[2]=~s/^\s+|\s+$//;
        if($temp[3]=~ /\bscientific\b/){
                $id_to_name{$temp[0]} = $temp[1];
                my @sci_name_cut = split /\s+/,$temp[1];
                my $get_sci_name;
                $get_sci_name = "$sci_name_cut[0] $sci_name_cut[1]" if(exists $sci_name_cut[1]);
                $name_to_id{$get_sci_name} = $temp[0] if($temp[2] eq "" && defined $get_sci_name);
        }
}
close NAME;

# read in nodes.dmp
while (<NODE>){
        chomp;
        my @temp = split /\t\|\t/;
        if(exists $level{$temp[2]}){
                $rank{$temp[0]} = $temp[2];
        }
        $pare_id{$temp[0]}=$temp[1];
}
close NODE;

# this block has been changed
my $line;
for my $key (keys %hashTaxid){
    $line = "";
    my $tax_line = &tran_node($key);
    my (@r_level,@r_tax);
    if($tax_line){
	my @r_tax_line = split /\t\t/,$tax_line;
	for(@r_tax_line){
#               print $_,"\n";
	    my @t_tmp = split /-/,$_;
	    push @r_level,$t_tmp[0];
	    push @r_tax,$t_tmp[1];
	}
    }else{
	@r_level = ("-");
	@r_tax = ("-");
    }
    my $classify = join("|",reverse @r_level). "\t" . join("|", reverse @r_tax);
    $hashTaxidClassify{$key} = $classify;
}

# real classify
my %hashRankReal;
for my $key (keys %hashTaxid){
#    print "$key\t$hashTaxidClassify{$key}\t$hashTaxid{$key}\n";
    my @array = split /\t/, $hashTaxidClassify{$key};
    my @arrayRank = split /\|/, $array[0];
    my @arrayReal = split /\|/, $array[1];
    for (my $i = 0; $i <= $#arrayRank; $i++){
        $hashRankReal{$arrayRank[$i]}{$arrayReal[$i]} += $hashTaxid{$key};
    }
}

# print result, add other level classify in the future version
open OUT, ">$result" || die "$!\n";
for my $rank (keys %hashRankReal){
    if ($rank ne "species"){
	next;
    }
    for my $real (keys %{ $hashRankReal{$rank} }){
        print OUT "$real\t$hashRankReal{$rank}{$real}\n";
    }
    print OUT "\n";
}
close OUT;

# append classify to result
if ($append ne ""){
    open APP, ">$append" || die "$!";
    my $gi;
    for (my $i = 0; $i < $row; $i++){
	if ($arrayOfInput[$i] =~ /gi\|(\d+)\|/){
	    $gi = $1;
	}else{
	    print STDERR "Can't extract gi at $arrayOfInput[$i]\n";
	    next;
	}
	next unless(exists $hashGidTaxid{$gi} && exists $hashTaxidClassify{$hashGidTaxid{$gi}});
	my @array = split /\t/, $hashTaxidClassify{$hashGidTaxid{$gi}}; 
	my @arrayRank = split /\|/, $array[0];
	my @arrayReal = split /\|/, $array[1];
	for (my $j = 0; $j <= $#arrayRank; $j++){
	    if ($arrayRank[$j] =~ /species/){
		print APP $arrayOfInput[$i], "\t", $arrayReal[$j], "\n";
	    }
	}
    }
    close APP;
}

# here, I only process single blast result, I will add more scripts to process more results
if ($append ne "" && $count ne ""){
    my %hashSpecies; # store species name in %hashSpecies
    my %hashSpecies2;# this only for the convenient output
    open APPEND, "<$append" || die "$!";
    while(<APPEND>){
	chomp;
	my @array = split /\t/, $_;
	$hashSpecies{$array[0]}{$array[1]} = $array[-1];
	$hashSpecies2{$array[0]} = $array[-1];
    }
    close APPEND;

    my %hashOfArrayStartEnd; # store start and end of query in %hashOfArrayStartEnd
    if ($blastSingle ne ""){
	open BLAST, "<$blastSingle" || die "$!";
	while(<BLAST>){
	    chomp;
	    my  @array = split /\t/, $_;
	    if (exists $hashSpecies{$array[0]}{$array[1]}){
		push @{$hashOfArrayStartEnd{$array[0]}}, [ @array[6..7] ];
	    }
	}
	close BLAST;
    }else{
	die "Input blast result\n";
    }

    open COUNT, ">$count" || die "$!";
    for my $key (keys %hashOfArrayStartEnd){
	my @array = sort{$a->[0] <=> $b->[0]} @{$hashOfArrayStartEnd{$key}}; # sort by the start of the query
	my $length = $array[0]->[1] - $array[0]->[0] + 1;
	my ($start, $end) = ($array[0]->[0], $array[0]->[1]);
	for (my $i = 1; $i <= $#array; $i++){
	    if ($array[$i]->[0] > $end){
		$length += ($array[$i]->[1] - $array[$i]->[0] + 1);
		$start = $array[$i]->[0];
		$end = $array[$i]->[1];
	    }else{
		if ($array[$i]->[1] > $end){
		    $length += ($array[$i]->[1] - $end); # no need to plus 1, as the end has been counted;
		    $end = $array[$i]->[1];
		} # else no need to do anything
	    }
	}
	print COUNT "$hashSpecies2{$key}\t$length\n";
    }
    close COUNT;
} 

if ($append ne "" && $count ne ""){
    my %hashSpecies; # store species name in %hashSpecies
    my %hashSpecies2;# this only for the convenient output
    open APPEND, "<$append" || die "$!";
    while(<APPEND>){
	chomp;
	my @array = split /\t/, $_;
	$hashSpecies{$array[0]}{$array[1]} = $array[-1];
	$hashSpecies2{$array[0]} = $array[-1];
    }
    close APPEND;

    my %hashOfArrayStartEnd; # store start and end of query in %hashOfArrayStartEnd
    if ($blastSingle ne ""){
	open BLAST, "<$blastSingle" || die "$!";
	while(<BLAST>){
	    chomp;
	    my  @array = split /\t/, $_;
	    if (exists $hashSpecies{$array[0]}{$array[1]}){
		push @{$hashOfArrayStartEnd{$array[0]}}, [ @array[6..7] ];
	    }
	}
	close BLAST;
    }else{
	die "Input blast result\n";
    }

    open COUNT, ">$count" || die "$!";
    for my $key (keys %hashOfArrayStartEnd){
	my @array = sort{$a->[0] <=> $b->[0]} @{$hashOfArrayStartEnd{$key}}; # sort by the start of the query
	my $length = $array[0]->[1] - $array[0]->[0] + 1;
	my ($start, $end) = ($array[0]->[0], $array[0]->[1]);
	for (my $i = 1; $i <= $#array; $i++){
	    if ($array[$i]->[0] > $end){
		$length += ($array[$i]->[1] - $array[$i]->[0] + 1);
		$start = $array[$i]->[0];
		$end = $array[$i]->[1];
	    }else{
		if ($array[$i]->[1] > $end){
		    $length += ($array[$i]->[1] - $end); # no need to plus 1, as the end has been counted;
		    $end = $array[$i]->[1];
		} # else no need to do anything
	    }
	}
	print COUNT "$hashSpecies2{$key}\t$length\n";
    }
    close COUNT;
}

# subroutine
sub tran_node{
        my $node = shift;
        if(exists $rank{$node}){
                $line.= "$rank{$node}-$id_to_name{$node}\t";
        }
        unless(exists $pare_id{$node}){
                return $line;
        }
        my $par_node = $pare_id{$node};
        if($par_node ne 1){
                &tran_node($par_node);
        }else{
                return $line;
        }
}

=head1 NAME

    classify.pl - classify the sequence by blast[m8 format] or SOAP align result

=head1 USAGE

    perl classify.pl [OPTIONS]
    
    -bl [string]       blast result file list
    -sl [string]       soap result file list
    -bs [string]       single blast result
    -ss [string]       single soap result
    -gidTaxid [string] gi_taxid_nucl.dmp from NCBI taxonomy[default 20141020 version]
    -name [string]     names.dmp from NCBI taxonomy [default 20141020 version]
    -node [string]     nodes.dmp from NCBI taxonomy [default 20141020 version]
    -append [string]   append the classify result to the blast or SOAP align result [default NULL]
    -count [string]    calculate the length of alignment of each classify, [-append parameter MUST]
    -o  [string]       classify result
    -h                 show this help

=head1 DESCRIPTION

    This script is to classify the sequences by gid from blast or SOAP align result.
    The classification is based on taxonomy of NCBI. 

=head1 VERSION

  Author: Wu Rensheng <wurensheng@genomics.org.cn> 
  Version: 1.04, Date: 2010-09-01, LMDF: 2011-02-14

=cut
