#!/usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin); 
use Getopt::Long;
my %opt = (output=>"uniq_table.txt",in_clstr=>"",outdir=>".",c=>"0.9",M=>"2400",n=>"5",cd_opts=>"-c 0.9 -n 5 -M 2400 ",type=>"nt");
GetOptions (\%opt,"output:s","in_clstr:s","step:i","prefix:s","outdir:s","type:s","help:s"); 
#==============================================================================================================================
($opt{in_clstr} && -s $opt{in_clstr}) || die "Name: get_table.pl
Description: Script to get statistic table of unique sequence
Version: 0.1  Date: 2014-11-4
Modified: The bug that falsely output the last row of the table was fixed in 2014-11-11
Contatct: yujinhui[AT]novogene.cn
Usage: perl $0 --in_clstr <.cdhit.clstr> --outdir <workdir> --output <table.txt> [--options]
    --in_clstr <str>        input .clstr file when only run step 2
    --output <str>          output statistic table of unique sequence;default=uniq_table.txt
    --outdir <dir>          set output directory,default=.	

example:
    perl $0 --in_clstr test.fa.cdhit.clstr --outdir workdir --output pro.table.txt 

";
#==============================================================================================================================
(-d $opt{outdir}) || mkdir -p $opt{outdir};
$opt{outdir}=abs_path($opt{outdir});

#=====main======
    
	my $clstr_file=$opt{in_clstr} || die "Erro: .clstr file doesn't exist.";# read .cdhit file
	my $table=$opt{output} || die "Erro: Please input output file name.";
	my(@line,$rep_id,$len,$i,%scaftig);
	$/=">Cluster";
	open (IN,"<$clstr_file");<IN>;
	open (OUT,">$table");
	print OUT "#Rep_id\tLen(nt/aa)\tNum\tSeq_ID\n";
	while (<IN>){
	    chomp;
		my $num=0;
		my $scaf_id="";
		my $cluster=$_;
		@line=split/\n/,$cluster;
		shift @line;
		foreach $i(@line){
			$num++;
			if ( $i=~/\%/ && $i=~/>(?<scaf_id>\S+?)\.\.\./ ){
			  $scaf_id.=",$+{scaf_id}";
			  }
			elsif ($i=~/\*/ && $i=~/^\d+?\s+?(?<rep_len>\d+?)[ant]+?,\s>(?<rep_id>\S+?)\.\.\./){
			  ($rep_id,$len)=($+{rep_id},$+{rep_len});
			  }
		}
			$scaf_id=$rep_id.$scaf_id;
			print OUT "$rep_id\t$len\t$num\t$scaf_id\n";		
}
$/="\n";
close IN;
close OUT;
#=====End========