#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt = (cut_num=>5,prefix=>'subf',outdir=>'.');
GetOptions(\%opt,"add_num:i","seq_lim:f");
@ARGV || die"Usage: perl cut_seq.pl <in.fa> [cut_num(5)] [sub_file_prefix(subf)] [outdir(./)]
    --cut_num <num>         sequence cut number, default=5
    --prefix <str>          subfile prefix, default=subf
    --outdir <dir>          output directory, default=./
    --add_num <num>         add num main scaffold to outseq file
    --seq_lim <flo>         limit the size of add scaffold(Kb), default the whold sequence\n";
my ($inf,$cut_num,$prefix,$outdir) = @ARGV;
(-s $inf) || die"error: can't find file $inf, $!";
$cut_num ||= $opt{cut_num};
$prefix ||= $opt{prefix};
$outdir ||= $opt{outdir};
chomp(my $seq_num = `grep -c ">" $inf`);
$seq_num || die"error form at fasta file $inf, $!";
if($opt{add_num} && $opt{add_num} < $seq_num){
    $seq_num = $opt{add_num};
}else{
    $opt{add_num} = 0;
}
($cut_num > $seq_num) && ($cut_num = $seq_num);
my @out;
my ($n, $m, $a) = (0, 0, 0);
$opt{seq_lim} && ($opt{seq_lim} *= 1000);
open IN,$inf || die"$!\n";
$/=">";<IN>;
while(<IN>){
    chomp;
    if($opt{seq_lim}){
        my $id = $1 if(/^(.+?)\n/);
        s/^.+?\n|s//g;
        (length > $opt{seq_lim}) && ($_ = substr($_,0,$opt{seq_lim}));
        $_ = "$id\n" . $_ . "\n";
    }
    $out[$n] .= ">".$_;
    $a++;
    ($a == $opt{add_num}) && last;
    $m ? ($n--) : ($n++);
    ($n==$cut_num) && ($n = $cut_num-1,$m=1);
    ($n<0) && ($m = 0, $n=0)
}
$/="\n";
close IN;
(-d $outdir) || mkdir($outdir);
foreach(1..$cut_num){
    open OUT,">$outdir/$prefix\_$_.fa";
    print OUT $out[$_-1];
    close OUT;
}
