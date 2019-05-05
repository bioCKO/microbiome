#!/usr/bin/perl
(@ARGV==2) || die "perl $0 <ori.coverage> <mean_cov.table>";
open(IN, "$ARGV[0]");
my %contig2cov;
my $posNum=0;
my $record_id="";
my %contig2posNum;
while(<IN>){
    chomp;
    my($id, $dep) = (split /\t/, $_)[0,-1];
    if(not exists $contig2cov{$id}){$contig2posNum{$record_id} = $posNum;$posNum=0;}
    $contig2cov{$id} += $dep;$posNum++;
    $record_id = $id;
}
$contig2posNum{$record_id} = $posNum;
close IN;

open(OUT, ">$ARGV[1]");
print OUT "Contig ID\tMean Coverage\n";
foreach my $id (keys %contig2cov){
    my $mean_cov = $contig2cov{$id}/$contig2posNum{$id};
    print OUT "$id\t$mean_cov\n";
}
close OUT;

