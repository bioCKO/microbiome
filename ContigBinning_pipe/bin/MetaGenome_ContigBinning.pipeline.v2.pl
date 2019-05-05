#!/usr/bin/perl

use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

#set default options
my %opt = (
    #main options 
    "step", "1234", "insertsize", 350, "VF", "20g/2g;50g/10g;10g/2g", "threads", "10;20;5", 
    #options for step2
    "length_threshhold", 1500, "binning_evalue_method", "1", "choose2draft_binningmethod", "1", 
    #options for step3
    "kmer_range","17:77:10",
    #other options 
    "outdir", ".", "shdir", "./Shell/detail", 
);

#get options from screen
GetOptions(
        \%opt,
        #main options
        "data_list:s","clean_list:s","mf:s","info:s","step:s","insertsize:s","VF:s","qopts:s","get_result","get_report",
        #options for step2
        "length_threshhold:n","binning_evalue_method:s","choose2draft_binningmethod:s",
        #options for step3
        "kmer_range:s",
        #other options
        "outdir:s","shdir:s","notrun",
);

## get software's path
use lib "$Bin/../lib/00.Commbin/";
my $lib = "$Bin/../lib";
use PATHWAY;
(-s "$Bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/,$!\n";
my ($super_worker) = get_pathway("$Bin/Pathway_cfg.txt",[qw(SUPER_WORKER)],$Bin, $lib);
my $chimera_split = "perl $Bin/../lib/01.chimera_split/chimera.split.pl";
my $contig_binning = "perl $Bin/../lib/02.contig_binning/contig_binning.pl";
my $draftGenome_analysis = "perl $Bin/../lib/03.draftGenome_analysis/draftGenome.analysis.pl";
my $get_result = "perl $Bin/../lib/04.Result_Report/Getresult.pl";
my $get_report = "perl $Bin/../lib/04.Result_Report/Getreport.pl";

#========================================================================================================================================
($opt{data_list} && -s $opt{data_list} && $opt{clean_list} && -s $opt{clean_list} && $opt{mf} && -s $opt{mf}) || die
"Name:$0
Description: Pipeline for MetaGenome Contig-Binning Analysis
Version: V2.0
Date:
Connector: lindan[AT]novogene.com
Usage1: perl $0 --data_list ass.list --clean_list reads.list --insertsize 350 --length_threshhold 1500 --read_length 125

[options for version1]
        *-data_list        [str] for step1, standard assembly result(before chimera correction), with format: 
                                  sample1ID   assembly seq path
                                  sample2ID   assembly seq path
                                  ...
        *-clean_list       [str] clean data fq list, with format:
                                  sample1ID   reads1 fq, reads2 fq
                                  sample2ID   reads1 fq, reads2 fq
                                  ...
                                  fq could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
        *-mf               [str]  group info for sample
        --insertsize        [str] set insert size, default=350
        --VF               [str] set vf/dvf for 1) bowtie/soap-mapping(step123)、2) MetaBAT contig-binning(step2)、3) spades-assembly(step3),default: 20g/2g;50g/10g;10g/2g. Note the vf/dvf of Concoct contig-binning(step2) will be set fourfold of MetaBAT by default. The default set (20g/2g;50g/10g;10g/2g) is suited for the case when the total data size is  below 100g(sum all sample's data). The set of 2) may be multiple set in growing with the total data size while 1) 3) kept the same; for the case of 200g total size, the set may be \"20g/2g;100g/20g;10g/2g\".
        --threads          [str] set qsub threads for 1) bowtie/soap-mapping(step123)、2) metabat contig-binning(step2)、3) spades-assembly(step3),default: 10;20;5. Note the vf/dvf of Concoct contig-binning will be set twice of MetaBAT. The default set (10;20;5) is suited for the case when the total data size is below 100g(sum all sample's data). When the data size grows, e.g.200g, the set of 2) may be 0.5 times faster grows while 1) 3) kept the same, as result of \"--threads 10;30;5\".
        --step             [str] default: 1234
                                  1: for chimera split analysis
                                  2: for contig binning anslysis
                                  3: for draft genome anslysis
                                  4: get result and report

            #for step2:
            --binning_evalue_method    [str] choose contig-binning and binning clusters'quality evaluation methods combination for step2, 1: MetaBAT and CheckM; 2: MetaBAT and SCG; 3: Concoct and ChechM; 4: Concoct and SCG. Default=1. If set=1234, then the both contig-binning methods (MetaBAT and Concoct) will be run and each will be checked by both the clusters'quality evaluation methods (ChechM and SCG).
            --choose2draft_binningmethod [str] choose which binning evaluation method result should be used for the following draft analysis. only one number chosen from [1234]. 1: MetaBAT and CheckM; 2: MetaBAT and SCG; 3: Concoct and ChechM; 4: Concoct and SCG. Default=1. 
            
            #for step3:
            --kmer_range        [str] set the range of kmers for spades assembly, default: 17:77:10, i.e., 17,27,37,47,...77.
             

[other options]
        --outdir      [str]       project directory,default is ./
        --shdir       [str]       output shell script directory, default is ./Shell  
        --notrun                  just produce shell script, not run
\n";
#=============================================================================================================================================

$opt{data_list} = abs_path($opt{data_list});
$opt{clean_list} = abs_path($opt{clean_list});
$opt{mf} = abs_path($opt{mf});
($opt{info} && -s $opt{info}) && ($opt{info} = abs_path $opt{info}) && ($get_report.=" --info $opt{info} ");
(-d $opt{outdir}) || `mkdir -p $opt{outdir}`; 
(-d $opt{shdir}) || `mkdir -p $opt{shdir}`;
$opt{outdir} = abs_path($opt{outdir}); 
$opt{shdir} = abs_path($opt{shdir});
$opt{outdir} =~ s/\/$//g; 
$opt{shdir} =~ s/\/$//g;
#$opt{VF} =~ s/[\"|\"]//g;
my @VF = split/;/,$opt{VF};
my (@vfs,@dvfs);
foreach(@VF){my ($vf, $dvf) = split/\//,$_; push @vfs, $vf; push @dvfs, $dvf;}
my @threads = split/;/,$opt{threads};

my $chimera_data;
if($opt{step}=~/1/){
  (-s "$opt{outdir}/01.chimera_split") || `mkdir -p $opt{outdir}/01.chimera_split`; (-s "$opt{shdir}/01.chimera_split") || `mkdir -p $opt{shdir}/01.chimera_split`; 
  open(SH, ">$opt{shdir}/01.chimera_split.sh");
  print SH "$chimera_split -data_list $opt{data_list} -clean_list $opt{clean_list} -mf $opt{mf} -vf $vfs[0] --dvf $dvfs[0] --threads $threads[0] --shdir $opt{shdir}/01.chimera_split --outdir $opt{outdir}/01.chimera_split\n";
  close SH;
  $chimera_data = "$opt{outdir}/01.chimera_split/03.ChimeraSplit/total.scaftigs.list";
}

my ($bins_list,$binCov_list);
if($opt{step}=~/2/){
  (-s "$opt{outdir}/02.contig_binning") || `mkdir -p $opt{outdir}/02.contig_binning`; (-s "$opt{shdir}/02.contig_binning") || `mkdir -p $opt{shdir}/02.contig_binning`;
  open(SH, ">$opt{shdir}/02.contig_binning.sh");
  print SH "$contig_binning -data_list $chimera_data -clean_list $opt{clean_list} -VF \"$vfs[0]\/$dvfs[0];$vfs[1]\/$dvfs[1]\" --threads \"$threads[0];$threads[1]\" --insertsize $opt{insertsize} --binning_evalue_method $opt{binning_evalue_method} --outdir $opt{outdir}/02.contig_binning --shdir $opt{shdir}/02.contig_binning\n";
  close SH;
  ($opt{choose2draft_binningmethod} eq "1") ?
  ($bins_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/metabat_binning_evaluate/step2.metabat.CheckM_eval/bins.list") && ($binCov_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/metabat_binning_evaluate/step2.metabat.CheckM_eval/CheckM.substantial_bin.stat.xls") :
  ($opt{choose2draft_binningmethod} eq "2") ?
  ($bins_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/metabat_binning_evaluate/step2.metabat.SCG_eval/bins.list") && ($binCov_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/metabat_binning_evaluate/step2.metabat.SCG_eval/SCG.substantial_bin.stat.xls") :
  ($opt{choose2draft_binningmethod} eq "3") ?
  ($bins_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/concoct_binning_evaluate/step4.concoct.CheckM_eval/bins.list") && ($binCov_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/concoct_binning_evaluate/step4.concoct.CheckM_eval/CheckM.substantial_bin.stat.xls") :
  ($opt{choose2draft_binningmethod} eq "4") ?
  ($bins_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/concoct_binning_evaluate/step4.concoct.SCG_eval/bins.list") && ($binCov_list = "$opt{outdir}/02.contig_binning/step2.contig_binning_evaluation/concoct_binning_evaluate/step4.concoct.SCG_eval/SCG.substantial_bin.stat.xls"):
  0;
}

if($opt{step}=~ /3/){
  (-s "$opt{outdir}/03.draftGenome_analysis") || `mkdir -p $opt{outdir}/03.draftGenome_analysis`; (-s "$opt{shdir}/03.draftGenome_analysis") || `mkdir -p $opt{shdir}/03.draftGenome_analysis`;
  open(SH, ">$opt{shdir}/03.draftGenome_analysis.sh");
  print SH "$draftGenome_analysis -data_list $bins_list -clean_list $opt{clean_list} -binCov_list $binCov_list -insertsize $opt{insertsize} -VF \"$vfs[0]\/$dvfs[0];$vfs[2]\/$dvfs[2]\" --threads \"$threads[0];$threads[2]\" --kmer_range $opt{kmer_range} --shdir $opt{shdir}/03.draftGenome_analysis --outdir $opt{outdir}/03.draftGenome_analysis\n";
  close SH;
}

if($opt{step}=~ /4/){
  open (SH, ">$opt{shdir}/04.get_result_report.sh");
  (-s "$opt{outdir}/Result") || `mkdir -p $opt{outdir}/Result`;
  print SH "$get_result --binning_evalue_method $opt{binning_evalue_method} --ori_out $opt{outdir} --outdir $opt{outdir}/Result\n";
  if($opt{step}=~ /3/){
      print SH
      "$get_report --step 123 --binning_evalue_method $opt{binning_evalue_method} -resultdir $opt{outdir}/Result --outdir $opt{outdir}\n";
  }else{
      print SH
      "$get_report --step 12 --binning_evalue_method $opt{binning_evalue_method} -resultdir $opt{outdir}/Result --outdir $opt{outdir}\n";
  } 
  close SH;
}

my $run_shell = "cd $opt{shdir}\nsh 01.chimera_split.sh\nsh 02.contig_binning.sh\nsh 03.draftGenome_analysis.sh\nsh 04.get_result.sh\n";
open(SH,">$opt{shdir}/MetaGenome_ContigBinning.pipeline.sh");
print SH $run_shell;
close SH;

$opt{notrun} || system"cd $opt{shdir}\n$run_shell";




