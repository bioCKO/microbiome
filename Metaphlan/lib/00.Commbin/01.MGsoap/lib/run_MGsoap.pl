#! /usr/bin/perl -w
use strict;
use FindBin qw($Bin);
#use Cwd qw(abs_path);
sub abs_path{chomp(my $tem = `pwd`);($_[0]=~/^\//)?$_[0]:"$tem/$_[0]";}
use Getopt::Long;
my ($outdir,$vf,$maxjob,$soap,$subdir,$onesp,$noclean,$gzip,$gzipg,$qopts,
    $verbous,$sampid,$bwtvf,$cover,$coveropt,$gap,$draw,$shdir,$locate,$prefix);
GetOptions(
        "outdir:s"=>\$outdir,"vf:s"=>\$vf,"subdir:s"=>\$subdir,"noclean"=>\$noclean,
        "maxjob:i"=>\$maxjob,"soap:s"=>\$soap,"onesp"=>\$onesp,"sampID"=>\$sampid,
        "bwtvf:s"=>\$bwtvf,"cover"=>\$cover,"coveropt:s"=>\$coveropt,"verb"=>\$verbous,
        "gap:s"=>\$gap,"draw"=>\$draw,"gzip"=>\$gzip,"gzipg"=>\$gzipg,"qopts:s"=>\$qopts,
        "shdir:s"=>\$shdir,"locate"=>\$locate,"prefix"=>\$prefix,
);
foreach('soap2.21','soap.coverage','2bwt-builder','super_worker.pl','line_diagram.pl','multi-process.pl'){
    (-s "$Bin/$_") || die"error: can't find script $_ at $Bin\n";
}
my $superwork_pl="/BJWORK/GR/wangxiaohong/MyPipeline/MetaGenomicsPipeline/MetaGenomics_pipeline_v0.1/lib/03.Assembly/02.Assembly/bin/super_worker.pl";

#==========================================================================================================
(@ARGV==2 || @ARGV==3) || die "Name: run_MGsoap.pl
Descrption: script to soap and soapcoverage for MG.
Version: 1.0  Data: 2011-09-24
Connect: liuwenbin\@genomics.org.cn
Usage: perl run_MGsoap.pl <index> <reads.lst | reads1 reads2>
    index               soap -D set, when not end with .index, index lib will build
    reads.lst <file>    input file of reads pathway
    reads1,2 <file>     just input reads pathway, not use reads.lst
    --outdir <dir>      output directory, default=.
    --shdir <dir>       work shell directory, default=outdir/Shell
    --prefix <str>      output shell file prefix,default is run_soap
    --subdir <str>      set sample dir prefix, default subdir name after lib_ID
    --sampID <file>     set file: lib_ID sample_ID, then subdir name after sample_ID
    --onesp             one sample, then outfile at outdir, default at subdir
    --bwtvf <str>       resource for 2bwt-builder, default vf=500M
    --vf <str>          resultce for soap and coverage qsub, deault=1G
    --maxjob <num>      maxjob for qsub, deault=100
    --soap=<str>        soap option, default=\" -l 32 -m 460 -x 540 -s 40 -v 2 -r 1\"
    --gap <num|str>     num: when -soap without -g num, add -g to -soap set and run;
                        str: set second soap option to run at the same time, default not set.
    --cover             run soap.coverage, default not run.
    --coveropt=<str>    soap.coverage opton, default=\" -p 8\"
    --draw              draw coverage depth distribution figure.
    --gzip              gzip soap result.
    --gzipg             to gizp soap-g result, default not gzip.
    --qopts <str>       qsub options, default='-P mgtest -q bc.q'
    --locate            run locate not qsub
    --verb              output running information.
\nNote:
    1 Reads at reads.lst should be reads1\\nreads2.
    2 when index not end with .index, index lib will build.
    3 When use -soap or -coveropt, you'd better write as -soap=\" xxxx\".
    4 Soap results pathway at outdir/soap.lst, -g out at soap-g.lst.
    5 You should not use -gzipg when the result for soapInDel(not support gz).\n\n";
#    5 outdir structure: 00.Index/ 01.Soap_and_coverage/\n\n";
#==========================================================================================================
### check error
foreach(@ARGV){
    ((-s $_) || (-s "$_.sai")) || die"error: can't find file $_\n";
    $_ = abs_path($_);
}
my ($index,$lane_lst,$reads2) = @ARGV;
### default option
$outdir ||= '.';
$prefix ||= 'run_soap';
$outdir = abs_path($outdir);
(-d $outdir) || mkdir($outdir);
$shdir ||= "$outdir/Shell";
$shdir = abs_path($shdir);
(-d $shdir) || mkdir($shdir);

$maxjob ||= 100;
$bwtvf ||= '500M';
$vf ||= '1G';
$soap ||= " -l 32 -m 460 -x 540 -s 40 -v 2 -r 1";
$coveropt ||= ' -p 8';
$qopts ||= '-P mgtest -q bc.q';
#($soap=~/-g\s+\d/) && ($gap = 0);
### main process
my $bname = (split/\//,$index)[-1];
if(-s "$index.index.sai"){
    $index .= ".index";
}elsif(!($index =~ /\.index$/ && -s "$index.sai")){
    $verbous && (print STDERR localtime() . " --> star building index\n");
    my $indir = $outdir . "/00.Index";
    (-d $indir) || mkdir"$indir";
    (-s "$indir/$bname") || system"ln -s $index $indir";
    open BWT,">$shdir/bwt.sh" || die$!;
    print BWT "cd $indir; $Bin/2bwt-builder $bname 2> bwt.log\n";
    close;
    $locate ? system"cd $shdir; sh bwt.sh" :
#system"cd $shdir; perl $Bin/super_worker.pl -clean -sleept 30 -workdir $indir -prefix bwt -resource $bwtvf  bwt.sh --qopts=\"$qopts\"";
    system"cd $shdir; perl $superwork_pl  -clean -sleept 30 -workdir $indir -prefix bwt -resource $bwtvf  bwt.sh --qopts=\"$qopts\"";
    $index = "$indir/$bname.index";
    $verbous && (print STDERR localtime() . " --> finish running bwt\n");
}
$verbous && (print STDERR localtime() . " --> star running soap\n");
open SH,">$shdir/$prefix.sh" || die$!;
my $num = 1;
my %samph;
$sampid && (-s $sampid) && (%samph = split/\s+/,`less $sampid`);
open SL,">$outdir/soap.lst";
$gap && (open SLG,">$outdir/soap-g.lst" || die$!);
my $draw_sh = "$shdir/draw.sh";
$draw && $cover && (open DR,">$draw_sh" || die$!);
my $suf = $gzip ? "soap.gz" : "soap";
my $sufg = $gzipg ? "soap.g.gz" : "soap.g";
my ($a,$b);
my @subdir = $subdir ? split/,/,$subdir : ();
$subdir[1] ||= "02.Coverage";
$reads2 && (($a,$b) = @ARGV[1,2], (goto AA));
open IN,$lane_lst || die$!;
while(<IN>){
    /\S/ || next;
    chomp;
    $a = $_;
    chomp($b =  <IN>);
    AA:{;}
    my ($lib, $lib2);
    if($onesp){
        $lib = $outdir;
    }elsif($subdir){
#        $lib = "$outdir/$subdir" . $num;$num++;
        $lib = "$outdir/$subdir[0]";
        $lib2 = "$outdir/$subdir[1]";
    }else{
        if($a =~/L\d+_([^_]+)_1\.fq/){ 
            $lib = ($samph{$1}||$1); $lib="$outdir/$lib";
        }elsif($reads2){
            $lib = $outdir;
        }elsif($a=~/.fq[12].gz/){
            $lib=$outdir;
        }else{die"error METHOD OF DEFINITION at $a\n";}
    }
    $lib2 ||= $lib;
    (-d $lib) || mkdir($lib);
    my $breads = (split/\//,$a)[-1];
    $breads =~ s/\.fq\.gz$//;
    print SH "cd $lib\n$Bin/soap2.21 -D $index -a $a -b $b -o $breads.PE.soap -2 $breads.SE.soap $soap 2> soap.log\n";
    $suf ||= ($gzip ? "soap.gz" : "soap");## I'm sorry to do that, But is realy an unkmow bug.
    print SL "$lib/$breads.PE.$suf\n$lib/$breads.SE.$suf\n";
    if($cover){
        (-d $lib2) || mkdir($lib2);
        my $index2 = $index;
        $index2 =~ s#\.index$|\s##;
        print SH "cd $lib2\n$Bin/soap.coverage -cvg -refsingle $index2 -i $lib/$breads.PE.soap $lib/$breads.SE.soap ",
              "-depthsingle soap.coverage.depthsingle -o coverage.depth -plot soap.coverage.plot 0 400 ",
              "$coveropt 2> cover.log\n";
        $draw && (print DR "cd $lib2\nperl $Bin/line_diagram.pl soap.coverage.plot --signh --frame -x_title ",
                "'Sequencing depth(X)' -y_title 'Sequencing depth frequence'  >coverage_depth.svg\n",
                "`/usr/bin/convert coverage_depth.svg coverage_depth.png` 2>/dev/null\n");
    }
    $gzip && (print SH "cd $lib; perl $Bin/multi-process.pl \"gzip $breads.PE.soap xx gzip $breads.SE.soap\"\n");
    print SH "\n";
    if($gap){
        my $g_soap = ($gap=~/\D/) ? $gap : "$soap -g $gap";
        print SH "cd $lib\n$Bin/soap2.21 -D $index -a $a -b $b -o $breads.PE.soap.g -2 $breads.SE.soap.g ",
              "$g_soap 2> soap-g.log\n";
        $gzipg && (print SH "perl $Bin/multi-process.pl \"gzip $breads.PE.soap.g xx gzip $breads.SE.soap.g\"\n");
        print SH "\n";
        print SLG "$lib/$breads.PE.$sufg\n$lib/$breads.SE.$sufg\n";
    }
    $reads2 && last;
}
$reads2 || close(IN);
close SH;
close SL;
$draw && $cover && close(DR);
$gap && close(SLG);
my $splits = '\'\n\n\'';
my $clean = $noclean ? " " : "-clean";
$locate ? system"cd $shdir; sh $prefix.sh" : 
#system"cd $shdir;perl $Bin/super_worker.pl run_soap.sh -splits $splits -prefix soap -maxjob $maxjob $clean -qopts=\"$qopts\" -resource $vf -logtxt soap.qsub.log -reqline -head \"#!/usr/bin/bash\"";
system"cd $shdir;perl $superwork_pl  $prefix.sh -splits $splits -prefix soap -maxjob $maxjob $clean -qopts=\"$qopts\" -resource $vf -logtxt soap.qsub.log -reqline -head \"#!/usr/bin/bash\"";
$verbous && (print STDERR localtime() . " --> finesh running soap\n");
if($draw && $cover){
    $verbous && (print STDERR localtime() . " --> star drawing sequencing depth distribution\n");
    `sh $draw_sh`;
    $verbous && (print STDERR localtime() . " --> finish drawing sequencing depth distribution\n");
}
