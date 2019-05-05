#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use PerlIO::gzip;
my ($F,$K,$C) = ('\s+','m1');
GetOptions("F:s"=>\$F,"k:s"=>\$K,"c:s"=>\$C);
@ARGV || die"usage: perl $0 <infiles> [-opts] > out.sort
    -F <str>    split sign, default='\\s+'
    -k <str>    sort ranks, eg. m1,n2, default=m1
    -c <num>    specify one rank for classify, eg. 1, default not set.\n\n";
#============================================================================
my (@S,@K);
foreach(split/,/,$K){
    /^(\D+)(\d+)/ || die"error set at -k $K, $!";
    my ($sign, $num) = ($1, $2);
    push @K,(($sign=~/r/)?1:0)*2 + (($sign=~/n/)?1:0);
    push @S,$num-1;
}
my @data = ([]);
my %class;
my $n = $C ? -1 : 0;
foreach(@ARGV){
    /\.gz$/ ? (open IN,"<gzip",$_ || die$!) : (open IN,$_ || die$!);
    while(<IN>){
        my @l = (split/$F/);
        if($C && !$class{$l[$C]}){
            $class{$l[$C]} = $n + 2;
            $n++;
        }
        push @{$data[$n]},[@l[@S],$_];
    }
    close IN;
}
foreach my $d(@data){
    foreach(sort mysort @{$d}){
        print $_->[-1];
    }
}
        




sub mysort{
    foreach my $i(0..$#K){
        my $k = ($K[$i]==3) ? ($b->[$i] <=> $a->[$i]) :
                ($K[$i]==2) ? ($b->[$i] cmp $a->[$i]) :
                ($K[$i]==1) ? ($a->[$i] <=> $b->[$i]) :
                ($a->[$i] cmp $b->[$i]);
        $k && return($k);
    }
    0;
}
