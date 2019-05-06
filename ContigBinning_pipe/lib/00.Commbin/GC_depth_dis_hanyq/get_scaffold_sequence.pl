#!/usr/bin/perl
use strict;
use warnings;

die"Name:get_scaffold_sequence.pl
Description: script to use the ID of scaffold under one dir  to get scaffold sequence
version: 1.0, Date:2014-08-08
Connect: hanyuqiao\@novogene.cn
Usage: perl get_scaffold_sequence.pl  <cluster_file/> <referance fatat file>
       --<cluster_file/>    this dir name is unique,can not change;in which there are files of scaffold IDs
example��perl $0 /PROJ/MICRO/hanyuqiao/gc/mygc_test/06gc/cluster_file ./02.Assembly/S28/fill/all.scafSeq.fna

" if(!$ARGV[1]);

my $dir = $ARGV[0];#�Ѿ��ֺ����scaffold�ļ�·��
die "$dir do not exist! \n" if (!(-d $dir) );
my @files = `ls $dir`;##����

my $seq_file = $ARGV[1];#scaffold�����ļ�
$dir=~s/\/$//;
#########################�������е�����
foreach my $file(@files) {
    if($file =~ /\.seq$/){
        `rm -rf $file`;
#print $file."\n";
        next;
    };
    open SCAF, "<$seq_file" ||die "can not open sequence file :$!";
	chomp $file;#!!!!!
	open FILE, "<$dir\/$file" ||die "$dir\/$file $!\n";
	my @scaf_name;#����ÿ���ļ���scaffold���ƣ����ں���ƥ��
	while(my $line=<FILE>){
		chomp $line;
		push @scaf_name, $line;
    }

    close FILE;#�ļ�û���ˣ������Ѿ�������������
	############################ƥ����������
	open OUT, ">","$dir/$file.seq"||die $!;#�½��ļ�

    $/=">";<SCAF>;
	while(my $line1 = <SCAF>){#��ȡ�����ļ���һ�У��ж��Ƿ�Ϊ������
        chomp $line1;
        my $id =$1 if( $line1=~/^(\S+)/);
		foreach my $i(0..$#scaf_name) {#�������飬�ж������Ƿ�һ��
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


