#!/usr/bin/perl -w

=head1 Description:

    script for generating nonredundant datasets.

=head1 Version:

    Version: 0.1  Date: 2014-10-28
    Version: 0.1.1 Date: 2015-02-10, add option dvf, split steps1-2, modity M option to access *G.
    Contact: yujinhui[AT]novogene.cn

=head1 Usage: perl Uniseq_vxx.pl --input <Pro/DNA/RNA_set> --outdir <out_directory> [--options]
                                                                                 
    --input <str>           input sequnce of Protein/DNA/RNA; supported format: fasta
    --seq_list <str>        input sequnce list of Protein/DNA/RNA; format: #samplename path
    --pattern <dir-pattern> input directory pattern that contain Protein/DNA/RNA sequences.
    --method <str>          input method for uniq seq,cdhit|usearch, default=cdhit
    --in_clstr <str>        input .clstr file when only run step 2
    --type <str>            select sequence type,chose "nt" for DNA/RNA and "pro" for protein,default="nt" 
    --output <str>          output statistic table of unique sequence;default="uniseq_table"
    --outdir <dir>          set output directory,default=.
    --shdir <dir>           set shell directory,default=./Shell
    --c <str>               set sequence identity threshold for cd-hit,default 0.9;Once set,-n was limited 
    --M <str>               memory limit for cd-hit and usearch, default 2G
    --dvf <str>             vf cutoff, while --qalter, deault=5G
    --cd_opts <str>         set cd-hit parameters other than --c --M ;
    --us_opts <str>         set other usearch options, default=[-derep_prefix]
    --step <num>            step to run: 1-elimination of redundancy
                                         2-generation of table                                         
                                         default=12
    --prefix <str>          set output prefix,default=cd-hit
    --notrun <str>          only write the shell, but not run
    --locate <str>          just rum locate, not qusb
    --help <str>            format: output help information to screen.
                            cd:help information about cd-hit
                            est:help information about cd-hit-est
                            us:help information about usearch   
Note: 
    Modified: 2014-11-13 refined the sub function for selecting -n
    When set -c parameter,the -n was determined;
    Please noted that step2 is just designed for cdhit;
                                
Example:
    perl Uniseq_v0.1.pl --seq_list seq.list --type pro --c 0.85 --M 3000                                                                                  
=cut
#==============================================================================================================================

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin); 
use Getopt::Long;

# set default options
my %opt = (
  input=>"",seq_list=>"",output=>"uniseq_table",
  shdir=>"./Shell",in_clstr=>"",step=>12, prefix=>"cd-hit",
  outdir=>".",c=>"0.9",M=>"2G",cd_opts=>"",type=>"nt",
  method => "cdhit",us_opts =>' -derep_prefix ',dvf=>'5G',
  );
GetOptions (
  \%opt,"input:s","seq_list:s","output:s","shdir:s","c:f",
  "M:s","n:i","in_clstr:s","step:i","prefix:s","outdir:s",
  "cd_opts:s","type:s","help:s","notrun","locate","pattern:s",
  "method:s","us_opts:s","dvf:s",
); 

#get software pathway
$opt{c}|| die "Erro: -c was required";
$opt{method} eq 'cdhit' || $opt{method} eq 'usearch' || die"error:method just can be selected from cdhit or usearch\n";
use lib "$Bin/../../00.Commbin";
my $lib="$Bin/../../../lib";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt")||die "erro: can't find config at $Bin/../../../,$!\n";
my ($CD_HIT,$super_worker,$usearch,$usearch_help)=get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(CDHIT SUPER_WORK USEARCH USEARCHH)],$Bin,$lib);
my $cdhit="$CD_HIT/cd-hit";
my $cdhitest="$CD_HIT/cd-hit-est";
my $getable="$Bin/lib/get_table.pl";
my $CD;
if($opt{method} eq 'cdhit')
{if ($opt{type}=~/pro/i ){
    $opt{n}=sel_pn($opt{c});
    $CD= $cdhit;
}
elsif ($opt{type}=~/nt/i ){
    $opt{n}=sel_nn($opt{c});
    $CD= $cdhitest;
}
else {die "Erro: sequence type canbe only selected form pro/nt";}}

if($opt{help}){
    ($opt{help}=~/cd/) ? system"$cdhit -h" :
    ($opt{help}=~/est/) ? system"$cdhitest -h" :
    ($opt{help}=~/us/) ? system"$usearch_help ":
    die"error: --help just can be selected from cd|est\n";
    exit;
}

#====================================================================================================================
#=====Main====
$opt{input} || $opt{seq_list} || $opt{in_clstr} || $opt{pattern} ||die `pod2text $0`;
$opt{outdir}=abs_path($opt{outdir});
$opt{shdir}=abs_path($opt{shdir});
(-d $opt{outdir}) || `mkdir -p $opt{outdir}`;
(-d $opt{shdir}) || `mkdir -p $opt{shdir}`;
$opt{us_opts} && ($usearch .= " $opt{us_opts} ");
if($opt{method}eq'cdhit')
{$opt{M} ? 1 : ($opt{M}='5G'); #limit -M up to 5g ;
$super_worker.=" --resource $opt{M} ";
  if ($opt{M}) {
      my $num=$1 if($opt{M}=~/^(.*)G$/i);
      my $M=$num*1000 ;
      $opt{M}=$M;
  }
$opt{n} ? $opt{cd_opts}.=" -c $opt{c} -n $opt{n} -M $opt{M}":
die "Please check the identity threshold";}
$opt{dvf} && ($super_worker .= " --dvf $opt{dvf} ");

##step1 elimination of redundancy
my ($list,$cd_in,$cd_out,$clstr);
open(SH,">$opt{shdir}/$opt{prefix}.sh"); 
#open(SH2,">$opt{shdir}/$opt{prefix}.work.sh"); #qsub shell;2014-11-6
if($opt{step}=~/1/ ){
		if ($opt{input} && -s $opt{input}){                      #if input sequence
            $cd_in=$opt{input};
            $cd_out="$opt{outdir}/$2" if ( $cd_in=~/(.*)\/(.*?)$/);
        }
		elsif ($opt{seq_list} && (-s $opt{seq_list})){                #if input list of sequence 
		    $list=`less $opt{seq_list}`;
            $cd_in=combine_db($list);
            $cd_out=$cd_in;
        }
        elsif ($opt{pattern}){                #if input is directory pattern
            $list=`ls $opt{pattern}`;
            $cd_in=combine_db($list);
            $cd_out=$cd_in;
        }
		$opt{output} ? ($cd_out="$opt{outdir}/$opt{output}.cdhit.fa") : ($cd_out.=".cdhit");
		$clstr=$cd_out.".clstr";
		print SH "$CD -i $cd_in -o $cd_out $opt{cd_opts}\n" if($opt{method} eq 'cdhit');
    print SH "$usearch $cd_in -output $opt{outdir}/derep.fa -sizeout\n",
    'perl -ne \'chomp;$i=$_;$i=~s/;size=\d+;$//;print "$i\n";\' ',
    "$opt{outdir}/derep.fa > $cd_out\n" if($opt{method} eq 'usearch');
}

##step2 generation of table
my ($clstr_file,$table);
if($opt{step}=~/2/ && $opt{method} eq 'cdhit'){	
	if ($opt{in_clstr} && (-s $opt{in_clstr} )){
       $clstr_file=abs_path($opt{in_clstr});
    }
    elsif ($clstr){
        $clstr_file="$clstr";
    }   
	print SH "perl $getable --in_clstr $clstr_file --output $opt{outdir}/$opt{output}.table.txt\n";
}
#print SH2 "$super_worker $opt{shdir}/$opt{prefix}.sh\n";
$opt{notrun} && exit;
$opt{locate} ? system "sh $opt{shdir}/$opt{prefix}.sh 2> $opt{shdir}/$opt{prefix}.log\n" :
system "cd $opt{shdir};$super_worker --splits '\\n\\n' --qopts  ' -V ' $opt{prefix}.sh";
#system "cd $opt{shdir};qsub -cwd -l vf=$opt{M}m -V $opt{shdir}/$opt{prefix}.sh\n"; ##run well~
#system "cd $opt{shdir}/;sh $opt{shdir}/$opt{prefix}.work.sh";#not work 
close SH;

#====Sub====
sub combine_db {
my ($dblist)=@_;
my ($smalldb,$bigdb);
my @sdblist=split /\n/,$dblist;
open OUT,"> $opt{outdir}/$opt{output}.fa";
foreach $_(@sdblist){
my @dir=split /\s/,$_;
open IN,"$dir[-1]";
while(<IN>){
    print OUT "$_";
}
close IN;
#$smalldb.="$dir[-1] ";
}
close OUT;
#print SH "cd $opt{outdir}\n","cat $smalldb > $opt{output}.fa\n";
return $bigdb="$opt{outdir}/$opt{output}.fa";
}

sub sel_pn {                  #select -n for cd-hit according to -c 
    my ($c,$n)=@_;
    if ($c){
      (0.7 <= $c && $c <=1.0) ? return $n=5:
      (0.6 <= $c && $c <0.7) ? return $n=4:
      (0.5 <= $c && $c <0.6) ? return $n=3:
      (0.4 <= $c && $c <0.5) ? return $n=2: 
      print "Warning:c value was among 0.4~1.0"; 
    }
  }

sub sel_nn {                  #select -n for cd-hit-est according to -c 
    my ($c,$n)=@_;
    if ($c){
      (0.95 <= $c && $c <=1.0) ? return $n=10:
      (0.92 <= $c && $c <0.95) ? return $n=9:
      (0.9 <= $c && $c <0.92) ? return $n=8:
      (0.88 <= $c && $c <0.9) ? return $n=7:
      (0.85 <= $c && $c <0.88) ? return $n=6:
      (0.8 <= $c && $c <0.85) ? return $n=5:
      (0.75 <= $c && $c <0.8) ? return $n=4:
      print "Warning:c value was among 0.75~1.0"; 
    }
  } 
  
sub get_filename{  # 20141111 modified;
    my ($file,$filename)=@_;
    my @suffixlist = qw(.fa .fasta .txt .fq .pl .sh);
    my ($name,$path,$suffix) = fileparse($file,@suffixlist);
    $filename=$name.$suffix;
    $path=abs_path($path);
    $file=$path."/".$filename;
    return ($file,$filename);
}
#====End====
