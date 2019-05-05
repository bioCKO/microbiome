#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my %opt = (sd=>"0.2,0.3",run=>"qsub",soap_vf=>"4g","bwt_vf"=>"500M",soap_opts=>" -l 32 -s 40 -v 3 -r 1 -p 6",
cover_opts=>"-p 8",outdir=>".",maxjob=>400);
GetOptions(\%opt,"sd:s","run:s","soap_vf:s","bwt_vf:s","soap_opts:s","cover_opts:s","outdir:s",
    "gzip","verbose","maxjob:i","qopts:s","insert:s","workdir:s","sort");
(@ARGV != 2) && die"Name: soap_cover.pl
Describe: script to run SOAP2, soap.coverage for onesample or population
Author: liuwenbin, liuwenbin\@genomic.org.cn
Version: 1.0, Date: 2011-12-26
Usage: perl soap_cover.pl <reads.lis> <reference>  [-option]
    reads.lis           reads pathway list
    reference           reference fasta, when not end with .index, index lib will build for SOAP2
    --outdir <dir>      output directory, default=./
    --workdir <dir>     shell running directory, defualt=outdir/Shell
    --onesample         only one sample, default population
    --insert <str>      insert lst: name avg_ins, set to caculate -m -x, when PE reads
    --sd <str>          sd to caculate -m -x for small,big lane, default=0.2,0.3
    --qopts <str>       option for qsub, e.g. '-P test -q bc.q', default not set
    --run <srt>         parallel type, qsub, or multi, default=qsub
    --maxjob <num>      maxjob, default=400
    --soap_vf <str>     resource for SOAP, default 'vf=4g'
    --bwt_vf <str>      resource for 2bwt-builder, default vf=500M
    --soap_opts <str>   other soap option, default ' -l 32 -s 40 -v 3 -r 1 -p 6'
    --cover_opts <str>  soap.coverage option, default '-p 8'
    --sort              to sort the soap result
    --verbose           output running information to screen.
    --gzip              gzip soap result
\nNote:
    1 you had better set --insert, or eatch reads file seen as single reads.
    2 Under set outdir of eatch sample contin: 01.Soapalign/ 02.Coverage/, all process shell at Shell/
    3 The result for SOAP2 and soap.coverage are the same, set by -soap_vf option.
\nExample:
    nohup perl soap_cover.pl reads.lst all.scafSeq -gzip -insert InsertSize.txt &\n\n";


###   check error   ===========================================================================================
foreach(@ARGV,$opt{insert}){$_ &&= abs_path($_);}
my ($reads_lst, $index_lib) = @ARGV;
(-s $reads_lst) || die"error can't fine valid file: $reads_lst, $!\n";
foreach("run_soap_v1.0.pl","2bwt-builder","soap2.21","soap.coverage","super_worker.pl","line_diagram.pl","base.revision","soap2_insert.pl"){
    (-s "$Bin/$_") || die"error can't find $_ at $Bin, $!\n";
}
my ($bwt_builder,$run_soap,$super_worker) = ("$Bin/2bwt-builder","perl $Bin/run_soap_v1.0.pl","perl $Bin/super_worker.pl");
$opt{qopts} && ($super_worker .= " --qopts=\"$opt{qopts}\"");
####   bwt index   ===========================================================================================
(-d $opt{outdir}) || mkdir($opt{outdir});
$opt{outdir} = &abs_path($opt{outdir});
my $shdir = ($opt{workdir} || "$opt{outdir}/Shell");
(-d $shdir) || mkdir($shdir);
if(!(-s "$index_lib.index") && (-s "$index_lib.index.sai")){
	$index_lib .= ".index";
}elsif($index_lib !~ /\.index$/ || !(-s "$index_lib.sai")){
	my $indir = "$opt{outdir}/00.Index";
    (-d $indir) || mkdir"$indir";
	my $lin_lib = "$indir/" . (split/\//,$index_lib)[-1];
    (-s $lin_lib) || `ln -s $index_lib $indir`;
    $index_lib = $lin_lib;
    (-s "$index_lib.index.sai") && (goto BWT);
    open BSH,">$shdir/bul_bwt.sh" || die$!;
    print  BSH "cd $indir\n$bwt_builder $index_lib\n";
    close BSH;
    $opt{verbous} && (print STDERR localtime() . " --> building bwt\n");
	system"cd $shdir;$super_worker -resource $opt{bwt_vf} -splitn 1 -prefix bwt -sleept 60 bul_bwt.sh";
	$opt{verbous} && (print STDERR localtime() . " --> finish building bwt\n");
    BWT:{;}
    $index_lib .= ".index";
}
####   run soap2 and soap.coverage  =============================================================================
my $soap2_opts = " -step 12 -sd $opt{sd} -r mutil -p $opt{maxjob} -v $opt{soap_vf} -w $opt{bwt_vf} -s=\"$opt{soap_opts}\" -cp=\"$opt{cover_opts}\"";
$opt{gzip} && ($soap2_opts .= " -z");
$opt{insert} && (-s $opt{insert}) && ($soap2_opts .= " -l $opt{insert}");
my @dir;
my @sample_name = &get_sample($opt{outdir},$reads_lst,$opt{onesample},\@dir,'reads.lst');#sub2
open SH,">$shdir/run_soapcover.sh" || die$!;
foreach(@dir){
    print SH "cd $_\n$run_soap reads.lst $index_lib $soap2_opts\n\n";
}
close SH;
my $splits = '\n\n';
$opt{verbous} && (print STDERR localtime() . " --> start running saop2 and soap.coverage\n");
system"cd $shdir;$super_worker --maxjob $opt{maxjob} --resource $opt{soap_vf} --prefix soapcover --splits \"$splits\" run_soapcover.sh";
open STAT,">$opt{outdir}/all_coverage.table" || die"$!\n";
print STAT "Sample_name\tRef_len(bp)\tCover_length\tCoverage(%)\tDeapth(X)\n";
if($opt{sort}){
    open SH,">$shdir/sortSoap.sh" || die$!;
    open SL,">$opt{outdir}/sortSoap.lst" || die$!;
}
foreach my $i(0..$#dir){
#    my @covst = (split/\s+/,`tail -1 $dir[$i]/02.Coverage/coverage_depth.table`)[2,1,3,4];
#    print STAT join("\t",$sample_name[$i],@covst)."\n";
    my $covst;
    if(-s "$dir[$i]/02.Coverage/coverage_depth.table"){
        $covst = `tail -1 $dir[$i]/02.Coverage/coverage_depth.table`;
        $covst =~ s/^\S+/$sample_name[$i]/;
    }else{
        $covst = join("\t",$sample_name[$i],0,0,0,0)."\n";
    }
    print STAT $covst;
    if($opt{sort}){
        print SH "cd $dir[$i]/01.Soapalign;less ./* | $Bin/msort -k m8,n9 > $sample_name[$i].soap.sort\n";
        print SL "$sample_name[$i]=$dir[$i]/01.Soapalign/$sample_name[$i].soap.sort\n";
    }
}
close STAT;
$opt{verbous} && (print STDERR localtime() . " --> finish running saop2 and soap.coverage\n");
if($opt{sort}){
    $opt{verbous} && (print STDERR localtime() . " --> start to sort soap2 result\n");
    system"cd $shdir;$super_worker --maxjob $opt{maxjob} --resource $opt{soap_vf} --prefix sort sortSoap.sh";
    $opt{verbous} && (print STDERR localtime() . " --> finish running sort soap2 result\n");
}


## ================================================================================================================
#sub1
sub abs_path{chomp(my $tem=`pwd`);($_[0]=~/^\//) ? $_[0] : "$tem/$_[0]";}
#sub2
#==============
sub get_sample{
#==============
    my ($outdir,$readl,$onesample,$dir,$fname) = @_;
    open IN,$readl;
    my (%readh,%dirh);
    if($onesample){
       $dirh{all} = $outdir;
    }
    while(<IN>){
        if($onesample){
            $readh{all} .= $_;
        }else{
            my $temdir;
            if(/(\S+)\s+(\S+\n)/){
                ($temdir,$_) = ($1, $2);
            }else{
                $temdir = (split/\//)[-2];
            }
            $readh{$temdir} .= $_;
            $dirh{$temdir} = $outdir . '/' . $temdir;
        }
    }
    close IN;
    my @sample_name;
    foreach my $d(keys %readh){
        (-d $dirh{$d}) || `mkdir -p $dirh{$d}`;
        open RE,">$dirh{$d}/$fname" || die"$!\n";
        print RE $readh{$d};
        close RE;
        push @$dir,$dirh{$d};
        push @sample_name,$d;
    }
    @sample_name;
}
