#!usr/bin/perl -w
use strict;
my ($in1,$in2,$out)=@ARGV;
open IN1,$in1;
my %hash;
while (<IN1>){
    chomp;
    my @l = split /\t/;
    my $l = $l[0];
    $l =~ s/&|\(|\)|\[|\]|;|://g;
    $l =~ s/,|-| /\_/g;
#   $l =~ s/;/\_/g;
#    $l =~ s/,/\_/g;
#    $l =~ s/:/\_/g;
#    $l =~ s/ /\_/g;
    $hash{$l} = $l[0];
}
close IN1;

open OUT,">$out";
print OUT "ori_name\t\t\tamend_name\n";
open IN2,$in2;
my $line = <IN2>;
my @sam = split /,/,$line;
pop @sam;
for (@sam){
    if ($_ ne "Others" &&  exists $hash{$_}){
        print OUT "$hash{$_}\t\t\t$_\n";
    }
}
close IN2;
close OUT;
    
