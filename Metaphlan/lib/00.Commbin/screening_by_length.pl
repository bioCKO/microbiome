#!/usr/bin/perl -w
use strict;

die "perl $0 <input fa> <cut>\n" if @ARGV != 2;
open IN,$ARGV[0] or die "Can not open $ARGV[0] $!.";
my $cut=$ARGV[1];
$/ = '>';
<IN>;
while ( my $seq = <IN> ) {
    my $id = $1 if($seq =~ /^(\S+)/); 
    chomp $seq; 
    $seq =~ s/^.+?\n//; 
    $seq =~ s/\s//g; 
    my $len = length($seq);
    print  ">$id\n$seq\n" if $len >= $cut; 
}
$/="\n";
close IN;
