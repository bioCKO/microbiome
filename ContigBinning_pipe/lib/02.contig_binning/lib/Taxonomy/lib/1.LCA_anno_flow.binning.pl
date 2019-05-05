#!/usr/bin/perl -w
use File::Basename;
use Getopt::Long;
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);


# set default options
my (
	$m8,$output,$outdir,
);
$outdir="./";
$output="Unigenes";
#get options from screen
GetOptions(
	"m8:s" => \$m8,"output:s" => \$output,"outdir:s" => \$outdir,
);


#get software pathway
use lib "/PUBLIC/software/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V4.2/lib/00.Commbin/";
my $lib = "$Bin/..";
use PATHWAY;
(-s "$Bin/../Pathway_cfg.txt") || die"error: can't find config at $Bin/.., $!\n";
#my($gi_taxid,$names,$nodes) = get_pathway("/PROJ/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V2.2/bin/Pathway_cfg.txt",[qw(GI2TAXID NAMES NODES)],$Bin,$lib);
my($gi_taxid,$names,$nodes) = get_pathway("$Bin/../Pathway_cfg.txt",[qw(GI2TAXID NAMES NODES)],$Bin,$lib);


#====================================================================================================================
($m8 && -s $m8) || 
die "Name: $0
Description: Script to LCA annotation(Taxonomy)
Version: 3.0  Date: 2015-06-22
Connector: chenjunru[AT]novogene.com
Usage1: perl $0 --m8 <blastout m8 file> [options]
        *-m8         input blast m8 outfile for LCA annotation
        --output     outputfile prefix, default is Unigenes
        --outdir     output directory,default is ./
";
#====================================================================================================================
## main Script
$outdir=abs_path($outdir);
(-s $outdir) || `mkdir -p $outdir`;

open( F, $m8 ) || die "Can't open $m8!\n";
my (%gi2taxid,%hash);
{ #releasing memory for %need
	my %need;
	while (<F>) {
		chomp;
		my @tmp        = split /\t/;
		my $gid        = ( split /\|/, $tmp[1], 3 )[1];
		$need{$gid} = 1;
	}
	close(F);

	open( F, $gi_taxid ) || die "Can't open $gi_taxid!\n";
    <F>;
	while (<F>) {
		chomp;
		my @tmp = split /\s+/;
		next if !$need{ $tmp[0] };
		$gi2taxid{ $tmp[0] } = $tmp[1];
	}
	close(F);
}
{
	open( F, $nodes ) || die "Can't open $nodes!\n";
	while (<F>) {
		chomp;
		my@tmp = split /\s*\|\s*/;
		${$hash{$tmp[0]}}[0]=$tmp[1]."($tmp[2])";
	}
	close(F);

	open( F, $names ) || die "Can't open $names!\n";
	while (<F>) {
		chomp;
		my @tmp = split /\s*\|\s*/;
		if ( $tmp[3] =~ /scientific name/ ) {
			${$hash{$tmp[0]}}[1]= $tmp[1];
		}
	}
	close(F);
}

my (%geneid2tax,%taxid2tree,%taxid2tree2totalrank,%geneid2tax2totalrank);
my @ranks=("superkingdom","phylum","class","order","family","genus","species");
my @rank_breif=("k__","p__","c__","o__","f__","g__","s__");
{
	open( F, $m8 ) || die "Can't open $m8!\n";
	open(OUT ,">$outdir/$output.m8.tax.xls");
	## add m8 head information?
	while (<F>) {
		chomp;
		my @tmp=split/\t/;
		my $gid = ( split /\|/, $tmp[1], 3 )[1];
		my $tax_id = $gi2taxid{$gid};
		print OUT "$_";
		&selecting($tax_id,$tax_id) if(!$taxid2tree{$tax_id});
		my $taxonomy;
		foreach my $i (0..6){
			$taxid2tree{$tax_id}{$ranks[$i]} ?
			($taxonomy.="$rank_breif[$i]$taxid2tree{$tax_id}{$ranks[$i]};"):
			($taxonomy.= "$rank_breif[$i]Unclassified;");
		}
		$taxonomy=substr($taxonomy,0,-1);
		$taxonomy=~s/(;.__Unclassified)+$//g;
		$taxonomy="Unclassified" if(!$taxonomy);
		$taxonomy=~s/\'/_/g;
		$taxonomy=~s/\//_/g;
		print OUT "\t$tax_id\t$taxonomy\n";
		push @{$geneid2tax{$tmp[0]}},$taxonomy if(!grep {$taxonomy eq $_} @{$geneid2tax{$tmp[0]}});

        &selecting_totalrank($tax_id,$tax_id) if(!$taxid2tree2totalrank{$tax_id});
		my $taxonomy_totalrank=$taxid2tree2totalrank{$tax_id} if($taxid2tree2totalrank{$tax_id});
		$taxonomy_totalrank=substr($taxonomy_totalrank,0,-1);
		$taxonomy_totalrank=~s/(;.__Unclassified)+$//g;
		$taxonomy_totalrank="Unclassified" if(!$taxonomy_totalrank);
		$taxonomy_totalrank=~s/\'/_/g;
		$taxonomy_totalrank=~s/\//_/g;
		push @{$geneid2tax2totalrank{$tmp[0]}},$taxonomy_totalrank if(!grep {$taxonomy_totalrank eq $_} @{$geneid2tax2totalrank{$tmp[0]}});
	}	
	close F;
	close OUT;
}


open(OUT,">$outdir/$output.lca.tax.xls");
## add head information ?
foreach my $geneid (sort{$a cmp $b} keys %geneid2tax){
	my @geneid2tax=@{$geneid2tax{$geneid}};
	my $lca_tax=&lca_tax(@geneid2tax);
	print OUT "$geneid\t$lca_tax\n";
}
close OUT;

open(OUT,">$outdir/$output.lca.tax.detail.xls");
## add head information ?
foreach my $geneid (sort{$a cmp $b} keys %geneid2tax2totalrank){
	my @geneid2tax=@{$geneid2tax2totalrank{$geneid}};
	my $lca_tax=&lca_tax_totalrank(@geneid2tax);
	print OUT "$geneid\t$lca_tax\n";
}
close OUT;

#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#	subprogram
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sub selecting {
	my($select2,$last,$last_rank);
	my ($in,$ori_id)=@_;
	$select2=${$hash{$in}}[0];
	if($select2=~/(\d+)\((.*)\)/){$last=$1;$last_rank=$2;}
	$taxid2tree{$ori_id}{$1}=${$hash{$in}}[1] if ($last_rank=~/^(superkingdom|phylum|class|order|family|genus|species)$/);
	if ($select2=~/^(\d+)/){
		$select2=$1;
	}
	if ($select2 != 1){
		selecting($select2,$ori_id);
	}
}

sub lca_tax{
	my @or=@_;
	my %taxinfo;
	my $taxnum=$#or+1;
	foreach my $tax (@or){
		my @taxs=split/;/,$tax;
		foreach(@taxs){
			my $rank=substr($_,0,3);
			$taxinfo{$rank}{$_} ++;
		}
	}
	my $lca_tax;
	BLOCK:foreach my $rank (@rank_breif){
			foreach my $tax (keys %{$taxinfo{$rank}}){
				($taxinfo{$rank}{$tax} eq $taxnum)?
				($lca_tax .= "$tax;"):
				last BLOCK;
			}
		}
	($lca_tax)?($lca_tax=substr($lca_tax,0,-1)):($lca_tax="Unclassified");
	return $lca_tax;
}
sub selecting_totalrank {
	my($select2,$last,$last_rank);
	my ($in,$ori_id)=@_;
	$select2=${$hash{$in}}[0];
	if($select2=~/(\d+)\((.*)\)/){$last=$1;$last_rank=$2;}
	$taxid2tree2totalrank{$ori_id}.="$last_rank\__${$hash{$in}}[1];";
	if ($select2=~/^(\d+)/){
		$select2=$1;
	}
	if ($select2 != 1){
		selecting_totalrank($select2,$ori_id);
	}
}

sub lca_tax_totalrank{
	my @or=@_;
    my %taxinfo;
    my $taxnum=$#or+1;
    my $ranknum;
    foreach my $tax (@or){
        my @taxs=split/;/,$tax;
        my $i=0;
        @taxs=reverse@taxs;
        foreach(@taxs){
            $taxinfo{$i}{$_} ++;
            $i++;
        }
        $ranknum=$i-1;
    }
    my $lca_tax;
    BLOCK:foreach my $rank (0..$ranknum){
        foreach my $tax (keys %{$taxinfo{$rank}}){
        ($taxinfo{$rank}{$tax} eq $taxnum)?($lca_tax .= "$tax;"):last BLOCK;
    }                                                                                             }
    ($lca_tax)?($lca_tax=substr($lca_tax,0,-1)):($lca_tax="Unclassified");
    return $lca_tax;
}
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#	End
#/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
