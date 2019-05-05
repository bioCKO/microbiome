#! /usr/bin/perl -w

use strict;
@ARGV >=2 || die "usage:perl $0 <input> <output> <max>\n";
my($input,$output,$max_or)=@ARGV;

open(OR,"$input");
my $head=<OR>;
chomp$head;
my @samples=split/\t/,$head;
shift@samples;
my %hash;
while (<OR>) {
 	chomp;
 	my@or=split/\t/;
 	my $id=shift@or;
 	for my $i(0..$#or){
 		next if(!$or[$i]);
        $hash{$i}+=$or[$i];
 	}
 } 
 close OR;
 my @vals=values %hash;
 my @sort_vals=sort{$a <=> $b} @vals;
 my $max=$sort_vals[-1];
 $max=$max_or if($max_or);
 my %beishu;
for my $i(0..$#samples){
	$beishu{$i}=$max/$hash{$i};
}

open(OR,"$input");
open(OUT,">$output");
<OR>;
print OUT "$head\n";
while (<OR>) {
 	chomp;
 	my@or=split/\t/;
 	my $id=shift@or;
 	print OUT "$id";
 	for my $i(0..$#or){
 		my $mid=$or[$i]*$beishu{$i};
 		print OUT "\t$mid";
 	}
 	print OUT "\n";
 } 
 close OR;
 close OUT;
