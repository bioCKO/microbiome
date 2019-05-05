#!/usr/bin/perl -w
use strict;
@ARGV || die"usage: perl $0 <soap.SNP.depth> > out.best.base\n";
#ChrID  Pos     N A T C G       N A T C G       N A T C G       N A T C G
#scaffold1       877265  1 0 0 1 0       31 0 0 31 0     0 0 0 0 0       0 0 0 0 0
my @sign = qw(A T C G);
print "#ChrID\tPos\tBase\tSD\tTD\tRP\n";
while(<>){
    /^#/ && next;
    my @p = split;
    my $rp = $p[12];
    if($rp){
        for my $i(2..6){$p[$i] += $p[10+$i];}
    }
    my ($base,$depth) = best_base(\@sign,[@p[3..6]]);
    print join("\t",@p[0,1],$base,$depth,$p[2],$rp),"\n";
}
sub best_base{
    my ($base,$depth) = @_;
    my ($b,$d) = ($base->[0],$depth->[0]);
    for my $i(1..$#$base){
        ($depth->[$i] > $d) || next;
        ($b,$d) = ($base->[$i],$depth->[$i]);
    }
    ($b,$d);
}
