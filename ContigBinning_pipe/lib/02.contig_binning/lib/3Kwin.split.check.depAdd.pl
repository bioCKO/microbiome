#!/usr/bin/perl

@ARGV>=3 || die"perl $0 <coverage.depth.table> <win.split.check.info> <win.split.check.info.depAdd.info>\n";

my %subid2dep;
open (F1, "$ARGV[0]");
<F1>;
while(<F1>){
    chomp;
    my ($subid, $dep) = (split/\t/, $_)[0,1];
    $subid2dep{$subid} = $dep;
}
close F1;

open (F2, "$ARGV[1]");
open (O, ">$ARGV[2]");
my $head = <F2>; $head =~ s/\n//g; $head .= "\tmean_cov\n";
print O $head;
while(<F2>){
    chomp;
    my $subid = (split/\t/, $_)[1];
    if(exists $subid2dep{$subid}){
        print O "$_\t$subid2dep{$subid}\n";
    }else{
        print O "$_\t0\n";
    }
}
close F2;close O;
