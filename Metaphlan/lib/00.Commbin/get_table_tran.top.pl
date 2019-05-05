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
    next if /^Others\t/;
    my @l = /\t/ ? split/\t+/ : split;
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
        my $flag=0;
        if(! &is_number($l[-1]) && $num){
            push @{$data[0]},"$l[0]";
            $flag=1;
        }else{
            #push @{$data[$#l]},$l[0];
        }
        for my $i($flag..$#l){
            push @{$data[$i]},$l[$i];
        }
    }else{
        push @data,[@l];
    }
    $num++;
    ($num > $line) && last;
}
close IN;

$opt{trantab} && pop(@data);

for(@data){
    print join("\t",@{$_}),"\n";
}
sub is_number{
    my $num = shift;
    ($num =~ /^-?\d+$/ || $num =~ /^-?\d+e-?\d+$/ || $num =~ /^-?\d+\.\d+$/ || $num =~ /^-?\d+\.\d+e-?\d+/) ? 1 : 0;
}
