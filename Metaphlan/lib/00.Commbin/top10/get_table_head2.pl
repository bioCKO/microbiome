#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt;
GetOptions(\%opt,"trantab","sort");
@ARGV || die"usage: perl $0 <in.table> [topline(10)] > out.sel.tab\n";
my ($intab,$line) = @ARGV;
$line ||= 10;
my @others;
my $num = 0;
my @data;
my %uniq_otu;
my %item;
open IN,$intab || die$!;
while(<IN>){
    chomp;
    my @l = /\t/ ? split/\t+/ : split;
    $l[0]=(split/;/,$l[0])[-1];
    $item{$l[0]} = 1;
    if($num){
        for my $i(1..$#l){
            if(is_number($l[$i])){
                $others[$i-1] += $l[$i];
            }elsif($l[0]){
                push @{$uniq_otu{$l[0]}},[$num,$l[$i]];
            }
        }
    }
    if($opt{trantab}){
        for my $i(0..$#l){
            push @{$data[$i]},$l[$i];
        }
    }else{
        push @data,[@l];
    }
    $num++;
    ($num > $line) && last;
}
close IN;
for (@others){
    $_ = 1-$_;
    ($_ < 0) && ($_ = 0);
}
my $end_str = %uniq_otu ? 1 : 0;
if(!$item{Others}){
    unshift @others,"Others";
    push @others,($end_str ? 'k__All' : "-");
    push @{$uniq_otu{$others[0]}},[$num,$others[-1]];
    if($opt{trantab}){
        for my $i(0..$#others){
            push @{$data[$i]},$others[$i];
        }
    }else{
        push @data,[@others];
    }
}
for my $k(keys %uniq_otu){
    $#{$uniq_otu{$k}} || next;
    for my $i(@{$uniq_otu{$k}}){
        $i->[1] .= ";";
        my @lname = ($i->[1] =~ m/\w__(.+?);/g);
        if(@lname>1){
            my $name = "$lname[-2]-$lname[-1]";
            if($opt{trantab}){
                $data[0]->[$i->[0]] = $name;
            }else{
                $data[$i->[0]]->[0] = $name;
            }
        }
    }
}
$opt{trantab} && pop(@data);
if($opt{sort}){
    @data[1..$#data] = sort {$a->[0] cmp $b->[0]} @data[1..$#data];
}
for(@data){
    print join("\t",@{$_}),"\n";
}
sub is_number{
    my $num = shift;
    ($num =~ /^-?\d+$/ || $num =~ /^-?\d+e-?\d+$/ || $num =~ /^-?\d+\.\d+$/ || $num =~ /^-?\d+\.\d+e-?\d+/) ? 1 : 0;
}
