#!/usr/bin/perl -w
use strict;
use Getopt::Long;
#use PerlIO::gzip;
my ($ident,$len,$rank,$nohead,$size,$noann) = (0.8, 100);
GetOptions("ident:f"=>\$ident,"len:i"=>\$len,"ranks:s"=>\$rank,"nohead"=>\$nohead,"size:s"=>\$size,"noann"=>\$noann);
@ARGV || die"Usage:perl $0 <blast.m0.xls> > out.stat
    --ident <flo>       minimal  identity cutoff, default=0.8
    --len <num>         minimal length cutoff, default=100
    --ranks <str>       the ranks of ID,start,end,Seqlen,algLen,identity,anno[,+/-], default='4,6,7,5,11,8,-1'
    --size <file>       set size file to ignore Seqlen rank, default not set
    --nohead            not output head title
    --noann             no annotation info\n";
my @sel = $rank ? split/,/,$rank : (4,6,7,5,11,8,-1);
#($inf =~ /\.gz$/) ? (open IN,"<:gz",$inf || die$!) : (open IN,$inf || die$!);
my %sizeh = ($size && -s $size) ? split/\s+/,`awk '{print \$1,\$2}' $size` : ();
my (%pos, %anno);
while(<>){
     (!/\d/ || /^#/) && next;
    chomp;
    my @l = /\t/ ? (split/\t+/)[@sel] : (split)[@sel];
    ($l[1] > $l[2]) && (@l[1,2] = @l[2,1]);
    (!$l[3] && $sizeh{$l[0]}) && ($l[3] = $sizeh{$l[0]});
    $l[4] ||= $l[2] - $l[1] + 1;
    ($l[4] < $len) && next;
    ($l[5] && $l[5] < $ident) && next;
    $l[6] ||= '--';
    $l[7] && ($l[1] .= "\t".$l[7]);
    (defined $anno{$l[0]}) || ($anno{$l[0]} = [@l[3,6]]);
    push @{$pos{$l[0]}},[@l[1,2]];
}
%pos || exit;
my $end = $noann ? "Rate(%)\n" : "Rate(%)\tAnnotation\n";
$nohead || (print $sel[7] ? "ID\tStand\tRefs Length\tMap Num\tMap Length\t$end" :
"ID\tRefs Length\tMap Num\tMap Length\t$end");
foreach my $id(sort keys %pos){
    my ($s,$e,$len) = (0,0,-1);
    foreach my $p(sort {$a->[0] <=> $b->[0] || $a->[1]<=>$b->[1]} @{$pos{$id}}){
        if(!$e || $p->[0]>$e+1){
            $len += $e - $s + 1;
            ($s,$e) = @{$p};
        }elsif($p->[1] > $e){
            $e = $p->[1];
        }
    }
    $len += $e - $s + 1;
    my $num = @{$pos{$id}};
    my $rate = sprintf("%.3f",100*$len/$anno{$id}->[0]);
    @{$pos{$id}} = (); delete $pos{$id};
    print join("\t",$id,$anno{$id}->[0],$num,$len, $noann ? $rate : ($rate,$anno{$id}->[1])),"\n";
}
