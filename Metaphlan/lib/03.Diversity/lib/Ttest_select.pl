#!/usr/bin/perl -w
use strict;
@ARGV>=3 || die"usage: perl $0 <in.table> <groupNum> <Pvalue_cut> [Qvalue_cut(not set)] > out.file\n";
my ($table,$num,$pvalue,$qvalue) = @ARGV;
my @filter;
$num *= 2;
open IN,$table || die$!;
chomp(my $head = <IN>);
my @vs = $head =~ /\t/ ? split/\t+/,$head : split/\s+/,$head;
@vs = @vs[$num+1 .. $#vs];
my @pvalues;
while(<IN>){
    chomp;
    my @l = /\t/ ? split/\t+/ : split;
    my $item = shift @l;
    @l = @l[$num .. $#l];
    my @str;
    for my $i(0..$#l){
        if($l[$i] < $pvalue){
            push @str,$i;
            push @{$pvalues[$i]},$l[$i];
        }
    }
    @str && (push @filter,[$item,@str]);
}
close IN;

if(@filter){
    for(@pvalues){
        caculate_qvalue($_);
    }
    print join("\t","#Item",qw(DiffNum DiffPairs PairsPvalues PairsQvalues)),"\n";
    for my $p(@filter){
        my $item = shift @{$p};
        my (@str,@P,@Q);
        my $num = 0;
        for (@{$p}){
            my ($p,$q) = @{$pvalues[$_]->[0]};
            shift @{$pvalues[$_]};
            (defined $qvalue && $q>$qvalue) && next;
            push @str,$vs[$_];
            push @P,$p;
            push @Q,$q;
            $num++;
        }
        $num && (print join("\t",$item,$num,join(",",@str),join(",",@P),join(",",@Q)),"\n");
    }
}

sub caculate_qvalue{
    my ($arr) = @_;
    ($arr && @$arr) || return(0);
    my @new_arr;
    for my $i(0..$#$arr){
        push @new_arr,[$i,$arr->[$i]];
    }
    my $m = @new_arr;
    @$arr = ();
    my $i = 1;
    for my $p (sort {$a->[1]<=>$b->[1]} @new_arr){
        $arr->[$p->[0]] = [$p->[1], $m*$p->[1] / $i];
        $i++;
    }
}
