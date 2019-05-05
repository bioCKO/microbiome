#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;

# set default options
my %opt = (outdir=>'./',prefix=>'total');

#get options from screen
GetOptions(
    \%opt,"data_list:s","outdir:s","prefix:s","fa:s","mf:s",
);
## get software's path
use lib "$Bin/../../../00.Commbin/";
my $lib = "$Bin/../../..";
use PATHWAY;
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin, $!\n";
my ($tree_cluster,$get_len) = get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(TREE GET_LEN)],$Bin,$lib);

my $sample_draw="perl $Bin/sample_draw.pl ";

#====================================================================================================================
($opt{data_list} && -s $opt{data_list} && $opt{fa} && -s $opt{fa})|| 
die "Name: $0
Description: from coverage.depth.table, get the depth table between samples.
Version: V0.1 Date: 2014-10-30, add for table between samples
         V0.2 Date: 2015-02-05, add for relative mat and cluster tree
Connector: chenjunru[AT]novogene.com
Usage1: perl $0
        *--data_list <file>   input soap.coverage.list
        --fa <file>           input fa file to screening for depth=0
        --mf  <file>          input mf file to sort orders. if not set, the order is according to data_list.
        --prefix <str>        output file prefix, default is total
        --outdir <str>        output directory,default is ./
Note:
1. will produce four files,one for length and depth, one for coverage, one for length and coverage length, one for coverage.single
2. will produce total.cover.depth.relative from total.cover.depth
2. will produce tree file from prefix.cover.depth.relative
2. the script is designed for locate running or qsub\n";
#===========================================================================================================================================
###get options
$opt{data_list}=abs_path($opt{data_list});
(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
$opt{outdir}=abs_path($opt{outdir});
$opt{fa} =abs_path($opt{fa});

#====================================================================================================================
#main script
open(FA,"$opt{fa}") || die $!;
$/=">";
<FA>;
my(%id2seq);
while (my $seq=<FA>) {
	chomp $seq;
	my $seqid=$1 if($seq=~/^(\S+)/);
	$id2seq{$seqid}=">$seq";
}
close FA;

$/="\n";
open(OR,"$opt{data_list}") || die $!;
my (%id2sample,%id2length,@sample);
{
while (<OR>) {
	chomp;
	my @or=split/\s+/;
	my $sample=$or[0];
	my $depth_file=$or[1];
	{
	open(FILE,"$depth_file");
	<FILE>; #delete head information,Reference_ID...
	while (<FILE>) {
		chomp;
		my @or=split/\s+/;
		my $id=$or[0];
		my $length=$or[1];
		my $cover_length=$or[2];
		my $coverage=$or[3];
		my $depth=$or[4];
		my $single=$or[5];
		## check for length between samples.
		if ($id2length{$id}) {
			if ($id2length{$id} != $length) {
				die "the length looks diffrent btween samples,$id\n";
			}
		}else{$id2length{$id}=$length;}
		## end check
		$id2sample{$id}{$sample}{depth}=$depth;
		$id2sample{$id}{$sample}{length}=$cover_length;
		$id2sample{$id}{$sample}{coverage}=$coverage;
		$id2sample{$id}{$sample}{single}=$single;
	}
	push @sample,$sample if(!($opt{mf} && -s $opt{mf}));
	close FILE;
	}
}
close OR;
if ($opt{mf} && -s $opt{mf}) {
	open OR,"$opt{mf}";
	while (<OR>) {
		chomp;
		my @or=split/\s+/;
		push @sample,$or[0];
	}
	close OR;
}
}

## will produce four files,one for length and depth, one for coverage, one for length and coverage length, one for coverage.single
open(DEPTH,">$opt{outdir}/$opt{prefix}.cover.depth.xls");
my $head="Reference_ID\t".join("\t",@sample);
print DEPTH "$head\n";

open(COVER_LENGTH,">$opt{outdir}/$opt{prefix}.cover.length.xls");
my $length_head="Reference_ID\tReference_Length\t".join("\t",@sample);
print COVER_LENGTH "$length_head\n";

$head="Reference_ID\t".join("\t",@sample);
open(COVER,">$opt{outdir}/$opt{prefix}.coverage.xls");
print COVER "$head\n";

open(SINGLE,">$opt{outdir}/$opt{prefix}.coverage.single.xls");
print SINGLE "$head\n";
open(OUT_FA,">$opt{outdir}/$opt{prefix}.cover.screening.fa");
my ($mm,$nn);
foreach my $id (sort {$a cmp $b} keys %id2sample){
	my ($depth_mid,$cover_length_mid,$cover_mid,$single_mid);
	my ($depth_mid_sum,);
	foreach my $sample (@sample){
		$depth_mid .= "\t$id2sample{$id}{$sample}{depth}";
		$depth_mid_sum += $id2sample{$id}{$sample}{depth};
		$cover_length_mid .= "\t$id2sample{$id}{$sample}{length}";
		$cover_mid .= "\t$id2sample{$id}{$sample}{coverage}";
		$single_mid .= "\t$id2sample{$id}{$sample}{single}";
	}
	if($depth_mid_sum != 0){
		print DEPTH "$id$depth_mid\n";
		print COVER_LENGTH "$id\t$id2length{$id}$cover_length_mid\n";
		print COVER "$id$cover_mid\n";
		print SINGLE "$id$single_mid\n";
		print OUT_FA "$id2seq{$id}";
		$nn++;
	}
	$mm++;
}
close DEPTH;
close COVER_LENGTH;
close COVER;
close SINGLE;
close OUT_FA;
print "ori number:$mm\nafter depth screening:$nn\neffective rate:".$nn/$mm."\n";
`$sample_draw $opt{outdir}/$opt{prefix}.coverage.single.xls $opt{outdir}/$opt{prefix}.coverage.single.even.xls`;
`$tree_cluster $opt{outdir}/$opt{prefix}.coverage.single.even.xls >$opt{outdir}/$opt{prefix}.coverage.single.even.tree`;
`$get_len $opt{outdir}/$opt{prefix}.cover.screening.fa > $opt{outdir}/$opt{prefix}.cover.screening.fa.len.xls`;