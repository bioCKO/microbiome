#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt = (maf=>0.05,depcut=>30,edge=>20);
GetOptions(\%opt,"snp:s","hsnp:s","maf:f","N","dupcut:i","edge:i");
@ARGV || die"Name: cns.pl
Description: script to review fasta file and get review SNPs or heterozygosis SNPs
Usage: perl cns.pl <in.soap.SNP.depth> [org.fa] > out.cns
    --depcut <num>      depth cutoff for masked by N, defautl=30
    --edge <num>        length form the end to ignore depcut, default=20
    --N                 unmask region not mask by N
    --R                 not to consider repeat depth anyway
    --snp <file>        output review SNPs
    --hsnp <file>       output heterozygosis SNPs
    --maf <flo>         maf cutoff for heterozygosis SNP, default=0.05\n";
#==================================================================================
my ($snpf,$fasta) = @ARGV;
my (%fastah, %sizeh);
get_fasta($fasta,\%fastah, \%sizeh);#sub1
%fastah || ($opt{snp} = 0);
open SNP,$snpf || die$!;
$opt{hsnp} && (open HS,">$opt{hsnp}" || die$!);
my %CNS;
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
    ($p[0] < $opt{depcut}) && ($l[1] > $opt{edge}) && 
        (!$sizeh{$l[0]} || $l[1] <= $sizeh{$l[0]} - $opt{edge}) && next;
    my ($base,$fre,$base2,$fre2) = best_base(\@p,\@s);#sub2
    $CNS{$l[0]}->[$l[1]] = $base;
    if($opt{hsnp} && $fre2 >= $opt{maf}){
        chomp;
        print HS join("\t",$_,$base,$fre,$base2,$fre2),"\n";
    }
}
close SNP;
$opt{hsnp} && close(HS);
if(!%sizeh){
    for my $k(keys %CNS){$sizeh{$k} = @{$CNS{$k}};}
}
$opt{snp} && (open SP,">$opt{snp}" || die$!);
for my $id (sort {$a cmp $b} keys %sizeh){
    my @seq = $CNS{$id} ? @{$CNS{$id}} : ();
    my @seq2 = $fastah{$id} ? split//,$fastah{$id} : ();
    for my $i (0 .. $sizeh{$id}-1){
        if($seq2[$i] && $seq[$i+1]){
            if($seq2[$i] ne $seq[$i+1]){
                $opt{snp} && (print SP join("\t",$id,$i+1,$seq2[$i],$seq[$i+1]),"\n");
                $seq2[$i] = $seq[$i+1];
            }
        }elsif($seq2[$i]){
            $opt{N} || ($seq2[$i] = "N");
        }else{
            $seq2[$i] = "N";
        }
    }
    my $seqs = join("",@seq2);
    $seqs =~ s/(.{1,60})/$1\n/g;
    print ">$id\n",$seqs;
}
$opt{snp} && close(SP);

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
#sub1
sub get_fasta{
    my ($faf,$fah,$sizeh) = @_;
    ($faf && -s $faf) || return(0);
    if(`head -1 $faf` =~ /^>/){
        open FA,$faf || die$!;
        $/=">";<FA>;
        while(<FA>){
            /^(\S+)/ || next;
            my $id = $1;
            s/^.+?\n|\s|>//g;
            $fah->{$id} = $_;
            $sizeh->{$id} = length;
        }
        close FA;
        $/="\n";
    }else{
        %{$sizeh} = split/\s+/,`awk '{print \$1,\$2}' $faf`;
    }
}






