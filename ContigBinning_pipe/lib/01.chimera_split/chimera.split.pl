#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;

# set default options
my %opt = (
    #options for others
    "outdir","./","shdir","./Shell","prefix","scaftigs",

	#options for step1
	"cutlen",0,"win_size",3000,

    #options for step2
    "insert",350,"method",1,

    #options for others
    "step",1234,"vf","20G","dvf","2G", "threads", "10", 
);

#get options from screen
GetOptions(
    \%opt,
    #main options
    "data_list:s","clean_list:s","mf:s",

    #options for step1
    "cutlen:s","win_size:s",

    #options for step2
    "insert:s","method:s",

    #options for others
    "outdir:s","shdir:s","step:s","prefix:s","notrun","locate","threads:s","vf:s","dvf:s",
    
);

## get software's path
use lib "$Bin/../00.Commbin/";
my $lib = "$Bin/../";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my ($bowtieBuild,$super_worker,$bowtie2,$samtools,$bedtools,$genomeCoverageBed,$line_diagram,$svg2xxx,$ss) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(BWT_BUILD SUPER_WORKER BOWTIE2 SAMTOOLS BEDTOOLS GENOMECOVERAGEBED LINE_DIAGRAM SVG2XXX SS)],$Bin,$lib);
###software's path 
my $flexible_win="perl $Bin/lib/flexible.win.pl ";
my $screen_len="perl $Bin/lib/screening_by_length.pl ";
my $meancov_method1="perl $Bin/lib/mean_cov1.cal.pl ";
my $meancov_method2="perl $Bin/lib/mean_cov2.cal.pl ";
my $chimera="perl $Bin/lib/chimera.pl ";
my $get_table_scaf="perl $Bin/lib/get_table_scaf.pl ";


#====================================================================================================================
($opt{data_list} && -s $opt{data_list} && $opt{clean_list} && -s $opt{clean_list} && $opt{mf} && -s $opt{mf})|| 
die "Name: $0
Description: Script for chimera split	
Version: V1.0
Date: 2016年 05月 11日 星期三 15:53:47 CST 
Connector: lindan[AT]novogene.com
Usage1: perl $0 --data_list total.scaftigs.list --clean_list Dataclean.total.list --mf all.mf
        
        *-data_list  [str]  input scaftigs list for chimera split
        *-clean_list [str]  input clean data list for chimera split
        *-mf         [str]  group info for sample

    [options for step1]
        --cutlen     [str]  scaftigs length cut off for chimera split, set 0 for not screen, default=0,
        --win_size   [str]  windows size for flexible cutting,default = 3000
    	
    [options for step2]
        --insert     [str]  insert size for bowtie2's -I and -X,default=350
        --method     [str]  method for calculate coverage,1:bedtools,2:genomeCoverageBed, default=1
    

	[options for other]
        --outdir     [str]  project directory,default is ./
        --shdir      [str]  output shell script directory, default is ./Shell   
        --prefix     [str]  output prefix, default=Scaftigs.
        --vf         [str]  vf for step2,default=20G
        --dvf        [str]  dvf for step2,default=2G
        --threads    [str]  qsub threads for bowtie2,default=10
        --step       [num]  steps,default=1234
                                1. screen, flexible win, and build index 
                                2. bowtie2
                                3. chimera split
                                4. get stat info
        --notrun            just produce shell script, not run
        --locate            run locate

\n";
#===========================================================================================================================================

###get options
$opt{data_list}=abs_path($opt{data_list}) if $opt{data_list};
$opt{clean_list}=abs_path($opt{clean_list}) if $opt{clean_list};
$opt{mf}=abs_path($opt{mf}) if $opt{mf};
(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
$opt{outdir}=abs_path($opt{outdir});
(-s $opt{shdir}) || `mkdir -p $opt{shdir}`;
$opt{shdir}=abs_path($opt{shdir});

#options for step2
$bowtie2 .= " --threads $opt{threads} " if $opt{threads};
if ($opt{insert}) {
    my $insert_min=$opt{insert} - 60;
    my $insert_max=$opt{insert} + 60;
    $bowtie2 .= " -I $insert_min -X $insert_max " if $insert_min && $insert_max;
}

#====================================================================================================================
#main script
my ($locate_run,$qsub_run);
my $splits = '\n\n';

##step1:screen, flex_win and build index
my %sample2index;
my %sample2chimera;
if($opt{step}=~/1/ && $opt{data_list} && -s $opt{data_list}){
    (-s "$opt{outdir}/01.BowtieBuild") || mkdir "$opt{outdir}/01.BowtieBuild";
	open(SH,">$opt{shdir}/step1.bowtieBuild.sh");
	open(LIST,"$opt{data_list}");
	while (<LIST>) {
        chomp;
        my($sample,$scaf_fa)=(split/\s+/)[0,1];
        (-s "$opt{outdir}/01.BowtieBuild/$sample") || mkdir "$opt{outdir}/01.BowtieBuild/$sample";
        (-s "$opt{outdir}/01.BowtieBuild/$sample/Index") || mkdir "$opt{outdir}/01.BowtieBuild/$sample/Index";
        my $filename=$1 if $scaf_fa=~/.*\/(.*)/;
        print SH "cd $opt{outdir}/01.BowtieBuild/$sample\n";

        $opt{cutlen} ? 
        print SH "$screen_len $scaf_fa $opt{cutlen} > $filename\n" :
        print SH "ln -fs $scaf_fa\n";

        print SH "$flexible_win $filename $sample.$opt{prefix}.flexWin.fa flexWin.check.info.xls $opt{win_size}
$bowtieBuild $sample.$opt{prefix}.flexWin.fa Index/$sample.$opt{prefix}.flexWin &> Index/bwt.log\n\n";
        $sample2index{$sample}="$opt{outdir}/01.BowtieBuild/$sample/Index/$sample.$opt{prefix}.flexWin";
        $sample2chimera{$sample}="$chimera -check $opt{outdir}/01.BowtieBuild/$sample/flexWin.check.info.xls -fa $opt{outdir}/01.BowtieBuild/$sample/$filename ";
	}
	close LIST;
	close SH;
	$locate_run .= "sh step1.bowtieBuild.sh\n";
    $qsub_run .= "$super_worker step1.bowtieBuild.sh --resource 5G --qopts=\"-l num_proc=$opt{threads}\" --prefix bwt.build -splits '$splits' \n";
}

##step2:bowtie
if($opt{step}=~/1/ && $opt{clean_list} && -s $opt{clean_list} ){
    (-s "$opt{outdir}/02.Bowtie") || mkdir "$opt{outdir}/02.Bowtie";
    open(SH,">$opt{shdir}/step2.bowtie.sh");
    open(LIST,"$opt{clean_list}");
    while (<LIST>) {
        chomp;
        my($sample,$clean_fqs)=(split/\s+/)[0,1];
        next if ! $sample2index{$sample};

        my @clean_fqs=split/,/,$clean_fqs;
        (-s "$opt{outdir}/02.Bowtie/$sample") || mkdir "$opt{outdir}/02.Bowtie/$sample";
        print SH "cd $opt{outdir}/02.Bowtie/$sample
$bowtie2 --sensitive --no-mixed --no-discordant -x $sample2index{$sample} -1 $clean_fqs[0] -2 $clean_fqs[1] -S $sample.PE.bowtie.sam
$samtools view -bS $sample.PE.bowtie.sam > $sample.PE.bowtie.bam
$samtools sort $sample.PE.bowtie.bam $sample.PE.bowtie.sorted
rm $sample.PE.bowtie.sam\n";
        
        $opt{method} == 1 ?
        print SH "$bedtools genomecov -dz -ibam $sample.PE.bowtie.sorted.bam > $sample.PE.coverage
$meancov_method1 $sample.PE.coverage $sample.PE.meanCov.table\n\n" :
        $opt{method} == 2 ?
        print SH "$genomeCoverageBed -ibam $sample.PE.bowtie.sorted.bam > $sample.PE.coverage
$meancov_method2 $sample.PE.coverage $sample.PE.meanCov.table\n\n" : 1 ;

        print SH "cd $opt{outdir}/02.Bowtie/$sample
$bowtie2 --sensitive -x $sample2index{$sample} -1 $clean_fqs[0] -2 $clean_fqs[1] -S $sample.PESE.bowtie.sam
$samtools view -bS $sample.PESE.bowtie.sam > $sample.PESE.bowtie.bam
$samtools sort $sample.PESE.bowtie.bam $sample.PESE.bowtie.sorted
rm $sample.PESE.bowtie.sam\n";

        $opt{method} == 1 ?
        print SH "$bedtools genomecov -dz -ibam $sample.PESE.bowtie.sorted.bam > $sample.PESE.coverage
$meancov_method1 $sample.PESE.coverage $sample.PESE.meanCov.table\n\n" :
        $opt{method} == 2 ?
        print SH "$genomeCoverageBed -ibam $sample.PESE.bowtie.sorted.bam > $sample.PESE.coverage
$meancov_method2 $sample.PESE.coverage $sample.PESE.meanCov.table\n\n" : 1 ;

        $sample2chimera{$sample} .= " -cov_pese $opt{outdir}/02.Bowtie/$sample/$sample.PESE.meanCov.table -cov_pe $opt{outdir}/02.Bowtie/$sample/$sample.PE.meanCov.table ";
    }
    close LIST;
    close SH;
    $locate_run .= "sh step2.bowtie.sh\n";
    $qsub_run .= "$super_worker step2.bowtie.sh --resource $opt{vf} --prefix bowtie --dvf $opt{dvf} --qopts=\"-l num_proc=$opt{threads}\" -splits '$splits' \n";
}

##step3,chimera split
if($opt{step}=~/3/ && %sample2chimera){
    (-s "$opt{outdir}/03.ChimeraSplit") || mkdir "$opt{outdir}/03.ChimeraSplit";
    open(SH,">$opt{shdir}/step3.chimeraSplit.sh");
    foreach my $sample (sort keys %sample2chimera){
        (-s "$opt{outdir}/03.ChimeraSplit/$sample") || mkdir "$opt{outdir}/03.ChimeraSplit/$sample";
        print SH "cd $opt{outdir}/03.ChimeraSplit/$sample
$sample2chimera{$sample} --prefix $sample
$line_diagram ".'-fredb2 -fredb -numberc -vice -ranky2 "0:2" -samex -bar -frame  -y_title  "Frequence(#)" -y_title2 "Percentage(%)" -barstroke black -barstroke2 black -symbol -signs "Frequence(#),Percentage(%)" -color "cornflowerblue,gold" -linesw 2 -opacity 80 -opacity2 40  -sym_xy p0.6,p0.98  --sym_frame  -x_mun 0,500,6  -x_title "Scaftig Length(bp)"   --h_title'." '$sample Length Distribution' $sample.chimera.split.fa.len > $sample.len.svg
$svg2xxx -t png  $sample.len.svg
$ss $sample.chimera.split.fa 500 > $sample.scaftigs.500.ss.txt\n\n";
    }
    close SH;
    $locate_run .= "sh step3.chimeraSplit.sh\n";
    $qsub_run .= "$super_worker step3.chimeraSplit.sh --resource 1G  --prefix chimerasplit -splits '$splits' \n";
}

##step4, get stat info 
if($opt{step}=~/4/ ){
    (-s "$opt{outdir}/03.ChimeraSplit") || mkdir "$opt{outdir}/03.ChimeraSplit";
    open(SH,">$opt{shdir}/step4.chimeraStat.sh");
    print SH "cd $opt{outdir}/03.ChimeraSplit
ls $opt{outdir}/03.ChimeraSplit/*/*.scaftigs.500.ss.txt > total.scaftigs.ss.list
ls $opt{outdir}/03.ChimeraSplit/*/*.chimera.split.fa".' |perl -ne \'chomp;my$sample=$1 if($_=~/.*\/(.*).chimera.split.fa$/);print "$sample\t$_\n";\' > total.scaftigs.list'."
$get_table_scaf  --mf $opt{mf} --data_list $opt{outdir}/03.ChimeraSplit/total.scaftigs.ss.list --outdir $opt{outdir}/03.ChimeraSplit/ --outfile total.scaftigs.stat.info.xls\n\n";
    close SH;
    $locate_run .= "sh step4.chimeraStat.sh\n";
    $qsub_run .= "$super_worker step4.chimeraStat.sh --resource 1G  --prefix chimerastat -splits '$splits' \n";
}

open(SH,">$opt{shdir}/qsub.sh");
print SH $qsub_run;
close SH;

$opt{notrun} && exit;
$opt{locate} ? 
system"cd $opt{shdir}
$locate_run" :
system"cd $opt{shdir}
$qsub_run";


#====================================================================================================================
#sub routines
