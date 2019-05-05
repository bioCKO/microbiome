#!/usr/bin/perl -w
##!/PROJ/GR/share/Software/perl/bin/perl -w
use strict;
use PerlIO::gzip;
use Getopt::Long;
my ($stat_lv,$coutf,$soutf,$cutl,$mark,$o_contig,$rgroup,$prefix);
GetOptions(
        "l:i"=>\$cutl,
        "n:s"=>\$stat_lv,
        "c:s"=>\$coutf,
        "s:s"=>\$soutf,
        "r"=>\$rgroup,
        "a:s"=>\$o_contig,
        "p:s"=>\$prefix,
        "m"=>\$mark
);
#========================================================================================
@ARGV || die"Name: assembly_stat.pl
Describe: to statistics the assemble sequence length information
Author: liuwenbin, liuwenbin\@genomic.org.cn
Version: 1.0, Date: 2011-03-07
Usage: perl assembly_stat.pl <scaffold.fa>  > outstat.tab
    -l <n>       length cout off, default=500
    -n <s>       Nxx% statistic leval, default=50,90
    -a <s>       output all contig, default not out
    -c <s>       set output seq_len>len_cut conting sequence file, default not out
    -s <s>       set output >len_cut scaffold sequence file, default not out
    -r           to regroup scaffold name for -c -s outfile, the longest scaffold to be scaffold1
    -p <s>       new scaffold name prefix to regroup, default=Scaffold
    -m           section mark the number\n\n";
#========================================================================================
my $scaf = shift;
(-s $scaf) || die"error at input file: $scaf, $!";
$stat_lv ||= "50,90";
$cutl ||= 500;
$prefix ||= "Scaffold";
my @slv = (sort {$a<=>$b}(split/,/,$stat_lv));
my @sign = ("Total Num(>$cutl"."bp)","Total Length(bp)");
foreach(@slv){push @sign,"N$_ Length(bp)";}
push @sign,('Max Length(bp)','Min Length(bp)','Sequence GC(%)');
my @sign0 = ("Total Num",@sign[1..$#sign]);
my @size;
my @maxin = &get_length($scaf,$cutl,\@size,$soutf,$coutf,$o_contig,$rgroup);#sub1
my @stat;
foreach(0..3){
    @{$stat[$_]} = &get_Nxx(\@slv,$size[$_]);#sub2 
    push @{$stat[$_]},@maxin[3*$_..3*$_+2];
    if($mark){
        foreach(@{$stat[$_]}[0..$#sign-1]){&add_comm($_);}#sub3
    }
}
my ($oout,$fout);
foreach my $i(0..$#sign){
    $fout .= join("\t",$sign[$i],$stat[0]->[$i],$stat[1]->[$i]) . "\n";
    $oout .= join("\t",$sign0[$i],$stat[2]->[$i],$stat[3]->[$i]) . "\n";
}
print "\t\tScaffold\tContig\n$oout\n\t\tScaffold\tContig\n$fout";

#========================================================================================
#sub1
sub get_length{
    my ($scaf,$cutl,$size,$soutf,$coutf,$a_contig,$rgroup) = @_;
    ($scaf=~/\.gz$/) ? (open(IN,"<:gzip",$scaf) || die$!) : (open IN,$scaf || die$!);
    $/=">";<IN>;$/="\n";
    my (@gc, @at);
    $soutf && (open SO,">$soutf" || die$!);
    $coutf && (open CO,">$coutf" || die$!);
    $a_contig && (open AO,">$a_contig" || die$!);
    my (@s_seq,%c_seq);
    while(<IN>){
        /^(\S+)/ || next;
        my $id = $1;
        $/=">";
        chomp(my $seq = <IN>);
        $/="\n";
        $seq =~ s/\s+//g;
        my $len = length($seq);
        my $n = ($len >= $cutl) ? 0 : 2;
        push @{$size->[$n]},$len;
        &get_gc_at(\$gc[$n],\$at[$n],$seq);
        if(!$n && $soutf){
           $rgroup ? (push @s_seq,[$len,$id,$seq]) : (print SO ">$id\n$seq\n");
        }
        $seq =~ s/^[nN]+|[nN]+$//;
        my $i = 0;
        foreach my $subseq(split/[nN]+/,$seq){
            $i++;
            $a_contig && (print AO ">$id\_$i\n$subseq\n");
            my $s_len = length($subseq);
#            $n = ($s_len > $cutl) ? 1 : 3;
#            push @{$size->[$n]},$s_len;
            push @{$size->[$n+1]},$s_len;
            &get_gc_at(\$gc[$n+1],\$at[$n+1],$subseq);
            if(!$n && $coutf){
               $rgroup ? (push @{$c_seq{$id}},[$i,$subseq]) : (print CO ">$id\_$i\n$subseq\n");
            }
        }
    }
    close IN;
    if($rgroup && @s_seq){
        my $i = 0;
        @s_seq = sort {$b->[0] <=> $a->[0]} @s_seq;
        my (@idh,%idh);
        foreach(@s_seq){
            $i++;
            my $id = $prefix . $i;
            $idh{$_->[1]} || (push @idh,$_->[1]);
            $idh{$_->[1]} = $id;
            print SO ">$id\n",$_->[2],"\n";
        }
        foreach my $id(@idh){
            foreach (@{$c_seq{$id}}){
                print CO ">$idh{$id}\_$_->[0]\n",$_->[1],"\n";
            }
        }
    }
    $soutf && close(SO);
    $coutf && close(CO);
    $a_contig && close(AO);
    foreach(@gc,@at){$_||=0;}
    $size->[1] && (unshift @{$size->[3]},@{$size->[1]});
    foreach(@{$size}){
        #@{$_} || next;
        $_ || next;
        @{$_} = (sort {$b<=>$a} @{$_});
    }
    $size->[0] && (unshift @{$size->[2]},@{$size->[0]});
    my (@len, @out);
    foreach(0..3){
        $len[$_] = ($gc[$_] ||= 0) + ($at[$_] ||= 0);
        ($_ > 1) && ($len[$_] += $len[$_-2], $gc[$_] += $gc[$_-2]);
        push @out,(@{$size->[$_]}[0,-1], $len[$_] ? int(10000*$gc[$_]/$len[$_])/100 : 0);
    }
    @out;
}

#sub1.1
sub get_gc_at{
    my ($gc,$at,$seq) = @_;
    $$gc += ($seq =~ s/[GC]//ig);
    $$at += ($seq =~ s/[AT]//ig);
}
#sub2.1
sub sum
{
	my $sum_cur = 0;
	foreach(@_){
		$sum_cur += $_;
	}
	$sum_cur;
}
#sub2
sub get_Nxx{
    my ($lv,$size) = @_;
    my $total = &sum(@$size);
    my ($i,$cur_leng) = (-1, 0);
    my @out = ($#$size+1,$total);
    foreach my $rate(@$lv){
        my $tar_leng = $total * $rate /100;
        until(($cur_leng > $tar_leng) || ($i == $#$size)){
            $i++;
            $cur_leng += $size->[$i];
        }
        push @out,$size->[$i];
    }
    @out;
}
#sub3
sub add_comm{
    my $str = reverse $_[0];
    $str =~ s/(...)/$1,/g;
    $str =~ s/,$//;
    $_[0] = reverse $str;
}
