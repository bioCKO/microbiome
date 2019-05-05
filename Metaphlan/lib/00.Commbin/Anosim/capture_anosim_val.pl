#!/usr/bin/perl -w
use strict;
@ARGV == 3 || die "Usage: perl $0 <in_anosim_significance.txt> <in_anosim_group> <outfile>\n";
my ($anosim,$anosim_group,$outfile) = @ARGV;
open IN2,$anosim_group || die "Can'r open file:$anosim_group\n";
my @array;
while(<IN2>){
    s/"//g;
    s/\s+//;
    push @array,$_;
}
close IN2;
open OUT,">$outfile" || die $!;
if (-s $anosim){
    print OUT join("\t",qw/Group R-value  P-value/),"\n";
}
open IN,$anosim || die "Can'r open file:$anosim\n";
$/="Call:";
<IN>;
my $group_id = 0;
while(<IN>){
    chomp;
    s/\n+//g;
    /statistic R:\s+(\S+)\s+Significance:\s+(\S+)/;
    print OUT "$array[$group_id]\t$1\t$2\n";
    $group_id++;
}
$/="\n";
close IN;
close OUT;
