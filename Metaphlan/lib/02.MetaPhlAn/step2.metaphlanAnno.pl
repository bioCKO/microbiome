#!/usr/bin/perl -w
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use strict;

#set options
my($data_list, $vf, $num_proc, $locate_run, $notrun, $shdir, $outdir, $help);
#set default options
$num_proc ||= 10;
$shdir ||= "./Shell";
$outdir ||= ".";
$vf ||= "5g";

#get options
GetOptions(
        "data_list:s" => \$data_list,
        "num_proc:s" => \$num_proc,
        "vf:s" => \$vf,
        "notrun" => \$notrun,
        "shdir:s" => \$shdir,
        "outdir:s" => \$outdir,
        "help" => \$help,
        );

(-d $shdir) || system("mkdir -p $shdir");
$shdir=abs_path($shdir);
(-d $outdir) || system("mkdir -p $outdir");
$outdir=abs_path($outdir);
$data_list && ($data_list=abs_path($data_list));

# get software's path
use lib "$Bin/../../lib/00.Commbin";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin, $!\n";
my ($super_worker, $bowtie2db_mpa) = get_pathway("$Bin/../../bin/Pathway_cfg.txt", [qw(SUPER_WORK BOWTIE2DB_MPA)]);
my $fq2fa = "$Bin/lib/fq2fa.pl";
$help = "Name: $0
Description: script for MetaPhlAn TaxAnno 
Version:1.0
Date: 2016-06-08,the day before Dragon Boat Festival.
Connector: lindan[AT]novogene.com
Usage1: perl $0 --data_list data.list --outdir . --shdir Shell --notrun

[options for version1]
        *--data_list [file]        sample cleandata list, with format1:
                                   sample1ID        fq1,fq2
                                   sample2ID        fq1,fq2
                                   ...
                                   or with format2:
                                   sample1ID        fq
                                   sample2ID        fq
                                   ...

[other options]
         --vf        [str]         vf for metaphlan.anno,default=20G
         --num_proc   [str]        set number of threads for metaphlan.anno, default=10
         --shdir      [str]        output shell script directory, default is ./Shell
         --outdir     [str]        project directory,default is ./
         --notrun     [str]        just produce shell script, not run
         --locate                  locate run, only locate run.
\n";
#metaphlan tax anno
if($data_list && -s $data_list || die "$help"){
    my (@sampleids, @cleandata, $fq_list);
    open F, $data_list;
    open SH, ">$shdir/metaphlan.anno.pipeline.sh";
    print SH "#metaphlan tax anno\nmkdir $outdir/input\nmkdir $outdir/profiled_samples\n";
    while(<F>){
        chomp;
        my $sampleid = (split /\s+/, $_)[0];
        push @sampleids, $sampleid;
# my $headline = `head -1 $cleandata`;
#       if($headline =~ /^>/){
#           $datatype = "multifasta";
#       }else{$datatype = "multifastq";}
    }close F;
    open SH1, ">$shdir/prepare_data.bzip2.sh";
    print SH1 "perl $fq2fa --fqlist $data_list --merge --out $outdir/input\n";
    close SH1;
    print SH "
$super_worker $shdir/prepare_data.bzip2.sh --resource $vf --prefix prepare_data.bzip2 --workdir $shdir/prepare_data.bzip2\n";
    my $samplelist = join(" ",@sampleids);
    open SH2, ">$shdir/prepare_metaphlan.anno.sh";
    print SH2 "   
cd $outdir
samples=\"$samplelist\"
for s in \${samples}
do
    if test -s $outdir/\${s}.bt2out
    then 
    echo \"$Bin/lib/metaphlan.py --input_type bowtie2out $outdir/\${s}.bt2out >/TJPROJ1/MICRO/lindan/DevelopResearch/MetaPhlan/MetaPhlAnPipeline/example/example2/output/02.MetaPhlAn/profiled_samples/\${s}.txt\"    
    else
        if test -f $outdir/\${s}.bt2out
        then
        echo \"rm $outdir/\${s}.bt2out\ntar xjf $outdir/input/\${s}.tar.bz2 --to-stdout | $Bin/lib/metaphlan.py --bowtie2db $bowtie2db_mpa --bt2_ps very-sensitive --nproc $num_proc --input_type multifasta --bowtie2out $outdir/\${s}.bt2out > $outdir/profiled_samples/\${s}.txt\"
        else 
        echo \"tar xjf $outdir/input/\${s}.tar.bz2 --to-stdout | $Bin/lib/metaphlan.py --bowtie2db $bowtie2db_mpa --bt2_ps very-sensitive --nproc $num_proc --input_type multifasta --bowtie2out $outdir/\${s}.bt2out > $outdir/profiled_samples/\${s}.txt\"
        fi
    fi
done"; close SH2;
    print SH "
sh $shdir/prepare_metaphlan.anno.sh >$shdir/metaphlan.anno.sh
$super_worker $shdir/metaphlan.anno.sh --resource $vf --prefix metaphlan.anno --workdir $shdir/metaphlan.anno\n";
    print SH "
#abundance table merge

$Bin/lib/utils/merge_metaphlan_tables.py $outdir/profiled_samples/*.txt > $outdir/merged_abundance_table.txt
$Bin/lib/plotting_scripts/metaphlan_hclust_heatmap.py -c bbcry --minv 0.1 -s log --in $outdir/merged_abundance_table.txt --out $outdir/abundance_heatmap.png\n";
#abundance trans
    print SH "
#relative abundance
mkdir $outdir/relative
perl $Bin/lib/abundance.trans.pl $outdir/merged_abundance_table.txt $outdir/relative
perl $Bin/lib/abundance.trans.others_add.pl $outdir/relative\n";
close SH;
}

$locate_run .= "sh metaphlan.anno.pipeline.sh\n";
open SH, ">$shdir/locate.sh"|| die"Error:cannot creat $shdir/locate.sh\n";
    print SH $locate_run;close SH;

$notrun && exit;
system"cd $shdir 
$locate_run";


