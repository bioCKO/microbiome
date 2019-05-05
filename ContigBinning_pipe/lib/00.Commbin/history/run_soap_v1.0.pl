#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
#use lib '/ifs2/ANIMAL/GROUP/group004/liuwenbin/system/pm';
#use COMM qw(abs_path arr_path);
sub abs_path{chomp(my $tem=`pwd`);($_[0]=~/^\//) ? $_[0] : "$tem/$_[0]";}
sub arr_path{my @out;foreach(@_){push @out,abs_path($_);}@out;}
use Getopt::Long;
my ($qsub_opt,$resource,$lib_lst,$run,$soap_dir,$soap_opt,$dvf,$outlst,$verbous,$help,$maxjob,$sd,$gzip,$nt_dir,
        $cov_dir,$run_cover,$cov_opt,$revi_file,$revi_opt,$refile,$run_gc,$gc_dir,$step,$gc_opt,$insert_dir,$name,
        $cluster_range,$cover_cut,$blast_opts,$megablast,$mega_opts,$len_cut,$cpu,$blast_vf,$ntdb,$gidTaxid,$node);
my %opt;
GetOptions(
	"l|insert:s"=>\$lib_lst,       "sd:s"=>\$sd,
	"q|qopts:s"=>\$qsub_opt,       "r|run:s"=>\$run,
	"v|soap_vf:s"=>\$resource,     "d|soap_dir:s"=>\$soap_dir,
	"o|outlst:s"=>\$outlst,        "s|soap_opts:s"=>\$soap_opt,
	"w|bwt_vf:s"=>\$dvf,           "c"=>\$run_cover,
    "cd|cov_dir:s"=>\$cov_dir,     "cp|cov_opts:s"=>\$cov_opt,
    "f|revif:s"=>\$revi_file,      "rp|revi_opts:s"=>\$revi_opt,
	"b|verbose"=>\$verbous,        "h|help"=>\$help,
    "z|gzip"=>\$gzip,              "p|maxjob:i"=>\$maxjob,
    "rf|refile:s"=>\$refile,       "g"=>\$run_gc,
    "gd|gc_dir:s"=>\$gc_dir,       "step:i"=>\$step,
    "gp|gc_opts:s"=>\$gc_opt,      "id|insert_dir:s"=>\$insert_dir,
    "nt_dir:s"=>\$nt_dir,           "name:s"=>\$opt{name},
    "cover_cut:f"=>\$opt{cover_cut},     "cluster_range:s"=>\$opt{cluster_range},
    "megablast"=>\$opt{megablast},       "mega_opts:s"=>\$opt{mega_opts},
    "len_cut:i"=>\$opt{len_cut},         "cpu:i"=>\$opt{cpu},
    "blast_vf:s"=>\$opt{blast_vf},       "ntdb:s"=>\$opt{ntdb},
    "gidTaxid:s"=>\$opt{gidTaxid},       "node:s"=>\$opt{node},
    "incomp_del"=>\$opt{incomp_del},    "sortsoap"=>\$opt{sortsoap},
    "prefix:s"=>\$opt{prefix},          "dibc"=>\$opt{dibc}
);
$opt{incomp_del} = 1;############### NOTE!!
#GetOptions(
#    \%opt,"cluster_range:s","cover_cut:f","blast_opts:s","megablast",
#    "mega_opts:s","len_cut:i","cpu:i","blast_vf:s","ntdb:s","gidTaxid:s",
#    "name:s","node:s"
#);
(@ARGV != 2 || $help) && die"
Name
    run_soap.pl
\nDescription
    script to run SOAP2, soap.coverage, base.revision, GC_depth or soap2_insert, nt blast
\nAuthor
    liuwenbin, liuwenbin\@genomic.org.cn
\nVersion
    V1.0, Date: 2011-03-14
    Last modify: 2011-12-22
\nUsage: perl run_soap.pl <reads.lis> <index_lib>  [-option]
    reads.lis               PE reads or Single reads pathway
    index_lib               soap -D set, when not end with .index, index lib will build
    --step <num>            step to run: 1 soapalign, 2 soap.coverage, 3 base.revision, 4 GC_depth,
                            5 soap2_insert, 6 nt blast, defualt=1
    --insert <str>          insert lst: name avg_ins, set to caculate -m -x, when PE reads
    --sd <str>              sd to caculate -m -x for small,big lane, default=0.2,0.3
    --qopts <str>           option for qsub, e.g. '-P mgtest -q bc.q', default not set
    --run <srt>             parallel type, qsub, or multi, default=qsub
    --maxjob <num>          maxjob, default=qsub?100:4

    1.soapalign:
    --soap_vf <str>         resource for SOAP, default 'vf=2g'
    --bwt_vf <str>          resource for 2bwt-builder, default vf=500M
    --soap_opts <str>       other soap option, default '-p 6 -v 3'
    --soap_dir <dir>        SOAP2 result output directory, default=./01.Soapalign
    --outlist <str>         the out soap result list, default=soap.lst
    --incomp_del            to delect the incomplete soap2 result, I am sorry that soap2 has the bug!!
    --sortsoap              sort the soapalign result
    --prefix <str>          sortSoap prefix, default=all

    2.soap.coverage:
    --cov_dir <dir>         soap.coverage out dir, default=./02.Coverage
    --cov_opts <str>        soap.coverage option, default '-p 8'

    3.base.revision
    --revif <file>          set name and output base.revision fastat file, default no out
    --refile <file>         set base.revision infile, default=input index fasta file
    --revi_opts <str>       set base.revision option, default='-m 1 --cc 20'
    --dibc                  output output.dibc(-d set)

    4.GC_depth:
    --gc_dir <dir>          GC-depth analysis directory, default=./03.GC_depthi
    --gc_opts <str>         set GC-depth options, default='--gc_range 0,100 --dep_cut 400 '

    5.soap2_insert:
    --insert_dir <dir>      soap2_insert output directory, defualt=./04.Insert

    6.NT blast:
    --nt_dir <dir>          NT blast output directory, default=./05.Nt
    --cluster_range <str>   cluster_num frequence range see the cluster as enthetic, default=0.001,0.05
    --cover_cut <flo>       sequence enthetic coverage cutoff to selected out, defaut=0.5
    --blast_opts <str>      blast options, default='-e 1e-5 -F F -b 5'
    --megablast             use megablast instead of blastall, it maybe run faste
    --mega_opts <str>       megablast options, default='-p 0.8 -b 5 -v 5'
    --len_cut <num>         blast m8 match min length, defualt=200
    --cpu <num>             thread for the nt blast process, default=1
    --run <str>             run type, qsub or mutil, default=qsub
    --blast_vf <str>        resultce for qsub blast m8, defalt=3G
    --ntdb <file>           NT database, default=/ifshk1/pub/database/ftp.ncbi.nih.gov/blast/db/20110911/nt
    --gidTaxid <file>       gi_taxid_nucl.dmp from NCBI taxonomy, default 20101123 version
    --name <file>           names.dmp from NCBI taxonomy, default 20101123 version
    --node <file>           nodes.dmp from NCBI taxonomy, default 20101123 version
    --verbose               output running information
    --gzip                  gzip soap result
    --help                  output help information to screen
\nNote:
    1 The full output: 00.Index/ 01.Soapalign/ 02.Coverage/ 03.GC_depth/ 04.Insert/ 05.Nt, all process shell at Shell/
    2 The result for SOAP2 and soap.coverage and base.revision are the same, set by -soap_vf option.
    3 when set -refile, step 3 will run without seting -step 3.
\nExample:
    nohup perl run_soap.pl reads.lst all.scafSeq -step 12 -refile all.scafSeq.500 -refile all.scafSeq.500.revi -r mutil -l InsertSize.txt &\n\n";

###   check error   ===========================================================================================
my ($reads_lst, $index_lib) = &arr_path(@ARGV);
(-s $reads_lst) || die"error can't fine valid file: $reads_lst, $!\n";
foreach("2bwt-builder","soap2.21","soap.coverage","super_worker.pl","line_diagram.pl","base.revision","soap2_insert.pl"){
    (-s "$Bin/$_") || die"error can't find $_ at $Bin, $!\n";
}
#### option value   ===========================================================================================
$resource ||= "vf=2g";
$soap_opt ||= "-p 6 -v 3";
$cov_opt ||= "-p 8";
$revi_opt ||= '-m 1 --cc 20';
$gc_opt ||= ' --gc_range 0,100 --dep_cut 400';
$step ||= 1;
$dvf ||= 'vf=500M';
$run ||= 'qsub';
$sd ||= "0.2,0.3";
my @sd = split/,/,$sd;
$maxjob ||= ($run eq 'qsub') ? 100 : 4;
$outlst ||= "soap.lst";
$soap_dir ||= "01.Soapalign";
$cov_dir ||= "02.Coverage";
$gc_dir ||= "03.GC_depth";
$insert_dir ||= "04.Insert";
$nt_dir ||= "05.Nt";
#$qsub_opt ||= "-P mgtest -q bc.q";
foreach($outlst,$soap_dir,$cov_dir,$insert_dir,$gc_dir,$nt_dir){$_ = &abs_path($_);}
#### preces pathway   ==========================================================================================
my $bwt_builder = "$Bin/2bwt-builder";
my $soap_path = "$Bin/soap2.21";
my $soap_coverage = "$Bin/soap.coverage";
my $super_worker = "perl $Bin/super_worker.pl -reqsub --maxjob $maxjob ";
my $line_diagram = "perl $Bin/line_diagram.pl";
my $revision = "$Bin/base.revision $revi_opt";
my $mutil_process = "perl $Bin/multi-process.pl";
my $soap_insert = "perl $Bin/soap2_insert.pl";
my $gc_depth_pl = "perl $Bin/GC_depth_dis.pl";
my $nt_blast = "perl $Bin/../nt/run_nt_2.1.pl";
$nt_blast =~ s#[^/]+/\.\./##g;
$qsub_opt && ($super_worker .= " --qopts=\"$qsub_opt\"");
($run ne 'qsub') && ($super_worker .= " --bgrun --sleept 100",$nt_blast .= " --run mutil");
####============================================================================================================
#
#                                      MAIN PROCESS
#
####   build bwt    ============================================================================================
my $shdir = abs_path("Shell");
(-d $shdir) || mkdir($shdir);
$verbous && (print STDERR localtime() . " --> building bwt\n");
if(-s "$index_lib.index.sai"){
    $index_lib .= ".index";
}elsif($index_lib !~ /\.index$/){
	my $indir = abs_path("00.Index");
	(-d $indir) || mkdir"$indir";
	my $lin_lib = "$indir/" . (split/\//,$index_lib)[-1];
    (-s $lin_lib) || `ln -s $index_lib $indir`;
    $index_lib = $lin_lib;
    (-s "$index_lib.index.sai") && (goto BWT);
    open BSH,">$shdir/bul_bwt.sh" || die$!;
    print  BSH "cd $indir\n$bwt_builder $index_lib\n";
    close BSH;
	system"cd $shdir;$super_worker -resource $dvf -splitn 1 -prefix bwt bul_bwt.sh -sleept 100";
    BWT:{;}
	$index_lib .= ".index";
}
####  write shell file to run soap   ===========================================================================
$verbous && (print STDERR localtime() . " --> writing shell to run soap\n");
my %lib_ins;
if($lib_lst){
	open LB,$lib_lst || die $!;
	while(<LB>){
		my @l = split/\s+/;
        my $n = ($l[1] > 1000) ? 1 : 0;
		my ($m,$x) = ($l[2] && $l[3]) ? @l[2,3] : ((1-$sd[$n])*$l[1], (1+$sd[$n])*$l[1]);
		$lib_ins{$l[0]} = " -m $m -x $x";
        $n && ($lib_ins{$l[0]} .= " -R");
	}
}
my $run_soap_sh = "run_soap.sh";
open IN,$reads_lst || die $!;
open OUT,">$shdir/$run_soap_sh" || die$!;
my $line = 0;
my $gzip2 = $gzip ? 1 : 0;
($run_cover || $revi_file || $step=~/2|3/ || $opt{sortsoap}) && ($gzip = 0);
my $suffix = $gzip ? "soap.gz" : "soap";
if($step=~/5/){
    (-d $insert_dir) || mkdir($insert_dir);
}
(-d $soap_dir) || mkdir($soap_dir);
while(<IN>){
	chomp;
	my $soapopts = "-a $_";
	my $bname = (split/\//)[-1];
	if($lib_lst){
		chomp(my $b = <IN>);
		my $libname;
		($bname =~ /L\d+_([^_]+)_[12]\.fq/) && ($libname = $1);
		$lib_ins{$libname} || ((print STDERR "Note: can't find lib_ins $libname in $lib_lst\n"),next);
		$soapopts .= " -b $b $lib_ins{$libname}";
	}
	print OUT "cd $soap_dir\n$soap_path $soapopts -D $index_lib $soap_opt -o $bname.PE.soap -2 $bname.SE.soap 2> $bname.log\n";
    if($opt{incomp_del}){
        print OUT "awk '(\$12 && length(\$2)==length(\$3))' $bname.PE.soap > $bname.PE.soap2 & awk '(\$12 && length(\$2)==length(\$3))' $bname.SE.soap > $bname.SE.soap2 & wait\n",
              "mv -f $bname.PE.soap2 $bname.PE.soap; mv -f $bname.SE.soap2 $bname.SE.soap\n";
    }
    if($step=~/5/){
        print OUT "cd $insert_dir\n$soap_insert $soap_dir/$bname.{PE,SE}.soap\n";
    }
#    print OUT ($gzip ? "gzip $bname.PE.soap & gzip $bname.SE.soap & wait\n\n" : "\n"); # it may cause error easy
    print OUT ($gzip ? "gzip $bname.PE.soap\ngzip $bname.SE.soap\n\n" : "\n");
	$line++;
}
close IN;
close OUT;
my $splits = '\n\n';
###  step1/5 to run soap/soap2_insert ===============================================================================
if($step =~ /1/){
    $verbous && (print STDERR localtime() . " --> start to run soap with $line tasks\n");
    `cd $shdir;$super_worker -resource $resource -splits \"$splits\" $run_soap_sh -prefix soap -clean`;
    `ls $soap_dir/*.$suffix >$outlst`;
    $verbous && (print STDERR localtime() . " --> finesh runnint soap\n");
    if($opt{sortsoap}){
        $opt{prefix} ||= 'all';
        open SOR,">$shdir/sortSoap.sh" || die"$!";
        open SLS,">sortsoap.lst";
        print SOR "cd $soap_dir; less ./*.soap | $Bin/msort -k 'm8,n9' > $opt{prefix}.sort\ndate > $shdir/sort.frec\n";
#        print SOR "cd $soap_dir; perl $Bin/msort.pl -k n9 -c 8 *.soap* > $opt{prefix}.sort\ndate > $shdir/sort.frec\n";
        close SOR;
        print SLS "$opt{prefix} = $soap_dir/$opt{prefix}.sort\n";
        close SLS;
        ($run ne 'qsub') ? system"cd $shdir; sh sortSoap.sh &" :
        system"cd $shdir;$super_worker -resource $resource -splitn 1 sortSoap.sh &";
    }
}
###  step2 run soap.coverage  ========================================================================================
($run_cover || $revi_file || $step =~ /[234]/) || exit(0);
$index_lib =~ s/\.index$//;
open SH,">$shdir/after_soap2.sh";
my $sign;
if($gzip2){
    open GZ,">$shdir/gzip.sh" || die$!;
    foreach(`less $outlst`){print GZ "gzip $_";}
    print GZ "gzip $cov_dir/soap.coverage.depthsingle\n";
    close GZ;
}
if($run_cover || $step=~/2/){
    (-d $cov_dir) || mkdir($cov_dir);
    open SOC,">$cov_dir/soap.coverage.sh";
    print SOC "cd $cov_dir\n$soap_coverage  -cvg -refsingle $index_lib -il $outlst -depthsingle soap.coverage.depthsingle -o  coverage.depth ",
    "-plot coverage.plot 0 400 $cov_opt 2> cover.log \n",
    "$line_diagram coverage.plot --signh --frame -x_title 'Sequencing depth(X)' -y_title 'Sequencing depth frequence'  >coverage_depth.svg\n",
    "`/usr/bin/convert coverage_depth.svg coverage_depth.png` 2>/dev/null\n";
    $sign = "soap.coverage ";
###  step4 run GC depth    ========================================================================================
    if($run_gc || $step=~/4/){
        (-d $gc_dir) || mkdir($gc_dir);
        open GC,">$shdir/run_GC_depth.sh" || die$!;
        print GC "cd $gc_dir\n$gc_depth_pl $index_lib $cov_dir/soap.coverage.depthsingle $gc_opt\n";
        close GC;
        print SOC "cd $gc_dir\nsh $shdir/run_GC_depth.sh\n";
        $sign .= "GC_depth ";
    }
    ($revi_file && $step =~/[3]/) || (print SOC "$mutil_process $shdir/gzip.sh\n");
    close SOC;
    print SH "sh $cov_dir/soap.coverage.sh\n";
}
### step3 base.revision   ===========================================================================================
if($revi_file || $step=~/3/){
    my @soap_ps;
    foreach(`less $outlst`){
        chomp;
        /\.PE\.soap/ ? ($soap_ps[0] .= " $_") : ($soap_ps[1] .= " $_");
    }
    $refile ||= $index_lib;
    $revi_file ||= "$index_lib.revi";
    foreach($refile,$revi_file){$_=&abs_path($_);}
    $opt{dibc} && ($revision .= " -d $revi_file.dibc");
    print SH "cd $shdir\n$revision -i $refile -p $soap_ps[0] -s $soap_ps[1] -o $revi_file 2> revision.log\n";
    $sign .= "base.revision";
}
close SH;
$verbous && (print STDERR localtime() . " --> start to run $sign\n");
($run ne 'qsub') ? system"cd $shdir; sh after_soap2.sh" :
system"cd $shdir; $super_worker -resource $resource after_soap2.sh -prefix afsoap -clean";
($step=~/2/ || $run_cover) && &get_cover("$cov_dir/coverage.depth","$cov_dir/coverage_depth.table");
$verbous && (print STDERR localtime() . " --> finesh running $sign\n");
$revi_file ||= "$index_lib.revi";
(-s $revi_file) || ($revi_file = $index_lib);
my $cluster_node = "$gc_dir/GC_depth.pos.cluster";
### step6 nt blast  ===========================================================================================
if($step=~/6/ && -s $revi_file && -s $cluster_node){
#    (-d $nt_dir) || mkdir($nt_dir);
    my $nt_opts = " --outdir $nt_dir";
    foreach(qw(cluster_range cover_cut len_cut cpu blast_vf ntdb gidTaxid name node)){
        $opt{$_} && ($nt_opts .= " --$_ $opt{$_}");
    }
    foreach(qw(blast_opts mega_opts)){$opt{$_} && ($nt_opts .= " --$_=\"$opt{$_}\"");}
    $opt{megablast} && ($nt_opts .= " --megablast");
    open SH,">$shdir/run_nt.sh" || die"$!\n";
    print SH "$nt_blast $revi_file $cluster_node $nt_opts\n";
    close SH;
    system"cd $shdir;sh run_nt.sh";
}
#if($gzip2 && !($revi_file || $step=~/3/)){
if($gzip2){
    $verbous && (print STDERR localtime() . " --> start gzip soap result\n");
    system"cd $shdir;$super_worker -prefix gzip -resource 75M gzip.sh -clean";
    `ls $soap_dir/*.soap.gz >$outlst`;
    $verbous && (print STDERR localtime() . " --> finish gzip soap result\n");
}
($step=~/1/ && $opt{sortsoap}) && `perl -e 'until(-s \"$shdir/sort.frec\"){sleep(10);}'`;
#=======================================================================================================================================
#sub1
#=============
sub get_cover{
#=============
    my ($inf,$outf) = @_;
    (-s $inf) || return(1);
    open IN,$inf || die"$!\n";
    open OUT,">$outf" || die"$!\n";
    print OUT "ChrID\tRef_len(bp)\tCovered_len(bp)\tCoverage(%)\tDepth(X)\n";
    my $depth = 0;
    my @out;
    while(<IN>){
        /^\s/ && last;
        my @l=(split/[:\/\s]+/)[0,2,1,4,6];
        $l[3]=int(10000*$l[2]/$l[1]+0.5)/100;
        ($l[4]=~/\d/) || ($l[4] = 0);
        ($l[4]=~/(\S+)e\+(\d+)/) && ($l[4] = $1*10**$2);
        push @out,[$l[1],join("\t",@l)."\n"];
        $depth += $l[1]*$l[4];
    }
    foreach(sort {$b->[0] <=> $a->[0]} @out){
        print OUT $_->[1];
    }
    my @t;
    while(<IN>){
        /^[TC].+:(\d+)/ && (push @t,$1);
    }
    close IN;
    @t[2,3]=(int(10000*$t[1]/$t[0]+0.5)/100,int($depth/$t[0]+0.5));
    print OUT join("\t","Total",@t),"\n";
    close OUT;
}
