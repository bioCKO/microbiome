#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt = (maf=>0.05,depcut=>30,edge=>20);
GetOptions(\%opt,"snp:s","hsnp:s","maf:f","N","dupcut:i","edge:i");
@ARGV || die"Name: cns.pl
Description: script to review fasta file and get review SNPs or heterozygosis SNPs
Usage: perl cns.pl <in.soap.SNP.depth> > out.snp.list
    --depcut <num>      depth cutoff for masked by N, defautl=30
    --edge <num>        length form the end to ignore depcut, default=20
    --N                 unmask region not mask by N
    --R                 not to consider repeat depth anyway
    --maf <flo>         maf cutoff for heterozygosis SNP, default=0.05\n";
#==================================================================================
my $snpf = shift;
open SNP,$snpf || die$!;
my @s = qw(A T C G);
while(<SNP>){
    /^#/ && next;
    my @l = (split/\t+/)[0,1,2,4];
    my @p = split/\s+/,$l[2];
    my @p2 = split/\s+/,$l[3];
    if($p[0] < $opt{depcut}/2 && $p2[0] > $p[0] && !$opt{R}){
        for my $i(0..$#p){$p[$i] += $p2[$i]; }
    }
    $p[0] || next;
#    ($p[0] < $opt{depcut}) && ($l[1] > $opt{edge}) && 
#        (!$sizeh{$l[0]} || $l[1] <= $sizeh{$l[0]} - $opt{edge}) && next;
    my ($base,$fre,$base2,$fre2) = best_base(\@p,\@s);#sub2
    print join("\t",@l[0,1],$base,$base2,$p[0],$fre,$fre2),"\n";
}
close SNP;
#==================================================================================
#sub2
sub best_base{
    my ($p,$s) = @_;
    my @base;
    for my $i(0..3){
        push @base,[$s->[$i],$p->[$i+1]];
    }
    @base = sort {$b->[1] <=> $a->[1]} @base;
    $base[0]->[1] = sprintf("%.4f",$base[0]->[1]/$p->[0]);
    $base[1]->[1] = sprintf("%.4f",$base[1]->[1]/$p->[0]);
    (@{$base[0]},@{$base[1]});
}
