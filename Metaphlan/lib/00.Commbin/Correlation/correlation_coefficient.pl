#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt;
GetOptions(\%opt,"spearmen","rank","rank2","list:s","Rcutoff:f","matrix:s");
(@ARGV && ($opt{list} || $opt{matrix})) || die"Name: correlation_coefficient.pl
Description: script to Pearsion or Spearmen caculate correlation coefficient
Version: 1.0, Date: 2015-07-03
Author: Wenbin Liu, liuwenbin\@novogene.cn
Usage: perl correlation_coefficient.pl <input1.table> [input2.table] [--options]
    input1.table <file>         input table one, the first row and rank to be head sign
    input2.table <file>         input talbe two, default=input1.table
    --spearmen                  to caculate Spearmen corelation coefficient(SCC), defualt for Pearsion(PCC)
    --rank                      to get input1.table vector(vector1s) form ranks, default from rows(one row one vector)
    --rank2                     to get input2.table vector(vector2s) form ranks, default from rows(one row one vector)
    --list <str>                set outfile name, the output form: vector1 vector2 Rvalue
    --Rcutoff <flo>             to set R absolute value cutoff, default not set
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
get_data($table1,\$data1,\$base1,\$name1,$opt{rank},$opt{spearmen},\%nameh);#sub1
if($table2){
    get_data($table2,\$data2,\$base2,\$name2,$opt{rank2},$opt{spearmen},\%nameh,1);#sub1
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
            $R = speamenR($data1->[$i],$base1->[$i],$data2->[$j],$base2->[$j],$N);#sub2
            $opt{matrix} && ($data[$i]->[$j] = $R);
            if($opt{list}){
                ($opt{Rcutoff} && abs($R) < $opt{Rcutoff}) && next;
                print LS join("\t",$name1->[$i],$name2->[$j],$R),"\n";
            }
        }elsif($i == $j){
            $opt{matrix} && ($data[$i]->[$j] = 1);
        }elsif($i < $j){
            $R = speamenR($data1->[$i],$base1->[$i],$data2->[$j],$base2->[$j],$N);#sub2
            $opt{matrix} && ($data[$i]->[$j] = $R, $data[$j]->[$i] = $R);
            if($opt{list}){
                ($opt{Rcutoff} && abs($R) < $opt{Rcutoff}) && next;
                print LS join("\t",$name1->[$i],$name2->[$j],$R),"\n";
            }
        }
    }
}
$opt{list} && close(LS);
### output matrix
if($opt{matrix}){
    open MA,">$opt{matrix}" || die$!;
    print MA join("\t","",@{$name2}),"\n";
    for my $i (0..$#data){
        print MA join("\t",$name1->[$i],@{$data[$i]}),"\n";
    }
    close MA;
}

#=======================================================================================
#sub1
#============
sub get_data
#============
{
    my ($table,$data,$base,$name,$rank,$spearmen,$nameh,$check) = @_;
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
            for my $j (0..$#l){
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
        $spearmen && rank_change($_);#sub1.1
        push @{$$base},[base_stat($_)];#sub1.2
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
