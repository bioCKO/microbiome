#!/usr/bin/perl
(@ARGV==2) || die "perl $0 <ori.coverage> <mean_cov.table>";
open(IN, "$ARGV[0]");
my %contig2cov;
while(<IN>){
    chomp;
    my($id, $dep, $ratio) = (split /\t/, $_)[0, 1, -1];
    $contig2cov{$id} += $dep*$ratio;
}
close IN;

open(OUT, ">$ARGV[1]");
print OUT "Contig ID\tMean Coverage\n";
foreach my $id (keys %contig2cov){
   print OUT "$id\t$contig2cov{$id}\n";
}
close OUT;

