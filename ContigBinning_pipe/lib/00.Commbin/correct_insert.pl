#!/usr/bin/perl -w
use strict;
#use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
use PerlIO::gzip;
my %opt;
GetOptions(\%opt,"outdir:s","prefix:s","ass_opts:s","soap_opts:s","maxjob:i","maxL:i","corr_insert:i","len:i","lim:s",
    "cfg","c:f","clean","outfile:s","cfg_opts:s","seq_file:s","seq_log:s","cfg_options:s","pe_filter","pe_range:s",
    "soap_lst:s","pe_deldir:s","runsoap_shdir:s");
#############################################################################################
(@ARGV==2 || @ARGV==3) || die"
Name: correct_insert.pl
Description:
  script to correct insert size of PE reads, the process  run SOAPdenovo first,
  then caculate insertsize form assembly log info or run SOAP2, and caculate it from SOAP result.
Version: 1.0, Date: 2011-12-7
Version: 2.0, Date: 2012-08-01
Author: Wenbin Liu, liuwenbin\@genomics.org.cn
Usage: perl correct_insert.pl <reads1.fq reads2.fq | reads.lst> <insert.txt> --outfile new_insert.txt
    reads1,2.fq <file>     reads1 and reads2 fasq pathway, gzip is allowed.
    reads.lst <file>       all PE reads pathway list.
    insert.txt <file>      estimates insert size list: lane_name InsertSize
    --outfile <file>       set outfile name, default=new_insert.txt
    --c <flo>              default=1.96, outfile be: lane_name avg_ins avg_ins-c*sd avg_ins+c*sd
                           (to note that: 1.96->95%, 2.575->99% normal distribution confidence interval)
    --outdir <dir>         working dir, default=corr_insert
    --prefix <str>         SOAPdenovo result prefix, default=all
    --maxL <num>           maximum reads length, default=100
    --ass_opts <str>       assembly options, default=\"all -K 63 -d 1 -F\"
    --corr_insert <num>    to correct insert use: 1 assembly log, 2-SOAP2 insert mean as avg_ins,
                           3-SOAP2 insert mode as avg_ins(by soap2_insert.pl). default=1
    --seq_file <file>      use sequence file for SOAP2 correct insert, then not run grape
    --seq_log <file>       use assembly log file to correct insertsize, then not run grape
    --soap_opts <str>      SOAP2 options, default=\" -l 32 -s 40 -v 3 -r 1 -p 6\"
    --soap_lst <file>      set soap2 result list, then not ru soap2
    --maxjob <num>         maxjob for SOAP2, default=3
    --cfg_opts <str>       write_cfg.pl options(options to write assembly cfg file), default='-a 3,2 -p 3,5'
    --cfg                  output new soapdenovo cfg file STDOUT
    --cfg_options <str>    output new cfgfile write options, default='-a 3,2 -p 3,5'
    --pe_filter            to filter PE outside normal insertSize range
    --pe_range <str>       set the range to identity normal insert range, while -pe_filter set, default='0,0/1000,3i'
    --len <num>            reads length, default get from reads file.
    --lim <str>            data limit(Mbp) for PE filter data, form small_lib_lim,big_lib_lim, default not filter
    --pe_deldir <dir>      if you have del FQid list directory, please set it.
    --clean                clean outdir.
	--runsoap_shdir <str>  shell dir if run_soap.pl is run. (added by lss at 2016)
Note:
    1 The script will no qsub, you should qsub by yourself.
    2 The out insert.txt be: lane_name avg_insert avg-c*sd avg+c*sd org_ins
    
Example:
    perl correct_insert.pl reads.list InsertSize.txt --pe_filter --pe_range='0,0;1000,3i' --lim 400,200
    perl correct_insert.pl reads.list InsertSize.txt --pe_filter --pe_range='0,0/0.5i,3i' --seq_file all.scafSeq
    perl correct_insert.pl reads.list InsertSize.txt --pe_filter --pe_range='0,0;0.5i,3i' --soap_lst soap.list\n\n";
#############################################################################################
foreach(@ARGV){
    (-s $_) || die"error: can't find able file $_, $!";
    $_ = abs_path($_);
}
#============================================================================================
# get pathawy
#my $lib = "$Bin/../lib";
my $lib = "$Bin/../";
$lib =~ s/[^\/]+\/\.\.\///g;
my ($grape31,$grape63,$write_cfg,$run_soap,$calculate_insert) =
("$lib/grape/grape31mer", "$lib/SOAPdenovo-V2.04/SOAPdenovo-63mer","$Bin/write_cfg.pl","$Bin/run_soap.pl","$Bin/calculate_insert.pl");
#("$lib/grape/grape31mer", "$lib/grape/grape63mer","$Bin/write_cfg.pl","$Bin/run_soap.pl","$Bin/calculate_insert.pl");
foreach($grape31,$grape63,$write_cfg,$run_soap,$calculate_insert){(-s $_) || die"error: can't find script $_,$!\n";}
#============================================================================================
# default options
$opt{outdir} ||= "corr_insert";
(-d $opt{outdir}) && ($opt{clean} = 0);
(-d $opt{outdir}) || mkdir($opt{outdir});
$opt{outdir} = abs_path($opt{outdir});
$opt{prefix} ||= 'all';
$opt{maxL} ||= 100;
$opt{cfg_opts} ||= ' ';#'-a 3,3 -p 3,3';
$opt{ass_opts} ||= "all -K 63 -d 1 -F";
$opt{soap_opts} ||= " -l 32 -s 40 -v 3 -r 1 -p 6";
$opt{cfg_options} ||= ' ';#'-a 3,3 -p 3,3';
$opt{maxjob} ||= 3;
$opt{corr_insert} ||= 1;
$opt{c} ||= 1.96;
$opt{outfile} ||= "new_insert.txt";
$opt{outfile} = &abs_path($opt{outfile});
my $insert = pop;
my $readl;
if(@ARGV==1){
    $readl = shift;
}else{
    $readl = "$opt{outdir}/reads.lst";
    open RE,">$readl" || die$!;
    print RE join("\n",@ARGV);
    close RE;
}
foreach($readl,$insert){$_ = abs_path($_);}
my $kmer = $1 if($opt{ass_opts} =~ /-K\s+(\d+)/);
my $denovo = ($kmer > 31) ? $grape63 : $grape31;
my $seq_file ||= ($opt{seq_file} || "$opt{outdir}/$opt{prefix}.scafSeq");
foreach($seq_file,$opt{soap_lst},$readl){
    $_ &&= abs_path($_);
}
my $seq_log ||= ($opt{seq_log} || "$opt{outdir}/all.log");
my $pe_deldir = abs_path("$$.PE_DEL");
if($opt{pe_filter}){
   $opt{corr_insert}=2;
   $opt{pe_range} && ($calculate_insert .= " -r \"$opt{pe_range}\"");
   $calculate_insert .= " -d $pe_deldir";
}
$opt{corr_insert} ||= 1;
$opt{pe_deldir} && ($pe_deldir = $opt{pe_deldir},goto(AA));
my $sel = ($opt{corr_insert}!=2) ? " -e " : " ";
#============================================================================================
# Soapdenovo
if(!(-s $seq_file || ($opt{soap_lst} &&  -s $opt{soap_lst}))){
    system"perl $write_cfg -m $opt{maxL} $opt{cfg_opts} $readl $insert > $opt{outdir}/cfg.txt
    cd $opt{outdir}
    $denovo $opt{ass_opts} -s cfg.txt -o $opt{prefix} > all.log 2> all.e";
}
#============================================================================================
# Correct insertSize
if($opt{corr_insert}==1 && (-s $seq_log)){
    my @all_lib;
    foreach(`less $readl`){
       my $bf = (split/\//)[-1];
        #($bf=~/L\d+\_([^_]+)\_1/) && (push @all_lib,$1);
		($bf=~/L\d+_([^_]+)\.notCombined_1\.f[aq]/ || $bf =~ /L\d+_([^_]+)_1\.fq/) && (push @all_lib,$1);
    }
    my %insh = split/\s+/,`awk '{print \$1,\$2}' $insert`;
    my $i = 0;
    open OUT,">$opt{outfile}" || die$!;
    foreach(`perl -ne '\$e && (print);\$e=0;/^Pair_num/ && (\$e=1);/^all PEs attached/ && last;' $seq_log`){
        my ($pair,$sd, $avg) = (split)[0,1,2];
        my $outins = (!$pair || $avg eq 'new') ? $insh{$all_lib[$i]} :
            join("\t",$avg,int($avg-$sd*$opt{c}+0.5),int($avg+$sd*$opt{c}+0.5));
        print OUT join("\t",$all_lib[$i],$outins),"\n";
        $i++;
    }
    close OUT;
}elsif($opt{soap_lst} && -s $opt{soap_lst}){
    system"cd $opt{outdir}
    perl $calculate_insert $opt{soap_lst} -c $opt{c} -s $insert -p $opt{maxjob} $sel > $opt{outfile}";
}elsif(-s $seq_file){
    system"cd $opt{outdir}
    perl $run_soap $readl $seq_file --shdir $opt{runsoap_shdir} -l $insert -o soap.lst -sd 0.1,0.2 -s=\"$opt{soap_opts}\" -r multi -p $opt{maxjob}
    perl $calculate_insert soap.lst -c $opt{c} -s $insert -p $opt{maxjob} $sel > $opt{outfile}";
}
AA:{;}
my %get_lib;
my %reads;
foreach(`less $readl`){
    chomp;
    my $bf = (split/\//)[-1];
    ($bf =~ /L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || $bf =~ /L\d+_([^_]+)_[12]\.fq/) || next;
    $get_lib{$1} = 1;
    push @{$reads{$1}},$_;
}
#my %lh = split/\s+/,`awk '{print \$1,\$NF}' $insert`;
my (%lh,%lhh);
foreach(`less $insert`){
    my @l = split;
    my $lane_name = shift @l;
    $lh{$lane_name} = $l[-1];
    $lhh{$lane_name} = join("\t",@l);
}
if($opt{pe_filter} && -d $pe_deldir){
    select_pe_reads(\%reads,$pe_deldir,\%lh,$opt{len},$opt{lim});
    $opt{clean} && `rm -r $pe_deldir`;
}
if(-s $opt{outfile}){
    foreach(`less $opt{outfile}`){my $t=(split)[0];delete $get_lib{$t};}
}
if(%get_lib){
    open IS,">>$opt{outfile}" || die$!;
    foreach(keys %get_lib){
        $lhh{$_} && (print IS "$_\t$lh{$_}\n");
    }
    close IS;
}
$opt{cfg} && system"perl $write_cfg -m $opt{maxL} $opt{cfg_options} $readl $opt{outfile}";
#$opt{clean} && `rm -r $opt{outdir}`;
$opt{clean} && (-d "$opt{outdir}/00.Index") && `rm -r $opt{outdir}/00.Index/`;
$opt{clean} && (-d "$opt{outdir}/01.Soapalign") && `rm -r $opt{outdir}/01.Soapalign/`;
$opt{clean} && (-e "$opt{outdir}/all.kmerFreq") && `rm -r $opt{outdir}/all.{readInGap,links,Arc,preArc,newContigIndex,updated.edge,edge,gapSeq,peGrads,ContigIndex,kmerFreq,readOnContig,scaf_gap,PEreadOnContig,preGraphBasic,scaf,shortreadInGap,vertex}`;
#======================
sub abs_path{
    chomp(my $tem = `pwd`);
    ($_[0]=~/^\//)? $_[0] : "$tem/$_[0]";
}
sub select_pe_reads{
    my ($reads,$pe_deldir,$inserth,$len,$lim) = @_;
    my %pedel;
    foreach(`ls $pe_deldir/*.dd`){
        chomp;
        (-s $_) || next;
        my $bf = (split/\//)[-1];
        ($bf=~/L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || $bf=~/L\d+_([^_]+)_[12]\.fq/) && (push @{$pedel{$1}},$_);
    }
    (%pedel || $lim) || return(0);
    my @sd;
    if($lim){
        @sd = split/,/,$lim;
        (@sd == 1) && ($sd[1] = $sd[0]);
        foreach(@sd){$_ *= 10**6;}
    }
    foreach(keys %pedel){
        $reads->{$_} || next;
        my ($af_reads1,$af_reads2) = @{$reads->{$_}};
        my $type = 0;
        my $bf=(split/\//,$af_reads1)[-1];
        if(($bf=~/L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || $bf=~/L\d+_([^_]+)_[12]\.fq/) && $inserth->{$1} && $inserth->{$1}>=1000){
            $type = 1;
        }
        my %get_id;
        foreach my $f(@{$pedel{$_}}){
            open PE,$f || die$!;
            while(<PE>){chomp;$get_id{$_}=1;}
            close PE;
        }
        my ($bf_reads1,$bf_reads2) = ("$af_reads1.org.gz","$af_reads2.org.gz");
        my ($get,$del) = (0, 0);
        system"mv -f $af_reads1 $bf_reads1; mv -f $af_reads2 $bf_reads2";

        my @size_reads1 = stat ($bf_reads1);   ##  lihongyue 
        my @size_reads2 = stat ($bf_reads2);   ##  lihongyue
        ($size_reads1[7] >25  &&  $size_reads2[7] >25) || die "Empty reads.gz\n\n";   ##  lihongyue

        open IN1,"<:gzip",$bf_reads1 || die "error in $bf_reads1";
        open IN2,"<:gzip",$bf_reads2 || die "error in $bf_reads2";
        open OUT1,">:gzip",$af_reads1 || die"error in $af_reads1";
        open OUT2,">:gzip",$af_reads2 || die"error in $af_reads2";
		$/ = "\n";
		while (my $id1 = <IN1>) {
			chomp $id1;
			chomp(my $id2 = <IN2>);
			$id1 =~ s/^\@|\/\d$//g;
			$id2 =~ s/^\@|\/\d$//g;
			chomp(my $seq1 = <IN1>);
			chomp(my $seq2 = <IN2>);
			<IN1>;<IN2>;
			chomp(my $qual1 = <IN1>);
			chomp(my $qual2 = <IN2>);
			if(!$len){$len = length($seq1) + length($seq2);}
			if($get_id{$id1}) {delete $get_id{$id1}; $del += $len; next;}
			if($get_id{$id2}) {delete $get_id{$id2}; $del += $len; next;}
			print OUT1 "\@$id1\n$seq1\n+\n$qual1\n";
			print OUT2 "\@$id2\n$seq2\n+\n$qual2\n";
			$get += $len;
			if($sd[$type]){
			    ($get >= $sd[$type]) && last;
			}
		}
        close IN1;
        close IN2;
        close OUT1;
        close OUT2;
        my $tol = $get + $del;
        open DES,">$bf_reads1.fpe.stat" || die$!;
        print DES "Total_date(Mb)\tDel_PE(Mb)\trate(%)\tClean_data(Mb)\trate(%)\n";
        print DES sprintf("%.3f\t%.3f\t%.2f\t%.3f\t%.2f\n",$tol/10**6,$del/10**6,100*$del/$tol,$get/10**6,100*$get/$tol);
        close DES;
    }
}
