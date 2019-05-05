#!/usr/bin/perl

use Getopt::Long;

# set default options
my %opt = (
    "prefix","output",
);

#get options from screen
GetOptions(
    \%opt,
    #main options
    "check:s","cov_pese:s","cov_pe:s","fa:s","prefix:s",
    
);

($opt{check} && -s $opt{check} && $opt{cov_pese} && -s $opt{cov_pese} && $opt{cov_pe} && -s $opt{cov_pe} && $opt{fa} && -s $opt{fa}) || 
die "Name: $0
Description: Script for find and split chimers   
Version: v1.0
Date: 2016年 05月 11日 星期三 19:03:48 CST
Connector: lindan[AT]novogene.com
Usage1: perl $0 
        
        *-check    [str]  check info after flex win
        *-cov_pese [str]  input mean cov table for PESE
        *-cov_pe   [str]  input mean cov table for PE
        *-fa       [str]  input original fa for chimera split
        --prefix   [str]  ouput prefix,default=output

        the output files:
        prefix.chimera.split.fa        the fasta file after chimera split
        prefix.split.point.xls         Contig ID\\tStart\\tLength\\n
        prefix.check.point.xls         head\\tMeanCov_PESE\\tMeanCov_PE\\tCheck Point\\n
        prefix.chimera.split.fa.len    after chimera split, the length info
\n";

#[split.info]: ori id and chimera subid.
#[split.subid.record]: split behind these ori subids.
#chimeraSplit_check.info: split related ori subids.

my %contig2meancov;
open(OR,"$opt{cov_pese}");
while (<OR>) {
    chomp;
    my@or=split/\t/;
    $contig2meancov{$or[0]}{PESE}=$or[1];
}
close OR;
open(OR,"$opt{cov_pe}");
while (<OR>) {
    chomp;
    my@or=split/\t/;
    $contig2meancov{$or[0]}{PE}=$or[1];
}
close OR;

my (%pese, %pe);
open (IN, "$opt{check}");
<IN>;
while(<IN>){
    chomp;
    my ($ori_id, $id,$end) = (split/\s+/, $_)[0,1,5];
    my $dep1=$contig2meancov{$id}{PESE};
    my $dep2=$contig2meancov{$id}{PE};
    if($id =~ /.*\_\_([0-9]+)$/){
        my $rank = $1;  #get subid;
        push @{$pese{$ori_id}{$rank}}, ($dep1,$end);  #save dep and len of every subid;
        push @{$pe{$ori_id}{$rank}}, ($dep2,$end);
    }
}
close IN;

#step1, check cut point from coverage
my %cut_point;
check_cutpoint(\%pese,);
check_cutpoint(\%pe,);


#step2, get non rundant check point from pese and pe
my %check2split;
foreach my $id(keys %cut_point){
    my @ranks = @{$cut_point{$id}};
    my (%h_subid,@new_ranks);
    foreach my $i(0..$#ranks){
        if(not exists $h_subid{${$ranks[$i]}[0]}){
            $h_subid{${$ranks[$i]}[0]} = 1; 
            push @new_ranks, [${$ranks[$i]}[0], ${$ranks[$i]}[1]];
            $check2split{$id}{${$ranks[$i]}[0]}=1;
        }
        else{
            next;
        }
    }
    @new_ranks = sort {$a->[0] <=> $b->[0]} @new_ranks;
    @{$cut_point{$id}} = @new_ranks;
}


#step3, output split point if exists
open(STAT,">$opt{prefix}.check.point.xls");
open (IN, "$opt{check}");
my $head=<IN>;chomp$head;
print STAT "$head\tMeanCov_PESE\tMeanCov_PE\tCheck Point\n";
while(<IN>){
    chomp;
    my ($ori_id, $id) = (split/\s+/, $_)[0,1];
    my $rank = $1 if($id =~ /.*\_\_([0-9]+)$/);
    $rank && $check2split{$ori_id}{$rank} ? 
    print STAT "$_\t$contig2meancov{$id}{PESE}\t$contig2meancov{$id}{PE}\t*\n" : 
    print STAT "$_\t$contig2meancov{$id}{PESE}\t$contig2meancov{$id}{PE}\t\n";
}
close IN;
close STAT;


#step4, get cut start and length from %cut_point
open(CUT,">$opt{prefix}.split.point.xls");
my %cutfa2point;
print CUT "Contig ID\tStart\tLength\n";
foreach my $id(sort keys %cut_point){
    my @ranks = @{$cut_point{$id}};
    my $start=0;
    my $len = ${$ranks[0]}[1];
    print CUT "$id\t$start\t$len\n";
    push @{$cutfa2point{$id}}, [$start,$len]; 
    foreach my $i(1..$#ranks){
        $start = ${$ranks[$i-1]}[1];
        $len = ${$ranks[$i]}[1] - ${$ranks[$i-1]}[1]; 
        push @{$cutfa2point{$id}}, [$start,$len]; 
        print CUT "$id\t$start\t$len\n";
    }
    print CUT "$id\t${$ranks[-1]}[1]\n";
    push @{$cutfa2point{$id}}, [${$ranks[-1]}[1]]; 
}
close CUT;


#step5, cut original fa from cutfa2point
open (IN, "$opt{fa}");
open (FA,">$opt{prefix}.chimera.split.fa");
open (LEN,">$opt{prefix}.chimera.split.fa.len");
$/ = "\n>";
while (my $seq=<IN>) {
    chomp$seq;
    $seq=~s/^>//;
    my $id=$1 if $seq=~/^(\S+)/;
    $seq=~s/^.*//;
    $seq=~s/\s+//g;
    my $suffix=1;
    if ($cutfa2point{$id}) {
        foreach my $rank (0..$#{$cutfa2point{$id}}){
            my $seq_split;
            if(${${$cutfa2point{$id}}[$rank]}[1]){
                $seq_split=substr($seq,${${$cutfa2point{$id}}[$rank]}[0],${${$cutfa2point{$id}}[$rank]}[1]);
            }else{
                $seq_split=substr($seq,${${$cutfa2point{$id}}[$rank]}[0]);
            }
            $seq_split = &seqformat($seq_split);
            print FA ">$id\_\_$suffix\n$seq_split";
            print LEN "$id\_\_$suffix\t".length($seq_split)."\n";
            $suffix++;
        }
    }else{
        $seq = &seqformat($seq);
        print FA ">$id\n$seq";
        print LEN "$id\t".length($seq)."\n";
    }
}
close IN;
close FA;
close LEN;







sub min(){
    my $n1 = shift;
    my $n2 = shift;
    my $n = ($n1<=$n2)?$n1:$n2;
}

sub check_cutpoint{
    my($hash,)=@_;
    foreach my $id(keys %$hash){ #iterate every id
        my @ranks = keys %{${$hash}{$id}};
        @ranks = sort { $a <=> $b } @ranks;
        if($#ranks>0){
            foreach my $r (0..$#ranks-1){  # iterate every subid and compare its dep difference with its next subid.
                my $abs = abs(${${$hash}{$id}{$ranks[$r]}}[0]-${${$hash}{$id}{$ranks[$r+1]}}[0]);
                my $min = &min(${${$hash}{$id}{$ranks[$r]}}[0], ${${$hash}{$id}{$ranks[$r+1]}}[0]);
                if($min == 0){ $min += 0.0001;}
                if($abs/$min>=0.75){
                    push @{$cut_point{$id}}, [$ranks[$r], ${${$hash}{$id}{$ranks[$r]}}[1]]; #if the dep diffrence is significant, save the index and length of the former subid. 
                }
             }    
        }  
    }
}

sub seqformat() {
    my ($seq) = @_;
    $seq =~ s/(.{1,100})/$1\n/g;
    chomp $seq;
    return $seq;
}
