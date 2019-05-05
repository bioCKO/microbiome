#!/usr/bin/perl
(@ARGV==2) || die"perl $0 <IN.fasta> <Out.fna>\n";
open (IN, "$ARGV[0]");
$/ = ">";<IN>;$/="\n";
my $win = 100;
open(O, ">$ARGV[1]");
while(<IN>){
    my $index = 1;
    /(^(\S+))/ || next;
    my $id = $1;
    $/=">";chomp(my $seq = <IN>); $/="\n";
    $seq =~ s/\s+//g;
    my $len = length($seq);
    ($len<$win) && next;
    for(my $i = 0; $i <= $len-$win; $i += $win){
        my $subseq = substr($seq, $i, $win);
        print O ">$id.$index\n$subseq\n";
        $index++;
    }
}
close O;
