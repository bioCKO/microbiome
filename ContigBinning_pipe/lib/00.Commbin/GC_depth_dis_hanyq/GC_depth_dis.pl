#!/usr/bin/perl
# Copyright 2010 Lizhi Xu <xulz@genomics.cn>
use strict;
use warnings;
use PerlIO::gzip;
use FindBin qw($Bin);
use Getopt::Long;#处理命令行选项
#my %opt = (windl=> 500, movel => 500);#默认窗口长度为500，移动步长为500，但是可以改变

my %opt = (windl=> 1000, movel => 1000);#默认窗口长度为500，移动步长为500，但是可以改变
GetOptions(\%opt, "outdir:s", "windl:i", "movel:i", "gc_range:s", "dep_cut:i","prefix:s","cluster:i");
##=========================================================================================
(@ARGV==2) || die"Name: GC_depth_dis.pl
Description: script to draw GC-depth with sequence file and soap.coverage result.
Version: 1.0,  Date: 2014-08-08
Connect: hanyuqiao\@novogene.cn
Usage: perl GC_depth_dis.pl <ref.fa> <cover_depf>
    ref.fa              referance fatat file, gzip is allowed
    cover_depf          soap.coveage -depthsingle outfile, gzip is allowed
    --outdir <dir>      outfile directoty, default=./
    --prefix <str>      outfile prefix, default not set
    --windl <num>       windows length, default=500
    --movel <num>       windows move length, default= --windl set
    --gc_range <str>    GC% range show, min:max(e.g 0:100), negative means auto, default='-1,-1'
    --dep_cut <num>     maxdepth to show at the figure, negative means auto, default='-1'
    --cluster <num>     dot clusert number, default=5\n\n

Needed perl files in your work dir:GC_depth_dis.pl gc_depth_R.pl  get_scaffold_sequence.pl 
Example: perl GC_depth_dis.pl ./02.Assembly/S28/fill/all.scafSeq.fna  ./02.Assembly/S28/evaluate/02.Coverage/soap.coverage.depthsingle   --gc_range 0,100 --dep_cut 400 
\n\n ";

##=========================================================================================
(-s "$Bin/gc_depth_R.pl") || die"error can't find gc_depth_R.pl at $Bin, $!\n";
(-s "$Bin/get_scaffold_sequence.pl") ||die"error can't find get_scaffold_sequence.pl at $Bin,$!\n";
foreach(@ARGV){
    (-s $_ || -s "$_.gz") || die"error: can't find valid file $_, $!\n";#-s文件或目录存在而且有内容
    !(-s $_) && (-s "$_.gz") && ($_ .= ".gz");
}
my ($ref,$covf) = @ARGV;
my @outf = ("GC_depth.pos","GC_depth.pos.pdf","GC_depth.pos.cluster","GC_depth.Scaffold");#获得输出文件3个qiao
$opt{outdir} ||= '.';
(-d $opt{outdir}) || mkdir($opt{outdir});
(-d "$opt{outdir}/cluster_file/") || mkdir("$opt{outdir}/cluster_file/");
foreach(@outf){
    $opt{prefix} && ($_ = $opt{prefix} . '.' . $_);
    $_ = $opt{outdir} . '/' . $_;
}
my %gc_hash;
my $minlen=50;#设置scaffold最小长度为50
&get_gc_list($ref,$opt{windl},$opt{movel},\%gc_hash);#sub1##reg文件其实为fasta文件
my $avg_depth = &get_depth($covf,$opt{windl},$opt{movel},\%gc_hash,$outf[0]);#sub2#输入文件为深度比对结果，输出文件为GC_depth.pos
my $scaf = &get_scafgd($ref,$covf,$minlen,\%gc_hash,$outf[3]);#得到scaffold的gc和depth
system "perl $Bin/gc_depth_R.pl @outf[0,1,3]";
system "perl $Bin/get_scaffold_sequence.pl $opt{outdir}/cluster_file/ $ref";
##=========================================================================================
#sub1
#===============
sub get_gc_list{
#===============
    my ($fasta,$windl,$movel,$gc_hash) = @_;
    ($fasta=~/\.gz$/) ? (open IN,"<:gzip",$fasta || die$!) : (open IN,$fasta || die$!);#文件句柄指向fasta文件
    $/=">";<IN>;$/="\n";#去掉开头的>
    while(<IN>){
        /^(\S+)/ || next;#若以空格开头就继续读取下一行
        my $id = $1;
        $/=">";chomp(my $seq = <IN>);$/="\n";
        $seq =~ s/\s+//g;#去掉所有空格
        my $len = length($seq);
        ($len < $windl) && next;#若序列长度小于窗口长度，则读取下一行
        my $j = -1;
        for (my $i = 0; $i <= $len - $windl; $i += $movel){#从0开始，挪动窗口
            $j++;#窗口编号
            my $subseq = substr($seq,$i,$windl);#获得一个窗口的序列
            my @gl = &get_gc($subseq);#sub1.1#获得一个窗口的(gc百分比，不为N的序列长度)
            $gl[1] || next;#序列长度(gl[1])不为0才继续
            $gc_hash->{"$id $j"} = [@gl];#返回id和窗口编号，以及gc百分比和序列长度？？？？
        }
    }
    close IN;
}
#sub1.1
#==========
sub get_gc{#获得一个gc百分比和序列长度
#==========
	my $seq = shift;
	$seq =~ s/N//ig;
    $seq || return(0,0);
	my $len = length $seq;
	my $gc = ($seq =~ s/[GC]//ig);#神奇的获得gc含量，替换？？？？
    (int($gc/$len*10000)/100, $len);
}
#sub2
#=============
sub get_depth{#输出到文件GC_depth.pos，ovf记录了序列的深度
#=============
    my ($covf,$windl,$movel,$gc_hash,$outf) = @_;
    my ($ln, $outl) = (0);
    my ($avg_depth, $win_num) = (0, 0);#平均长度和窗口号为0
    open OUT,">$outf" || die $!;
    ($covf=~/\.gz$/) ? (open IN,"<:gzip",$covf || die$!) : (open IN,$covf || die$!);#从covf中读取数据
    $/=">";<IN>;$/="\n";
    while(<IN>){	
        /^(\S+)/ || next;
        my $id = $1;#获得序列id
        $/=">";chomp(my $seq_str = <IN>);$/="\n";
        my @seq = split/\s+/,$seq_str;#获得深度的序列，为数字，记录了每个碱基的深度！！！？？
        my $j = -1;#记录窗口编号
        for (my $i = 0; $i < $#seq - $windl + 2; $i += $movel){
            $j++;#一个scaffold的窗口数-1
            $gc_hash->{"$id $j"} || next;#scaffold和窗口都已经存在，才继续下一步
            my @gl = @{$gc_hash->{"$id $j"}};
            my $depth = &sum(@seq[$i..$i+$windl-1]);#一个窗口中的序列深度相加
            $depth = int(100*$depth/$gl[1])/100;#获得一个窗口的序列的平均深度，gl[1]为出去N的一个窗口的碱基和
            $avg_depth += $depth;#ava_depth为全局变量，记录所有scaffold窗口的平均深度之和
            $win_num++;#win_num记录所有scaffold窗口数
            $outl .= join("\t",$id,$j,$gl[0],$depth)."\n";#输出，id,窗口号，此窗口的gc含量，平均序列深度
            $ln++;#记录所有scaffold的行数，够30行，输出一次
            ($ln>=30) && ($ln=0,(print OUT $outl),$outl="");#每30行输出一次，ln=0？？？
        }
		

    }
    close IN;
    $ln && (print OUT $outl);#如果ln不足30，但是还有行数，则输出到GC_depth.pos
    close OUT;
    $win_num ? int($avg_depth/$win_num+0.5) : 0;#貌似记录一个输出文件的平均深度。
}
#sub2.1
#=======
sub sum{
#=======
    my $sum = 0;
    foreach(@_){$sum+=$_;}
    $sum;
}

##=========================================================================================
#sub3 hanyuqiao整合sub1与sub2
#===============

sub get_scafgd{ #获得每个scaffold的gc含量和depth，输出到文件GC_avedep.pos，ovf记录了序列的深度
#=============
#获得gc含量
    my ($fasta,$covf,$minlen,$gc_hash,$outf) = @_;#获得两个输入文件，一个输出文件,若scaffold小于最小长度，则忽略
   
    open OUT,">$outf" || die $!;
    ($fasta=~/\.gz$/) ? (open IN,"<:gzip",$fasta || die$!) : (open IN,$fasta || die$!);#文件句柄指向fasta文件
    $/=">";<IN>;$/="\n";#去掉开头的>
    while(<IN>){#处理含有scaffold名称的行
        /^(\S+)/ || next;#若以空格开头就继续读取下一行
        my $id = $1;
        $/=">";chomp(my $seq = <IN>);$/="\n";#读取序列内容
        $seq =~ s/\s+//g;#去掉所有空格
        my $len = length($seq);
        ($len < $minlen) && next;#若序列长度小于一定长度则忽略不计算，取下一行
        my @gl = &get_gc($seq);#sub1.1#获得一个scaffold的(gc百分比，不为N的序列长度)
        $gl[1] || next;#scaffold序列长度(gl[1])不为0才继续，有可能都是N，又检查一遍
        $gc_hash->{"$id"} = [@gl,$len];#返回id以及gc百分比？？？？problem
        
    }
    close IN;

#获得depth

    ($covf=~/\.gz$/) ? (open IN,"<:gzip",$covf || die$!) : (open IN,$covf || die$!);#从covf中读取数据
    $/=">";<IN>;$/="\n";
    my $ln = 0;#30行输出一次
    my $outl = "";#输出结果暂存
    while(<IN>){	
        /^(\S+)/ || next;
        my $id = $1;#获得序列id
        $/=">";chomp(my $seq_str = <IN>);$/="\n";
        my @seq = split/\s+/,$seq_str;#获得深度的序列，为数字，记录了每个碱基的深度！！！？？
	    $gc_hash->{"$id"} || next;#scaffold已经存在，才继续下一步
	    my @gl = @{$gc_hash->{"$id"}};
	    my $sgc = $gl[0];#记录了gc含量
        my $depth = &sum(@seq[0..$#seq]);#一个scaffold中的序列深度相加，qiao
	    $depth = int(100*$depth/$gl[1])/100;
		my $len = $gc_hash->{"$id"}->[1];#scaffold的长度
        $outl .= join("\t",$id,$len,$sgc,$depth)."\n";  #输出,id,窗口号，此窗口的gc含量，平均序列深度
        $ln++;#记录所有scaffold的行数，够30行，输出一次
        ($ln>=30) && ($ln=0,(print OUT $outl),$outl="");#每30行输出一次，ln=0？？？
    }
    close IN;
    $ln && (print OUT $outl);#如果ln不足30，但是还有行数，则输出到GC_depth.pos
    close OUT;
    #$win_num ? int($avg_depth/$win_num+0.5) : 0;#貌似记录一个输出文件的平均深度。
}
