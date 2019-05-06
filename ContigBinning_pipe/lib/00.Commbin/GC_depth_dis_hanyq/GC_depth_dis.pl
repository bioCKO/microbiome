#!/usr/bin/perl
# Copyright 2010 Lizhi Xu <xulz@genomics.cn>
use strict;
use warnings;
use PerlIO::gzip;
use FindBin qw($Bin);
use Getopt::Long;#����������ѡ��
#my %opt = (windl=> 500, movel => 500);#Ĭ�ϴ��ڳ���Ϊ500���ƶ�����Ϊ500�����ǿ��Ըı�

my %opt = (windl=> 1000, movel => 1000);#Ĭ�ϴ��ڳ���Ϊ500���ƶ�����Ϊ500�����ǿ��Ըı�
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
    (-s $_ || -s "$_.gz") || die"error: can't find valid file $_, $!\n";#-s�ļ���Ŀ¼���ڶ���������
    !(-s $_) && (-s "$_.gz") && ($_ .= ".gz");
}
my ($ref,$covf) = @ARGV;
my @outf = ("GC_depth.pos","GC_depth.pos.pdf","GC_depth.pos.cluster","GC_depth.Scaffold");#�������ļ�3��qiao
$opt{outdir} ||= '.';
(-d $opt{outdir}) || mkdir($opt{outdir});
(-d "$opt{outdir}/cluster_file/") || mkdir("$opt{outdir}/cluster_file/");
foreach(@outf){
    $opt{prefix} && ($_ = $opt{prefix} . '.' . $_);
    $_ = $opt{outdir} . '/' . $_;
}
my %gc_hash;
my $minlen=50;#����scaffold��С����Ϊ50
&get_gc_list($ref,$opt{windl},$opt{movel},\%gc_hash);#sub1##reg�ļ���ʵΪfasta�ļ�
my $avg_depth = &get_depth($covf,$opt{windl},$opt{movel},\%gc_hash,$outf[0]);#sub2#�����ļ�Ϊ��ȱȶԽ��������ļ�ΪGC_depth.pos
my $scaf = &get_scafgd($ref,$covf,$minlen,\%gc_hash,$outf[3]);#�õ�scaffold��gc��depth
system "perl $Bin/gc_depth_R.pl @outf[0,1,3]";
system "perl $Bin/get_scaffold_sequence.pl $opt{outdir}/cluster_file/ $ref";
##=========================================================================================
#sub1
#===============
sub get_gc_list{
#===============
    my ($fasta,$windl,$movel,$gc_hash) = @_;
    ($fasta=~/\.gz$/) ? (open IN,"<:gzip",$fasta || die$!) : (open IN,$fasta || die$!);#�ļ����ָ��fasta�ļ�
    $/=">";<IN>;$/="\n";#ȥ����ͷ��>
    while(<IN>){
        /^(\S+)/ || next;#���Կո�ͷ�ͼ�����ȡ��һ��
        my $id = $1;
        $/=">";chomp(my $seq = <IN>);$/="\n";
        $seq =~ s/\s+//g;#ȥ�����пո�
        my $len = length($seq);
        ($len < $windl) && next;#�����г���С�ڴ��ڳ��ȣ����ȡ��һ��
        my $j = -1;
        for (my $i = 0; $i <= $len - $windl; $i += $movel){#��0��ʼ��Ų������
            $j++;#���ڱ��
            my $subseq = substr($seq,$i,$windl);#���һ�����ڵ�����
            my @gl = &get_gc($subseq);#sub1.1#���һ�����ڵ�(gc�ٷֱȣ���ΪN�����г���)
            $gl[1] || next;#���г���(gl[1])��Ϊ0�ż���
            $gc_hash->{"$id $j"} = [@gl];#����id�ʹ��ڱ�ţ��Լ�gc�ٷֱȺ����г��ȣ�������
        }
    }
    close IN;
}
#sub1.1
#==========
sub get_gc{#���һ��gc�ٷֱȺ����г���
#==========
	my $seq = shift;
	$seq =~ s/N//ig;
    $seq || return(0,0);
	my $len = length $seq;
	my $gc = ($seq =~ s/[GC]//ig);#����Ļ��gc�������滻��������
    (int($gc/$len*10000)/100, $len);
}
#sub2
#=============
sub get_depth{#������ļ�GC_depth.pos��ovf��¼�����е����
#=============
    my ($covf,$windl,$movel,$gc_hash,$outf) = @_;
    my ($ln, $outl) = (0);
    my ($avg_depth, $win_num) = (0, 0);#ƽ�����Ⱥʹ��ں�Ϊ0
    open OUT,">$outf" || die $!;
    ($covf=~/\.gz$/) ? (open IN,"<:gzip",$covf || die$!) : (open IN,$covf || die$!);#��covf�ж�ȡ����
    $/=">";<IN>;$/="\n";
    while(<IN>){	
        /^(\S+)/ || next;
        my $id = $1;#�������id
        $/=">";chomp(my $seq_str = <IN>);$/="\n";
        my @seq = split/\s+/,$seq_str;#�����ȵ����У�Ϊ���֣���¼��ÿ���������ȣ���������
        my $j = -1;#��¼���ڱ��
        for (my $i = 0; $i < $#seq - $windl + 2; $i += $movel){
            $j++;#һ��scaffold�Ĵ�����-1
            $gc_hash->{"$id $j"} || next;#scaffold�ʹ��ڶ��Ѿ����ڣ��ż�����һ��
            my @gl = @{$gc_hash->{"$id $j"}};
            my $depth = &sum(@seq[$i..$i+$windl-1]);#һ�������е�����������
            $depth = int(100*$depth/$gl[1])/100;#���һ�����ڵ����е�ƽ����ȣ�gl[1]Ϊ��ȥN��һ�����ڵļ����
            $avg_depth += $depth;#ava_depthΪȫ�ֱ�������¼����scaffold���ڵ�ƽ�����֮��
            $win_num++;#win_num��¼����scaffold������
            $outl .= join("\t",$id,$j,$gl[0],$depth)."\n";#�����id,���ںţ��˴��ڵ�gc������ƽ���������
            $ln++;#��¼����scaffold����������30�У����һ��
            ($ln>=30) && ($ln=0,(print OUT $outl),$outl="");#ÿ30�����һ�Σ�ln=0������
        }
		

    }
    close IN;
    $ln && (print OUT $outl);#���ln����30�����ǻ����������������GC_depth.pos
    close OUT;
    $win_num ? int($avg_depth/$win_num+0.5) : 0;#ò�Ƽ�¼һ������ļ���ƽ����ȡ�
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
#sub3 hanyuqiao����sub1��sub2
#===============

sub get_scafgd{ #���ÿ��scaffold��gc������depth��������ļ�GC_avedep.pos��ovf��¼�����е����
#=============
#���gc����
    my ($fasta,$covf,$minlen,$gc_hash,$outf) = @_;#������������ļ���һ������ļ�,��scaffoldС����С���ȣ������
   
    open OUT,">$outf" || die $!;
    ($fasta=~/\.gz$/) ? (open IN,"<:gzip",$fasta || die$!) : (open IN,$fasta || die$!);#�ļ����ָ��fasta�ļ�
    $/=">";<IN>;$/="\n";#ȥ����ͷ��>
    while(<IN>){#������scaffold���Ƶ���
        /^(\S+)/ || next;#���Կո�ͷ�ͼ�����ȡ��һ��
        my $id = $1;
        $/=">";chomp(my $seq = <IN>);$/="\n";#��ȡ��������
        $seq =~ s/\s+//g;#ȥ�����пո�
        my $len = length($seq);
        ($len < $minlen) && next;#�����г���С��һ����������Բ����㣬ȡ��һ��
        my @gl = &get_gc($seq);#sub1.1#���һ��scaffold��(gc�ٷֱȣ���ΪN�����г���)
        $gl[1] || next;#scaffold���г���(gl[1])��Ϊ0�ż������п��ܶ���N���ּ��һ��
        $gc_hash->{"$id"} = [@gl,$len];#����id�Լ�gc�ٷֱȣ�������problem
        
    }
    close IN;

#���depth

    ($covf=~/\.gz$/) ? (open IN,"<:gzip",$covf || die$!) : (open IN,$covf || die$!);#��covf�ж�ȡ����
    $/=">";<IN>;$/="\n";
    my $ln = 0;#30�����һ��
    my $outl = "";#�������ݴ�
    while(<IN>){	
        /^(\S+)/ || next;
        my $id = $1;#�������id
        $/=">";chomp(my $seq_str = <IN>);$/="\n";
        my @seq = split/\s+/,$seq_str;#�����ȵ����У�Ϊ���֣���¼��ÿ���������ȣ���������
	    $gc_hash->{"$id"} || next;#scaffold�Ѿ����ڣ��ż�����һ��
	    my @gl = @{$gc_hash->{"$id"}};
	    my $sgc = $gl[0];#��¼��gc����
        my $depth = &sum(@seq[0..$#seq]);#һ��scaffold�е����������ӣ�qiao
	    $depth = int(100*$depth/$gl[1])/100;
		my $len = $gc_hash->{"$id"}->[1];#scaffold�ĳ���
        $outl .= join("\t",$id,$len,$sgc,$depth)."\n";  #���,id,���ںţ��˴��ڵ�gc������ƽ���������
        $ln++;#��¼����scaffold����������30�У����һ��
        ($ln>=30) && ($ln=0,(print OUT $outl),$outl="");#ÿ30�����һ�Σ�ln=0������
    }
    close IN;
    $ln && (print OUT $outl);#���ln����30�����ǻ����������������GC_depth.pos
    close OUT;
    #$win_num ? int($avg_depth/$win_num+0.5) : 0;#ò�Ƽ�¼һ������ļ���ƽ����ȡ�
}
