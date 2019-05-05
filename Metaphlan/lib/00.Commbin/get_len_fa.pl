#!/usr/bin/perl -w
use strict;

open IN,$ARGV[0] or die "Can not open $ARGV[0] $!.";
$/ = '>';
<IN>;
while ( my $seq = <IN> ) {
    my $id = $1 if($seq =~ /^(\S+)/); 
    chomp $seq; 
    $seq =~ s/^.+?\n//; 
    $seq =~ s/\s//g; 
    my $len = length($seq);
    print  "$id\t$len\n"; 
}
$/="\n";
close IN;
