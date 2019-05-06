#!/usr/bin/perl
use strict;
use warnings;

die"Name:get_scaffold_sequence.pl
Description: script to use the ID of scaffold under one dir  to get scaffold sequence
version: 1.0, Date:2014-08-08
Connect: hanyuqiao\@novogene.cn
Usage: perl get_scaffold_sequence.pl  <cluster_file/> <referance fatat file>
       --<cluster_file/>    this dir name is unique,can not change;in which there are files of scaffold IDs
example：perl $0 /PROJ/MICRO/hanyuqiao/gc/mygc_test/06gc/cluster_file ./02.Assembly/S28/fill/all.scafSeq.fna

" if(!$ARGV[1]);

my $dir = $ARGV[0];#已经分好类的scaffold文件路径
die "$dir do not exist! \n" if (!(-d $dir) );
my @files = `ls $dir`;##技巧

my $seq_file = $ARGV[1];#scaffold序列文件
$dir=~s/\/$//;
#########################分组序列的名字
foreach my $file(@files) {
    if($file =~ /\.seq$/){
        `rm -rf $file`;
#print $file."\n";
        next;
    };
    open SCAF, "<$seq_file" ||die "can not open sequence file :$!";
	chomp $file;#!!!!!
	open FILE, "<$dir\/$file" ||die "$dir\/$file $!\n";
	my @scaf_name;#保存每个文件的scaffold名称，用于后面匹配
	while(my $line=<FILE>){
		chomp $line;
		push @scaf_name, $line;
    }

    close FILE;#文件没用了，名字已经保存在数组中
	############################匹配分组的序列
	open OUT, ">","$dir/$file.seq"||die $!;#新建文件

    $/=">";<SCAF>;
	while(my $line1 = <SCAF>){#读取序列文件的一行，判读是否为序列名
        chomp $line1;
        my $id =$1 if( $line1=~/^(\S+)/);
		foreach my $i(0..$#scaf_name) {#遍历数组，判断名字是否一样
			if($id=~m/^$scaf_name[$i]$/){
                #my $seq=<SCAF>;
                #chomp($seq);
				print OUT ">$line1";
			}
		}
	}

    close SCAF;
    $/="\n";
	close OUT;
    @scaf_name="";
# print "1\n";
}


