#! /usr/bin/perl -w
# chenjunru[AT]novogene.com
# 2015-03-05
# Function: for Krona inputs 

use strict;
die"Usage:perl $0 <input:Uniq.Scaftigs.tax.single.cover.xls> <outdir>\n" if (@ARGV != 2);

my($input,$outdir)=@ARGV;
(-s $outdir) || `mkdir -p $outdir`;

open(OR,"$input");
my $head=<OR>;
chomp $head;
my @head=split/\t/,$head;
pop @head if($head[-1] eq 'Taxonomy');
my (%samples,%filehandle);
for (my $i = 1; $i < $#head+1; $i++) {
	my $outfile="$outdir/$head[$i].txt";
	open $filehandle{$outfile}, ">$outdir/$head[$i].txt";
	$samples{$head[$i]}=$i;
}
while (<OR>) {
	chomp;
	my @or=split/\t/;
	my @tax=split/;/,pop@or;
	my $tax="root";
	foreach my $mid(@tax){
		$mid=~s/^[kpcofgs]__//;
		$mid=~s/\s+/_/g;
		$tax .= "\t$mid";
	}
	for (my $i = 1; $i < $#head+1; $i++) {
		my $lasthandle=$filehandle{"$outdir/$head[$i].txt"};
		print $lasthandle "$or[$i]\t$tax\n";
	}
}
close OR;

foreach(keys %filehandle){
	close $filehandle{$_};
}