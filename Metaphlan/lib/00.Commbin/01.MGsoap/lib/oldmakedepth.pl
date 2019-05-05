#! /usr/bin/perl -w
use strict;
use Data::Dumper;
my ($depth,$len,$covdep,$deptab,$plot) = @ARGV;
my (%num2group,%group,%gene_len,%gene,);
open(OR,"$depth")or die "Can not open $depth $!\n.";
while (<OR>) {
    chomp;
    my@or=split;
    push @{$group{$or[0]}},$or[2];
    push @{$num2group{$or[2]}},$or[0];
}
close OR;
open(IN,"$len")or die "Can not open $len $!\n.";
while (<IN>) {
    chomp;
    my @temp = split;
    $gene_len{ $temp[0] } = $temp[1];
    $gene{ $temp[0] } = 0;
    }
    close IN;
my @keys=keys %group;
my @allgene=keys %gene;
open OUT1,">$covdep";
open OUT2,">$deptab";
open OUT3,">$plot";
print OUT2 "Reference_ID\tReference_size(bp)\tCovered_length(bp)\tCoverage(%)\tDepth\tDepth_single\n";
foreach (@keys){
        my $num=scalar @{$group{$_}};
        my $he;
        for my $i (0..$num-1){
        $he+=@{$group{$_}}[$i];
        }
        my $genecover=sprintf("%.2f",100*$num/$gene_len{$_});
        my $genedepth=sprintf("%.1f",$he/$num);
        print OUT1 "$_\:\t$num\/$gene_len{$_}\tPercentage\:$genecover\tDepth\:$genedepth\n";
        print OUT2 "$_\t$gene_len{$_}\t$num\t$genecover\t$genedepth\t$he\n";
}
my ($sumnomat,$numnum);
foreach (@allgene){
        if (exists $group{$_}){
        next;
        }else{
         print OUT1 "$_\:\t$gene{$_}\/$gene_len{$_}\tPercentage\:0\tDepth\:nan\n";
         print OUT2 "$_\t$gene_len{$_}\t0\t0\t0\t0\n";
         $sumnomat+=$gene_len{$_};
        }
}
print OUT3 "0\t$sumnomat\n";
for my $i(1..400){
    if (exists $num2group{$i}){
     $numnum=scalar @{$num2group{$i}};
    }else{
    $numnum=0;}
print OUT3 "$i\t$numnum\n";
}
close OUT1;
close OUT2;
close OUT3;
