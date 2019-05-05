#!/usr/bin/perl
(@ARGV>=2) || die"perl $0 <IN.fasta> <Out.fna> [check.info] [win_size]\n";
open (IN, "$ARGV[0]");
$/ = ">";<IN>;$/="\n";
my $win = $ARGV[3] || 3000;
open(O, ">$ARGV[1]");
open(O1, ">$ARGV[2]");
print O1 "ORI_ID\tSplit_ID\tLength_ori\tLength_split\tStart\tEnd\n";
while(<IN>){
    my $index = 1;
    /(^(\S+))/ || next;
    my $id = $1;
    $/=">";chomp(my $seq = <IN>); $/="\n";
    $seq =~ s/\s+//g;
    my $len = length($seq);
    my $splitTotalLen = 0;
    ($len<$win) && (print O ">$id\n$seq\n") && (print O1 "$id\t$id\t$len\t$len\t1\t$len\n") && ($splitTotalLen += $len) && next; #if scaffold bps < window bps, print it and read next.
    my $split_num = int($len/$win); #number of windows
    my $win_size = int($len/$split_num); # new window bps according to $split_num
    my $remainder = $len % $split_num; # remainder bps shorter than one window length
    my $add = int($remainder/$split_num);
    my $add_remain = $len - ($win_size+$add)*$split_num;
    my ($start, $end);
    if($add_remain>0){
    for(my $i = 1; $i <= $add_remain; $i++){ # iterate except the last window
        my $step = $win_size+$add+1;
        $start = ($i-1)*$step; my $start_pos = $start+1;
        $end = $start+$step-1; my $end_pos = $end+1;
        my $subseq = substr($seq, $start, $step); #each window seq output
        print O ">$id\_\_$index\n$subseq\n";
        my $len2 = length $subseq; $splitTotalLen += $len2; 
        print O1 "$id\t$id\_\_$index\t$len\t$len2\t$start_pos\t$end_pos\n";
        $index++;
    }
    for(my $i = $add_remain+1; $i <= $split_num; $i++){
        my $step = $win_size+$add;
        $start = $add_remain*($win_size+$add+1)+$step*($i-$add_remain-1); my $start_pos = $start+1; 
        $end = $start+$step-1; my $end_pos = $end+1;
        my $subseq = substr($seq, $start, $step); #last window seq output
        print O ">$id\_\_$index\n$subseq\n";
        my $len2 = length $subseq; 
        $splitTotalLen += $len2;
        print O1 "$id\t$id\_\_$index\t$len\t$len2\t$start_pos\t$end_pos\n";
        $index++;
    }
    }
    else{
        for(my $i = 1; $i <= $split_num; $i++){
        my $step = $win_size+$add;
        $start = ($i-1)*$step; my $start_pos = $start+1;
        $end = $start+$step-1; my $end_pos = $end+1;
        my $subseq = substr($seq, $start, $step); #each window seq output
        print O ">$id\_\_$index\n$subseq\n";
        my $len2 = length $subseq; $splitTotalLen += $len2; 
        print O1 "$id\t$id\_\_$index\t$len\t$len2\t$start_pos\t$end_pos\n";
        $index++;
        }
    }
}
close O;
