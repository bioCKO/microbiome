#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my ($max_rd_len,$Lcut,$ins_sd,$reverse_seq,$asm_flags,$pair_num_cutoff,$chain,$rankf,$sel_ccf,$help,$small,$E,$map_len,$asmflag);
GetOptions(
	"m:i"=>\$max_rd_len,        "r:i"=>\$reverse_seq,
	"a:s"=>\$asm_flags,         "s:s"=>\$sel_ccf,
    "c:s"=>\$chain,             "k:s"=>\$rankf,
    "L:i"=>\$Lcut,              "p:s"=>\$pair_num_cutoff,
    "d:f"=>\$ins_sd,            "x"=>\$small,
	"h"=>\$help,                "E"=>\$E,
    "map_len:i"=>\$map_len,		"f:s"=>\$asmflag
);
(@ARGV <1 || $help) &&  die"Name: write_cfg.pl
Describe: to write the lib.cfg for running SOAPdenovo
Author: liuwenbin, liuwenbin\@genomic.org.cn
Version: 1.0, Date: 2011-03-04
Version: 2.0, Date: 2011-07-27, Update: add -k -s -c option
Usage: perl write_cfg.pl <reads.lis> <lib.lst> [-options] [out.cfg(default stdout)]
    reads.lis      .pair and .single or .clean reads pathway
    lib.lst        list file, form: library_name avg_ins [min_ins max_ins]
    -d <flo>       SD for lib.lst without [min_ins max_ins], default not use
    -k <file>      lib_rank, file form: lib_name [12345] rank, default acroding to avg_ins
                   [12345] set to select reads for given lane when reads.lst contain them:
                    1 only use clean reads        2 only use correct reads
                    3 only use corr-chain reads   4 use corr-chain & clean reads
                    5 use corr-chain & correct reads
    -s <file|num>  to select clean/corr, same as -k select for it, form: file lib_name number [rank]
                   -s can also in form of several number: [1|2]3[4|5]6, means:
                    to 0<avg_ins<200:      1 clean, 2 corr, 3 corr-chain
                    to 200<=avg_ins<1k:    4 clean, 5 corr
                    to avg_ins>1k:         6 clean
    -c <file>      short reads chain by correct_error, use it to write lib.cfg
    -f <file>      to set asm_flags for each lib, form: lib_name asm_flags
    -m <num>       max reads length, default=90
    -x             only use small lane to write cfgfile
    -L <num>       length see at big lane, default=1000
    -r <num>       reverse_seq, default=(avg_ins>=L)?1:0
    -a <str>       asm_flags=(avg_ins)>=L)?a2:a1, default=3,2
    -p <str>       pair_num_cutoff=(avg_ins>=L)?p2:p1, default=3,5
    -H             to change the out.cfg name, if it's exist
    -map_len <num> set map_len, default not set
    -h             output help information to screen
Example:
  1 common use:
    perl write_cfg.pl reads.lst Insert.txt >lib.cfg
  2 use -c to add corr-chain reads
    perl write_cfg.pl reads.lst Insert.txt -c corr_chain.lst >lib.cfg
  3 use -k to set ranks or select reads
    perl write_cfg.pl reads.lst Insert.txt -k ranks.txt >lib.cfg
  4 use -s to select reads
    perl write_cfg.pl clean.lst corr.lst -s 146\n\n";

$ins_sd && ($ins_sd<0 || $ins_sd > 1) && die"error: -d set must between 0~1\n";
$max_rd_len ||= ($chain && -s $chain) ? 150 : 90;
$Lcut ||= 1000;
my (%lib_ins, %lane_ins, %asmflagh);# = split/\s+/,`less $ARGV[1]`;
($asmflag && -s $asmflag) && (%asmflagh = split/\s+/,`cat $asmflag`);
#($asmflag && -s $asmflag) && (%asmflagh = split/\s+/,`less $asmflag`);
my (%chain_err,%rankh,%clc);
my $sel_clc = 0;#to identity clean reads or correct reads
$sel_ccf && !(-s $sel_ccf) && ($sel_ccf =~ /\b\d+\b/) && ($sel_clc = 1);
my ($reads_lst, $lib_ins_size, $outfile) = @ARGV;
if($lib_ins_size){
(-s $lib_ins_size) || die"error: infile $lib_ins_size isn't available\n";
foreach(`less $lib_ins_size`){
    my @l = split/\s+/;
    $lib_ins{$l[0]} = ($l[4] || $l[1]);
    if($sel_clc){
        if($l[1]<200){
            $clc{$l[0]} = ($sel_ccf=~/1/ && $sel_ccf=~/3/) ? 4 :
                ($sel_ccf=~/2/ && $sel_ccf=~/3/) ? 5 :
                ($sel_ccf=~/1/) ? 1 : ($sel_ccf=~/2/) ? 2 :
                ($sel_ccf=~/3/) ? 3 : 6;#6 means not select
        }elsif($l[1]>=$Lcut){
            $clc{$l[0]} = ($sel_ccf=~/6/) ? 1 : 6;
        }else{
            $clc{$l[0]} = ($sel_ccf=~/4/) ? 1 : ($sel_ccf=~/5/) ? 2 : 6;
        }
    }
    $ins_sd && (@l<4) && (@l[2,3] = ((1-$ins_sd)*$l[1],(1+$ins_sd)*$l[1]));
    $lane_ins{$l[0]} = (@l>3) ? "min_ins=$l[2]\navg_ins=$l[1]\nmax_ins=$l[3]" : 
        "avg_ins=$l[1]";
}
}
## to get err-chain iformaniton
if($chain && (-s $chain)){
    foreach(`less $chain`){
        chomp;
        my $bname = (split/\//)[-1];
        ($bname =~ /L\d+_([^_]+)_[12]\.fq/) || next;
        $chain_err{$1} = $_;
    }
}
## to get rank or reads selecct information
#$rankf && (-s $rankf) && (%rankh = split/\s+/,`less $rankf`);
if($rankf && (-s $rankf)){
    foreach(`less $rankf`){
        my @l=split/\s+/;$rankh{$l[0]}=$l[-1];
        (@l==3) && ($clc{$l[0]} = $l[1],$sel_clc ||=1);
    }
}
#($sel_ccf && (-s $sel_ccf)) && ($sel_clc = 1, %clc = split/\s+/,`less $sel_ccf`);
if($sel_ccf && (-s $sel_ccf)){
    $sel_clc=1;
    foreach(`less $sel_ccf`){
        my @l=split/\s+/;$clc{$l[0]}=$l[1];
        (@l==3) && ($rankh{$l[0]}=$l[2]);
    }
}
my %reads;
my %lib_name;
open RLS,$reads_lst || die$!;
while(<RLS>){
	chomp;
	my $bname = (split/\//)[-1];
    my $may_size;
	my $libname;
	if($bname =~ /L(\d+)_([^_]+)_[12]\.fq/ || /L(\d+)_([^_]+)\.notCombined_[12].f[aq]/){ #L500_NHD2586.notCombined_1.fastq.gz
        ($may_size,$libname) = ($1,$2);
    }elsif($bname =~ m/L(\d+)_(\S+)\.extendedFrags/){
        ($may_size,$libname) = ($1,$2);
    }
    if($lib_ins_size){
    	($libname && $lib_ins{$libname}) || die"Error: can't find library $libname in $ARGV[0]\n";
    }elsif($libname){
        $lib_ins{$libname} = $may_size;
        if($ins_sd){
            my ($ins_min,$ins_max)  = ((1-$ins_sd)*$may_size,(1+$ins_sd)*$may_size);
            $lane_ins{$libname} = "min_ins=$ins_min\navg_ins=$may_size\nmax_ins=$ins_max";
        }else{
            $lane_ins{$libname} = "avg_ins=$may_size";
        }
    }else{
        die"Error: can't find library library at $bname\n";
    }
    if($sel_clc){
        if($clc{$libname} =~ /[345]/){
            ($bname =~ /OL\.cor\.connected\.fa(\.gz)?$/) && ($chain_err{$libname} = $_, next);
        }
        if($clc{$libname} =~ /[14]/){
            ($bname =~ /\.clean(\.gz)?$|\.FRA(\.gz)?$/) || next;
        }elsif($clc{$libname} =~ /[25]/){
            ($bname =~ /\.(pair|single)(\.gz)?$/) || next;
        }else{
            next;
        }
    }
	push @{$reads{$libname}},$_;
	$lib_name{$libname} ||= 1;
}
close RLS;
my @lib_use;
my %lib_ins_use;
foreach(keys %lib_ins){push @{$lib_ins_use{$lib_ins{$_}}},$_;};
foreach(sort {$a <=>$b} keys %lib_ins_use){push @lib_use,@{$lib_ins_use{$_}}};
my ($rank,$stand_ins) = (0, 0);
my @flags = $asm_flags ? (split/,/,$asm_flags) : (3,2);
my @pair_num = $pair_num_cutoff ? (split/,/,$pair_num_cutoff) : (3, 5);
if($outfile){
    if($E && -s $outfile){
        my $i = 1;
        while(-s "$outfile$i"){
            $i++;
        }
        `mv $outfile $outfile$i`;
    }
    open OUT,">$outfile" || die$!;
    select OUT;
}
print "max_rd_len=$max_rd_len\n";
foreach(@lib_use){
    $lib_name{$_} || next;
	my @list = @{$reads{$_}};
    $rankf && (-s $rankf) && !$rankh{$_} && next;
	my $libname = $_;
	my $avg_ins = $lib_ins{$libname};
    $small && ($avg_ins >= $Lcut) && next;
    my $lane_ins = $lane_ins{$libname};
    my $cur_reverse_seq = ($reverse_seq || (($avg_ins >= $Lcut) ? 1 : 0));
    my $cur_asm_flags = ($avg_ins >= $Lcut) ? $flags[1] : $flags[0];
#    (@list == 1) && ($list[0] =~ /\.extendedFrags\.f[aq]/) && ($cur_asm_flags = 1);
	($list[0] =~ /\.extendedFrags\.f[aq]/) && ((@list == 1) ? ($cur_asm_flags = 1) : ($cur_asm_flags = 3));
	(defined $asmflagh{$libname}) && ($cur_asm_flags = $asmflagh{$libname});
    my $cur_pair_num_cutoff = ($avg_ins>= $Lcut)? $pair_num[1] : $pair_num[0];
    my $avg_rank = $avg_ins;
    if($rankh{$libname}){
        $rank = $rankh{$libname};
    }else{
        ($stand_ins != $avg_rank) && ($rank++,$stand_ins = $avg_rank);
    }
    if($chain_err{$_}){
        print "[LIB]
name=$libname
reverse_seq=$cur_reverse_seq
asm_flags=4
rank=$rank
pair_num_cutoff=$cur_pair_num_cutoff
f=$chain_err{$_}\n";
        $cur_asm_flags=2;
    }
	print "[LIB]
name=$libname
$lane_ins
reverse_seq=$cur_reverse_seq
asm_flags=$cur_asm_flags
rank=$rank
pair_num_cutoff=$cur_pair_num_cutoff\n";
$map_len && (print "map_len=$map_len\n");
	foreach(@list){
#		my $prefix = (/_[12]\.fq(\.gz)?$/ || /\.clean(\.gz)?$/ || /\.FRA(\.gz)?$/ || /\.notCombined_[12]\.\S+(\.gz)?/) ? ((/\_1\.fq(\.gz)?/ || /\_1\.fastq(\.gz)?/) ? 'q1' : 'q2') : ((/\.pair(\.gz)?$/ || /extendedFrags\.fastq/) ? 'p' : 'f'); #1.L180_NHD0482.notCombined_1.fastq.gz 
		my $prefix;
		if (/_[12]\.fq(\.gz)?$/ || /_[12]\.fq\.clean(\.gz)?$/ || /_[12]\.fq\.FRA(\.gz)?$/ || /\.notCombined_[12]\.fastq(\.gz)?/) {
			$prefix = (/\_1\.fq(\.gz)?/ || /\_1\.fastq(\.gz)?/) ? 'q1' : 'q2';
		}
		else {
			if (/\.pair(\.gz)?$/) { $prefix = 'p'; }
			elsif (/extendedFrags\.fastq|\.fastq|\.fq/) { $prefix = 'q'; }
			else { $prefix = 'f';}
		}
		print "$prefix=$_\n";
	}
}
#/F/F.L500_NHPCRFree006_1.fq.clean.gz
#/F/F.L500_NHPCRFree006_2.fq.clean.gz
#F/F.L6000_NHDL259_1.fq.FRA.gz
#F/F.L6000_NHDL259_2.fq.FRA.gz

$outfile && close(OUT);
