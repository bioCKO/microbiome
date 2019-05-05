#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $thread;
GetOptions("t:i"=>\$thread);
@ARGV || die"Name: multi-process.pl
Usage: perl multi-process.pl <infile | \"commend_1\" xx \"commend_2\" xx ...> [-t thread_num(default 5)]
Note: the process is danger, you should not parallel so much commends\n\n";
$SIG{CHLD} = "IGNORE";
$thread ||= 5;
my @commend;
if(@ARGV == 1 && -s $ARGV[0]){
    chomp(@commend = `awk '(\$1 && !/^#/)' $ARGV[0]`);
}else{
    chomp(@commend = split/\s+xx\s+/,"@ARGV");
}
my $i = 0;
foreach(@commend){
    $i++;
    s/&\s*$//;
    if(fork()){
        ($i>$thread) && ($i=0,wait);
    }else{exec $_;exit;}
}
@commend = ();
while (wait != -1) { sleep 1; }
