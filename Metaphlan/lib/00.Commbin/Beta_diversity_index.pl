#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt = (index=>"PCC");
GetOptions(\%opt,"spearmen","rank","rank2","list:s","cutoff:f","matrix:s","index:s","renormal:f");
(@ARGV && ($opt{list} || $opt{matrix})) || die"Name: Beta_diversity_index.pl
Description: script to caculate Beta diversity index: 
    Pearsion corelation coefficient (PCC)
    Spearmen corelation coefficient (SCC)
    Jensen-Shannon divergence square root (JSD)
    Bray-Curtis distance (BCD)
Version: 1.0, Date: 2015-07-03
Author: Wenbin Liu, liuwenbin\@novogene.cn
Usage: perl Beta_diversity_index.pl <input1.table> [input2.table] [--options]
    input1.table <file>         input table one, the first row and rank to be head sign
    input2.table <file>         input talbe two, default=input1.table
    --index <str>               select index type: PCC|SCC|JSD|BCD, defual=PCC
    --rank                      to get input1.table vector(vector1s) form ranks, default from rows(one row one vector)
    --rank2                     to get input2.table vector(vector2s) form ranks, default from rows(one row one vector)
    --list <str>                set outfile name, the output form: vector1 vector2 Index
    --cutoff <flo>              set beta diversity index absolute value cutoff for list output, default not set
    --matrix <str>              set outfile name, the output form to be matrix, head rank for vector1s and row for vector2s
Note:
    1. Either --list or --matrix must be set.
    2. The vector in two the input tables can share difference data turn.
\n";
for(@ARGV){(-s $_) || die$!;}
my ($table1,$table2) = @ARGV;
### to get table data into array
my ($data1,$base1,$name1,$data2,$base2,$name2);
my %nameh;
($opt{index} eq "SCC") && ($opt{spearmen} = 1);
($opt{index} eq "JSD") && ($opt{renormal} = 1e-9);
get_data($table1,\$data1,\$base1,\$name1,$opt{rank},$opt{spearmen},$opt{renormal},\%nameh);#sub1
if($table2){
    get_data($table2,\$data2,\$base2,\$name2,$opt{rank2},$opt{spearmen},$opt{renormal},\%nameh,1);#sub1
}else{
    ($data2,$base2,$name2) = ($data1,$base1,$name1);
}
### to caculate the R index
my $N = @{$data1->[0]};
my @data;
$opt{list} && (open LS,">$opt{list}" || die$!);
for my $i(0..$#{$data1}){
    for my $j(0..$#{$data2}){
        my $R;
        if($table2){
            $R = ($opt{index} eq "JSD") ? JSD_index($data1->[$i],$data2->[$j]) :#sub3
                ($opt{index} eq "BCD") ? BCD_index($data1->[$i],$data2->[$j]) :#sub4
                speamenR($data1->[$i],$base1->[$i],$data2->[$j],$base2->[$j],$N);#sub2
            $opt{matrix} && ($data[$i]->[$j] = $R);
            if($opt{list}){
                ($opt{cutoff} && abs($R) < $opt{cutoff}) && next;
                print LS join("\t",$name1->[$i],$name2->[$j],$R),"\n";
            }
        }elsif($i == $j){
            $opt{matrix} && ($data[$i]->[$j] = ($opt{index}=~m/PCC|SCC/) ? 1 : 0);
        }elsif($i < $j){
            $R = ($opt{index} eq "JSD") ? JSD_index($data1->[$i],$data2->[$j]) :#sub3
                ($opt{index} eq "BCD") ? BCD_index($data1->[$i],$data2->[$j]) :#sub4
                speamenR($data1->[$i],$base1->[$i],$data2->[$j],$base2->[$j],$N);#sub2
            $opt{matrix} && ($data[$i]->[$j] = $R, $data[$j]->[$i] = $R);
            if($opt{list}){
                ($opt{cutoff} && abs($R) < $opt{cutoff}) && next;
                print LS join("\t",$name1->[$i],$name2->[$j],$R),"\n";
            }
        }
    }
}
$opt{list} && close(LS);
### output matrix
if($opt{matrix}){
    open MA,">$opt{matrix}" || die$!;
    print MA join("\t","#$opt{index}",@{$name2}),"\n";
    for my $i (0..$#data){
        print MA join("\t",$name1->[$i],@{$data[$i]}),"\n";
    }
    close MA;
}

#=======================================================================================
#sub4
#=============
sub BCD_index
#=============
{
    my ($data1,$data2) = @_;
    my ($bcd,$tol);
    for my $i(0..$#$data1){
        my ($x,$y) = ($data1->[$i], $data2->[$i]);
        $bcd += $x < $y ? $x : $y;
        $tol += $x+$y;
    }
    $tol ? 1-2*$bcd/$tol : 0;
}
#sub3
#=============
sub JSD_index
#=============
{
    my ($data1,$data2) = @_;
    my $jsd = 0;
    for my $i(0..$#$data1){
        my ($x,$y) = ($data1->[$i], $data2->[$i]);
        my $m = ($x+$y) / 2;
        $jsd += $x*log($x/$m)+$y*log($y/$m);
    }
    sqrt($jsd/log(10)/2);
}
#sub1
#============
sub get_data
#============
{
    my ($table,$data,$base,$name,$rank,$spearmen,$renormal,$nameh,$check) = @_;
    my $i = 0;
    open IN,$table || die$!;
    chomp(my $head = <IN>);
    my @heads = ($head =~ /\t/) ? split/\t/,$head : split/\s+/,$head;
    shift @heads;
    if($rank){
        @{$$name} = @heads;
        while(<IN>){
            my @l = /\t/ ? split /\t/ : split;
            my $item = shift @l;
            if($check){
                defined $nameh->{$item} || next;
                $i = $nameh->{$item};
            }else{
                $nameh->{$item} = $i;
            }
            for my $j (0..$#heads){
                ${$$data}[$j]->[$i] = $l[$j];
            }
            $i++;
        }
    }else{
        my @change;
        for my $j (0..$#heads){
            if($check){
                if(defined $nameh->{$heads[$j]}){
                    $change[$nameh->{$heads[$j]}] = $j;
                }
            }else{
                $nameh->{$heads[$j]} = $j;
            }
        }
        while(<IN>){
            my @l = /\t/ ? split /\t/ : split;
            my $item = shift @l;
            if($check){
                @l = @l[@change];
            }
            push @{$$name},$item;
            push @{$$data},[@l];
        }
    }
    close IN;
    for(@{$$data}){
        $renormal && Renormal($_,$renormal);
        $spearmen && rank_change($_);#sub1.1
        push @{$$base},[base_stat($_)];#sub1.2
    }
}
#sub1.3
#===========
sub Renormal
#===========
{
    my ($data,$renormal) = @_;
    my $tol = 0;
    for(@{$data}){
        $_ ||= $renormal;
        $tol += $_;
    }
    for(@{$data}){
        $_ /= $tol;
    }
}
#sub1.1
#==============
sub base_stat
#==============
{
    my ($arr) = @_;
    my ($sum,$sum2) = (0, 0);
    for(@$arr){
        $sum += $_;
        $sum2 += $_**2;
    }
    my $N = @$arr;
    ($sum,sqrt($N*$sum2-$sum**2));
}
#sub1.2
#===============
sub rank_change
#===============
{
    my $arr = shift;
    my @arrs;
    my $i = 0;
    for (@$arr){
        push @arrs,[$_,++$i];
    }
    for (sort {$b->[0] <=> $a->[0]} @arrs){
        push @{$_},$i--;
    }
    for (sort {$a->[0] <=> $b->[0]} @arrs){
        push @{$_},++$i;
    }
    @$arr = ();
    for (sort {$a->[1] <=> $b->[1]} @arrs){
        push @$arr,($_->[2]+$_->[3])/2;
    }
}
#sub2
#============
sub speamenR
#===========
{
    my ($arr1,$stat1,$arr2,$stat2,$N) = @_;
    my $dis = 0;
    for my $i(0..$#$arr1){
        $dis += ($arr1->[$i]*$arr2->[$i]);
    }
    sprintf("%.3f",($N*$dis-$stat1->[0]*$stat2->[0]) / $stat1->[1] / $stat2->[1] );
}
