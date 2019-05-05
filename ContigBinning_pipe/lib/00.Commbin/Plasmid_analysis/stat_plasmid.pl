#!/usr/bin/perl -w
use strict;
use Getopt::Long;
#use PerlIO::gzip;
my ($ident,$cover,$len, $top,$rank,$nohead,$size,$noann) = (0.8, 2, 50, 5);
GetOptions("ident:f"=>\$ident,"len:i"=>\$len,"ranks:s"=>\$rank,"nohead"=>\$nohead,
    "size:s"=>\$size,"noann"=>\$noann,"cover:f"=>\$cover,"top:i"=>$top);
@ARGV || die"Usage:perl $0 <blast.m0.xls> > out.stat
    --ident <flo>       minimal identity cutoff, default=0.8
    --cover <flo>       minimal coverage cutoff, default=30
    --len <num>         minimal length cutoff, default=100
    --size <file>       set size file to ignore Seqlen rank, default not set
    --top <num>         output the top max coverage result for eatch scaffold, default=5
    --nohead            not output head title\n";
my $inf = shift;
($inf =~ /\.gz$/) ? (open IN,"<:gz",$inf || die$!) : (open IN,$inf || die$!);
my %sizeh = ($size && -s $size) ? split/\s+/,`awk '{print \$1,\$2}' $size` : ();
my (%pos, %pos2, %anno, %sizeh2);
#Query_id        Query_length    Query_start     Query_end       Subject_id      Subject_length  Subject_start   Subject_end     Identity        Positive        Gap     Align_length      Score   E_value Query_annotation        Subject_annotation
#Scaffold1       1019331 908967  909406  gi|75812661|ref|NC_007412.1|    300758  202448  202887  0.83    --      0       440     301     2e-77   --      Anabaena variabilis ATCC 29413 plasmid C, complete sequence
while(<IN>){
     (!/\d/ || /^#/) && next;
    chomp;
    my @l = /\t/ ? (split/\t+/) : (split);
    ($l[8] < $ident || $l[11] < $len) && next;
    @l = @l[0..7,-1];
    ($l[2] > $l[3]) && (@l[2,3] = @l[3,2]);
    ($l[6] > $l[7]) && (@l[6,7] = @l[7,6]);
    $l[-1] = (split/,/,$l[-1])[0];
    ($l[4] =~ /gi\|\d+\|ref\|(\S+)\|/) && ($l[4] = $1);
    $anno{$l[4]} ||= $l[-1];
    $sizeh{$l[0]} ||= $l[1];
    $sizeh2{$l[4]} ||= $l[5];
    my $key = "@l[0,4]";
    push @{$pos{$key}},[@l[2,3]];
    push @{$pos2{$key}},[@l[6,7]];
}
close IN;
%pos || exit;
my %poss;
foreach (sort keys %pos){
    my ($id, $gi) = split;
    my $len = cover_len($pos{$_});#sub1
    my $len2 = cover_len($pos2{$_});#sub1
    my $rate = sprintf("%.3f",100*$len/$sizeh{$id});
    my $rate2 = sprintf("%.3f",100*$len2/$sizeh2{$gi});
    ($rate2 < $cover) && next;
    delete $pos{$_};
    delete $pos2{$_};
    my $ann = join("\t",$id,$sizeh{$id},$rate,$gi,$sizeh2{$gi},$rate2,$anno{$gi})."\n";
    push @{$poss{$id}},[$rate,$ann];
}
%poss || exit;
#$nohead || (print "Scaf_ID\tStart\tEnd\t#Block\tCoverLen\tScafLen\tCoverage(%)\tgi\tAnnotation\n");
$nohead || (print "Scaf_ID\tSeqLen\tCoverage(%)\tPlasmid\tPlasmidLen\tPlasmidCoverage(%)\tAnnotation\n");
foreach my $id (sort keys %poss){
    my $n = 0;
    foreach (sort {$b->[0] <=> $a->[0]} @{$poss{$id}}){
        print $_->[1];
        $n++;
        ($n == $top) && last;
    }
}
#============================================================================================
#sub1
sub cover_len{
    my $pos = shift;
    my ($s,$e,$len) = (0,0,0);
    foreach my $p(sort {$a->[0] <=> $b->[0] || $a->[1]<=>$b->[1]} @{$pos}){
        if(!$e || $p->[0]>$e+1){
            $e && ($len += $e - $s + 1);
            ($s,$e) = @{$p};
        }elsif($p->[1] > $e){
            $e = $p->[1];
        }
    }
    $len + $e - $s + 1;
}
