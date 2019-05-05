#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;

# set default options
my %opt = (outdir=>'./',prefix=>'total',"cutoff"=>2);

#get options from screen
GetOptions(
    \%opt,"data_list:s","outdir:s","prefix:s","fa:s","cutoff:n","mf:s","len:s",
);
## get software's path
use lib "$Bin/../../../00.Commbin/";
my $lib = "$Bin/../../..";
use PATHWAY;
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin, $!\n";
my ($tree_cluster,$get_len) = get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(TREE GET_LEN)],$Bin,$lib);
my $sample_draw="perl $Bin/sample_draw.pl ";
#====================================================================================================================
($opt{data_list} && -s $opt{data_list} && $opt{fa} && -s $opt{fa} && $opt{len} && -s $opt{len})|| 
die "Name: $0
Description: from sample.readsNum.xls, get the readsNum, even, relative table between samples.
Version: V0.1 Date: 2015-04-20, 
Connector: chenjunru[AT]novogene.com
Usage1: perl $0
        *--data_list <file>   input total.readsNum.list
        --mf  <file>          input mf file to sort orders. if not set, the order is according to data_list.
        *--fa <file>          input fa file to screening for readsNum=0
        *--len <file>         Gene lenth info file
        --prefix <str>        output file prefix, default is total
        --outdir <str>        output directory,default is ./
        --cutoff <num>        the cutoff for readsNum, default=2 (must have one sample's readsNum > 2)
Note:
\n";
#===========================================================================================================================================
###get options
$opt{data_list}=abs_path($opt{data_list});
$opt{mf} && ($opt{mf}=abs_path($opt{mf}));
$opt{outdir}=abs_path($opt{outdir});
(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
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
my %gene_len;
if ( -s $opt{len} ) {
	open(LEN,"$opt{len}");
	while (my $or=<LEN>) {
		chomp$or;
		my @or=split/\s+/,$or;
		$gene_len{$or[0]}=$or[1];
	}
	close LEN;
}


open(OR,"$opt{data_list}") || die $!;
my(%id2sample2readsnum,@sample,);
while (<OR>) {
	chomp;
	my @or=split/\s+/;
	my $sample=$or[0];
	my $depth_file=$or[1];
	open(FILE,"$depth_file") || (warn"$!" && next);
	<FILE>; #delete head information,Gene_ID Gene_Reads      Relative_Abundance
	while (<FILE>) {
		chomp;
		my @or=split/\s+/;
		my $id=$or[0];
		my $readsnum=$or[1];
		$id2sample2readsnum{$id}{$sample}=$readsnum;
	}
	push @sample,$sample;
	close FILE;
}
close OR;

if ($opt{mf}) {
	undef@sample;
	open(OR,"$opt{mf}");
	while (<OR>) {
		chomp;
		my @or=split/\t/;
		push @sample,$or[0];
	}
	close OR;
}

## will produce four files,one for length and depth, one for coverage, one for length and coverage length, one for coverage.single
open(NUM,">$opt{outdir}/$opt{prefix}.readsNum.xls");
my $head="Reference_ID\t".join("\t",@sample);
print NUM "$head\n";
open(OUT_FA,">$opt{outdir}/$opt{prefix}.readsNum.screening.fa");
my ($mm,$nn,%totalnum,%tempcount,%tempsum);
foreach my $id (sort {$a cmp $b} keys %id2sample2readsnum){
	my ($readsnum_mid,$relative_mid,$depth_mid_sum);
    my $flag=0;
	foreach my $sample (@sample){
		$readsnum_mid .= "\t$id2sample2readsnum{$id}{$sample}";
		$depth_mid_sum += $id2sample2readsnum{$id}{$sample};
        $flag=1 if $id2sample2readsnum{$id}{$sample} > $opt{cutoff};
	}
	if($flag && $flag == 1){
		print NUM "$id$readsnum_mid\n";
		print OUT_FA "$id2seq{$id}";
		$nn++;
		foreach my $sample(@sample){
			$totalnum{$sample} += $id2sample2readsnum{$id}{$sample};
			$tempcount{$sample}{$id} = $id2sample2readsnum{$id}{$sample}/$gene_len{$id} ;
			$tempsum{$sample} += $tempcount{$sample}{$id} ;
		}
	}
	$mm++;
}
close NUM;
close OUT_FA;
open(RELATIVE,">$opt{outdir}/$opt{prefix}.readsNum.relative.xls");
print RELATIVE "$head\n";
foreach my $id (sort {$a cmp $b} keys %id2sample2readsnum){
	my $depth_mid_sum;
    my $flag=0;
	foreach my $sample (@sample){
		$depth_mid_sum += $id2sample2readsnum{$id}{$sample};
        $flag=1 if $id2sample2readsnum{$id}{$sample} > $opt{cutoff};
	}
	if($flag == 1){
		print RELATIVE  "$id";
		foreach my $sample(@sample){
			my $temp=$tempcount{$sample}{$id}/$tempsum{$sample};
			$temp?
			print RELATIVE "\t$temp":
			print RELATIVE "\t0";
		}
		print RELATIVE "\n";
	}
}
close RELATIVE;

#for table even
my @sample_sum=values %totalnum;
@sample_sum=sort{$a <=> $b} @sample_sum;
#end for table even
print "ori number:$mm\nafter depth screening:$nn\neffective rate:".$nn/$mm."\n";
`$sample_draw $opt{outdir}/$opt{prefix}.readsNum.relative.xls $opt{outdir}/$opt{prefix}.readsNum.even.xls $sample_sum[-1] `;
`$tree_cluster $opt{outdir}/$opt{prefix}.readsNum.even.xls >$opt{outdir}/$opt{prefix}.readsNum.even.tree`;
`$get_len $opt{outdir}/$opt{prefix}.readsNum.screening.fa > $opt{outdir}/$opt{prefix}.readsNum.screening.fa.len.xls`;
