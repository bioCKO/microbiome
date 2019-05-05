#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
# set default options
my %opt = (step=>'1234',soap=>' -l 32 -m 260 -x 340 -s 40 -v 13 -g 5 -r 1 -p 4 ',bwtvf=>'4G',vf=>'8G',outdir=>'./',coverage=>'  -depthsingle soap.coverage.depthsingle -o coverage.depth -plot soap.coverage.plot 0 400  -p 4 ',draw=>' --signh --frame -x_title \'Sequencing depth(X)\' -y_title \'Sequencing depth frequence\' ',prefix=>'Unigenes',cutoff=>2,fq_pattern=>'.*\_(\d+)(\.nohost)*\.fq[12].gz');
#get options from screen
GetOptions(
    \%opt,"index:s","data_list:s","step:s","soap:s","bwtvf:s","vf:s","qopts:s","help:s","outdir:s","shdir:s","locate","notrun","coverage:s","draw:s","table:s","genel:s","cutoff:n","mf:s","index_f:s","prefix:s","aa:s","fq_pattern:s",
);

#get software pathway
use lib "$Bin/../../00.Commbin";
my $lib = "$Bin/../../../lib";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($super_worker,) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SUPER_WORK )],$Bin,$lib);
my $soap="$Bin/lib/soap2.21 ";
my $soap_coverage="$Bin/lib/soap.coverage ";
my $index_builder="$Bin/lib/2bwt-builder ";
my $draw_line ="perl $Bin/lib/line_diagram.pl ";
my $cover_table ="perl $Bin/lib/cover_table.pl ";
my $scaftigs_profiling ="perl $Bin/lib/scaftigs_profiling.pl ";
my $gene_profiling="perl $Bin/lib/GeneProfiling.pl ";
my $gene_profiling_total="perl $Bin/lib/Gene_profiling_total.pl ";
my $soapExtra="perl $Bin/lib/SoapExtra.pl ";
## get help information
if($opt{help}){
    ($opt{help} eq 'sp') ? system "$soap " :
    ($opt{help} eq 'sc') ? system "$soap_coverage":
    ($opt{help} eq 'draw') ? system "$draw_line --help ":
    ($opt{help} eq 'table') ? system "$scaftigs_profiling":
    die"error: --help just can be selected from sp|sc\n";
    exit;
}
#====================================================================================================================
(($opt{index} && -s $opt{index}) || ($opt{index_f} && -s $opt{index_f}) && $opt{data_list} && (-s $opt{data_list}))|| 
die "Name: $0
Description: script for reads mapping, coverage, table produce 
Version: V3.0 (2015-06-08)
Update:  Date:2015-02-05, add for relative mat and cluster tree
         Date:2015-04-12, add for index_f
         Date:2015-04-18, add for readsNum, genel option
Connector: chenjunru[AT]novogene.com
Usage1: perl $0 --index Uniq.scaftigs.fa --data_list CleanData.list
Usage2: perl $0 --index_f total.scaftigs.list --data_list CleanData.list
    *--index      [str]  soap -D set, when not end with .index, index lib will build
    *--data_list  [str]  file that contain clean reads information, multiple samples can accepted,format is sample\\tCleanReads1,CleanReads2
    --index_f     [str]  soap -D set, a file that contain different samples,format=sample\\tindex\\n
[options for step1:]
    --aa          [str]  input a protein file for the last screening, if not set ,default is screening index file.
    --soap        [str]  soap options, default=\" -l 32 -m 260 -x 340 -s 40 -v 13 -g 5 -r 1 -p 4 \"
    --coverage    [str]  soap.coverage options, default=\" -depthsingle soap.coverage.depthsingle -o coverage.depth -plot soap.coverage.plot 0 400  -p 4 \"
    --fq_pattern  [str]  the pattern for fq file,default is '.*\_(\\d+)(\.nohost)*\.fq[12].gz'
    --draw        [str]  options for step 3,default=\" --signh --frame -x_title 'Sequencing depth(X)' -y_title 'Sequencing depth frequence' \"
    --prefix      [str]  options for output prefix ,default=Unigenes
    --genel       [str]  options for step4, Gene lenth file, if not set, readsnum table will not produced.
    --cutoff      [num]  set the cutoff for step4(readsNum),default=2 (must have one samples' readsNum > 2)
    --mf          [str]  set sample order for tables, the first line is sampleName.default is no order.
    --outdir      [str]  output directory,default is ./
    --shdir       [str]  output shell directory, default is outdir/Shell
    --bwtvf       [str]  resource for 2bwt-builder and step34, default vf=4G
    --vf          [str]  resultce for soap and coverage qsub, deault=8G
    --qopts       [str]  other qsub options, default='  '
    --notrun             just produce shell script, not qsub
    --locate             run locate,not qsub
    --step        [str]  default is 1234
                            1. reads mapping for sample
                            2. soap.coverage for every sample
                            3. draw coverage depth distribution figure.
                            4. depth,coverage,readsnum table produce(for multiple samples and index option)
    --help        [str]  sp: get help information for soap
                         sc: get help information for soap.coverage
                         draw: get help information for draw coverage depth distribution figure.
                         table: get help information for table produce
Note:
1. In order to run step 2, you must run step 1
2. In order to run step 3, you must run step 2
3. In order to run step 4, you must run step 2
4. At last, It will produce five files at outdir/Total,one for length and depth, one for coverage, one for length and coverage length, one for coverage.single, one for fa after screening depth=0;
5. when you runnig step2, it will produce two files at outdir, soap.coverage.list for coverage.depth.table, soap.coverage.single.list for soap.coverage.depthsingle
6. By default,the script will check the index option,if It not end with .index,run step0.sh
7. At last,It will produce shell scripts named by step[01234], and then locate or qsub
8. Step4 will be excluded for index_f\n";
#===========================================================================================================================================
###get options
$soap_coverage .= "  -cvg ";
$opt{data_list}=abs_path($opt{data_list});
$opt{mf} && ($opt{mf}=abs_path($opt{mf})) && ($gene_profiling_total .= " --mf $opt{mf} ");
$opt{mf} && ($scaftigs_profiling .= " --mf $opt{mf} ");

$opt{soap} && ($soap .= " $opt{soap} ");
$opt{outdir}=abs_path($opt{outdir});
$opt{shdir} ||= "$opt{outdir}/Shell";
my $super_worker_bwt = " $super_worker --resource $opt{bwtvf} ";
my $super_worker_soap = " $super_worker --resource $opt{vf} --prefix soap ";
$opt{qopts} && ($super_worker_bwt .= " -qopts \" $opt{qopts} \" " );
$opt{qopts} && ($super_worker_soap .= " -qopts \" $opt{qopts} \" " );
$opt{coverage} && ($soap_coverage .= " $opt{coverage} ");
$opt{draw} && ($draw_line .= " $opt{draw} ");
$opt{prefix} && ($scaftigs_profiling .= " --prefix $opt{prefix} ");
$opt{prefix} && ($gene_profiling_total.=" --prefix $opt{prefix} ");
$opt{genel} && ($opt{genel}=abs_path($opt{genel}));
$opt{genel} && ($gene_profiling_total .= " --len $opt{genel} ");
$opt{genel} && ($gene_profiling .= " --len $opt{genel} ");
$opt{cutoff} && ($gene_profiling_total.=" --cutoff $opt{cutoff} ");
$opt{aa} && ($opt{aa}=abs_path($opt{aa}));
$opt{aa} && ($gene_profiling_total .= " --fa $opt{aa} ");
#====================================================================================================================
#main script
(-s $opt{outdir}) || `mkdir -p  $opt{outdir}`;
(-s $opt{shdir}) || `mkdir -p  $opt{shdir}`;

my (%sample2coverage,$locate_run,$qsub_run);
my $splits = '\n\n';
## step 0, for soap index
my (%soap_coverage,%scaftigs_profiling,%soap);
if ($opt{index} && -s $opt{index}) {
    $opt{index}=abs_path($opt{index});
    $opt{index} &&  ($soap_coverage .= " -refsingle $opt{index} ");
    $opt{index} && ($scaftigs_profiling .= " --fa $opt{index} ");
    $opt{index} && !($opt{aa} && -s $opt{aa})  && ($gene_profiling_total .= " --fa $opt{index} ");
    my $bname = (split/\//,$opt{index})[-1];
    if(-s "$opt{index}.index.sai"){
        $soap .= " -D $opt{index}.index ";
    }elsif($opt{index} =~ /(.*)\.index$/ && -s "$opt{index}.sai"){
        $soap .= " -D $opt{index} ";
    }else{
        my $index_dir = $opt{outdir} . "/00.Index";
        (-d $index_dir) || mkdir "$index_dir";
        (-s "$index_dir/$bname") || system"ln -s $opt{index} $index_dir";
        open BWT,">$opt{shdir}/step0.bwt.sh" || die$!;
        print BWT "cd $index_dir\n",
        "$index_builder $bname 2> bwt.log\n\n";
        close BWT;
        $soap .= " -D $index_dir/$bname.index ";
        $locate_run .= "sh step0.bwt.sh\n";
        $qsub_run .= "$super_worker_bwt step0.bwt.sh  -splits '$splits' --prefix bwt --qopts ' -q mem2.q -P mem2 ' \n";
    }
}elsif($opt{index_f} && -s $opt{index_f}){
    open(OR,"$opt{index_f}");
    open BWT,">$opt{shdir}/step0.bwt.sh" || die$!;
    while (my $or=<OR>) {
        chomp$or;
        next if($or=~/^#/);
        my ($sample,$index_name)=(split/\s+/,$or)[0,1];
        (-s "$opt{outdir}/$sample") || `mkdir -p $opt{outdir}/$sample`;
        $soap_coverage{$sample} = $soap_coverage." -refsingle $index_name ";
        my $bname = (split/\//,$index_name)[-1];
        if(-s "$index_name.index.sai"){
            $soap{$sample} = $soap." -D $index_name.index ";
        }elsif($index_name =~ /(.*)\.index$/ && -s "$index_name.sai"){
            $soap{$sample} = $soap." -D $index_name ";
        }else{
            my $index_dir = "$opt{outdir}/$sample/00.Index";
            (-d $index_dir) || `mkdir -p $opt{outdir}/$sample/00.Index`;
            (-s "$index_dir/$bname") || system"ln -s $index_name $index_dir";  
            print BWT "cd $index_dir\n",
            "$index_builder $bname 2> bwt.log\n\n";  
            $soap{$sample} = $soap." -D $index_dir/$bname.index ";
        }
    }
    close BWT;
    close OR;
    $locate_run .= "sh step0.bwt.sh\n";
    $qsub_run .= "$super_worker_bwt step0.bwt.sh  -splits '$splits' --prefix bwt \n";
}


## step 1, reads mapping for sample
if($opt{step} =~/1/) {
    open(SH,">$opt{shdir}/step1.run_MGsoap.sh");
    open(OR,"$opt{data_list}") || die $!;
    open(LIST,">$opt{outdir}/soap.readsNum.list");
    open(LISTUM,">$opt{outdir}/soap.unmapping.list");
    while (<OR>) {
        chomp;
        my @or=split/\s+/;
        my $sample=$or[0];
        my @clean_reads=split/,/,$or[1];
        my $filename=(split/\//,$clean_reads[0])[-1];
        my $insertsize=$1 if ($filename=~/$opt{fq_pattern}/);
        my $basename="$sample\_$insertsize";
        (-s "$opt{outdir}/$sample") || mkdir "$opt{outdir}/$sample";
        if($opt{index_f} && -s $opt{index_f}){
            $soap{$sample} ? 
            print SH "cd $opt{outdir}/$sample\n",
            "$soap{$sample} -a $clean_reads[0] -b $clean_reads[1] -o $basename.PE.soap -2 $basename.SE.soap -u $basename.unmapping.fa 2> soap.log\n" :
            warn "step1:the index_f for SAMPLE:$sample can not find, please check index_f\n";
            print SH 
            "$soapExtra $clean_reads[0] $clean_reads[1] $basename.unmapping.fa $basename.unmapping\n";
            $opt{genel} ?
            print SH 
            "$gene_profiling --pe $basename.PE.soap --se $basename.SE.soap --out $sample.readsNum.xls\n\n" :
            print SH "\n";
            print LIST "$sample\t$opt{outdir}/$sample/$sample.readsNum.xls\n";
            print LISTUM "$sample\t$opt{outdir}/$sample/$basename.unmapping.fq1.gz,$opt{outdir}/$sample/$basename.unmapping.fq2.gz\n";
        }else{
            print SH "cd $opt{outdir}/$sample\n",
            "$soap -a $clean_reads[0] -b $clean_reads[1] -o $basename.PE.soap -2 $basename.SE.soap  -u $basename.unmapping.fa 2> soap.log\n";
            print SH 
            "$soapExtra $clean_reads[0] $clean_reads[1] $basename.unmapping.fa $basename.unmapping\n";
            $opt{genel} ?
            print SH
            "$gene_profiling --pe $basename.PE.soap --se $basename.SE.soap --out $sample.readsNum.xls\n\n":
            print SH "\n";
            print LIST "$sample\t$opt{outdir}/$sample/$sample.readsNum.xls\n";
            print LISTUM "$sample\t$opt{outdir}/$sample/$basename.unmapping.fq1.gz,$opt{outdir}/$sample/$basename.unmapping.fq2.gz\n";
        }
        $sample2coverage{$sample} .= "$basename.PE.soap $basename.SE.soap ";
    }
    close SH;
    close OR;
    close LIST;
    close LISTUM;
    $gene_profiling_total .= "  --data_list $opt{outdir}/soap.readsNum.list ";
    $locate_run .= "sh step1.run_MGsoap.sh\n";
    $qsub_run .= "$super_worker_soap step1.run_MGsoap.sh  -splits '$splits'\n";
=soaplist
    foreach my $sample (keys %sample2coverage){
        open(SOAPLIST,">$opt{outdir}/$sample/soap.list");
        my $soaplist=$sample2coverage{$sample};
        $soaplist=~s/\s+/\n/g;
        print SOAPLIST "$soaplist";
        close SOAPLIST;      
    }
=cut
}

## step2,soap.coverage for every sample
if ($opt{step}=~/2/ ) {
    die "Running step2:step 1 must be choosen!\n" if($opt{step}!~/1/);
    ## before step2, get soap.coverage.list by order.
    open(LIST,">$opt{outdir}/soap.coverage.list");
    open(OUTPUT,">$opt{outdir}/soap.coverage.single.list");
    if ($opt{mf}) {
        open(MF,"$opt{mf}");
        while (<MF>) {
            chomp;
            my @or=split/\s+/;
            print LIST "$or[0]\t$opt{outdir}/$or[0]/coverage.depth.table\n";
            print OUTPUT "$or[0]\t$opt{outdir}/$or[0]/soap.coverage.depthsingle\n";
        }
        close MF;
    }
    open(COVERAGE,">$opt{shdir}/step2.soap.coverage.sh");
    foreach my $sample (keys %sample2coverage){
        if ($opt{index_f} && -s $opt{index_f}) {
            ($soap_coverage{$sample})?
            print COVERAGE "cd $opt{outdir}/$sample\n",
            "$soap_coverage{$sample} -i $sample2coverage{$sample} 2> cover.log\n",
            "$cover_table coverage.depth soap.coverage.depthsingle coverage.depth.table\n\n":
            warn"step2:the index_f for SAMPLE:$sample can not find, please check index_f\n";
        }else{
            print COVERAGE "cd $opt{outdir}/$sample\n",
            "$soap_coverage -i $sample2coverage{$sample} 2> cover.log\n",
            "$cover_table coverage.depth soap.coverage.depthsingle coverage.depth.table\n\n";
        }
        print LIST "$sample\t$opt{outdir}/$sample/coverage.depth.table\n" if(!$opt{mf});
        print OUTPUT "$sample\t$opt{outdir}/$sample/soap.coverage.depthsingle\n" if(!$opt{mf});;
    }
    close COVERAGE;  
    close LIST;
    close OUTPUT;
    $locate_run .= "sh step2.soap.coverage.sh\n";
    $qsub_run .= "$super_worker_soap step2.soap.coverage.sh -splits '$splits'\n";
}

## step3. draw coverage depth distribution figure.
if ($opt{step}=~/3/ ) {
    die "Running step3:step 1 and 2 must be choosen!\n" if(!($opt{step}=~/1/ && $opt{step}=~/2/));
    open(DRAW,">$opt{shdir}/step3.draw.sh");
    foreach my $sample (keys %sample2coverage){
        print DRAW "cd $opt{outdir}/$sample\n",
        "$draw_line soap.coverage.plot >coverage_depth.svg\n",
        "/usr/bin/convert coverage_depth.svg coverage_depth.png\n\n";
    }
    close DRAW;
    $locate_run .= "sh step3.draw.sh&\n";
    $qsub_run .= "$super_worker_bwt step3.draw.sh  -splits '$splits' --prefix draw &\n";
}

## step4, depth, coverage, table produce(for multiple samples)
## step4 will be excluded for index_f
if ($opt{step}=~/4/ &&  $opt{index} && !$opt{index_f}) {
    die "Running step4:step 1 and 2 must be choosen!\n" if(!($opt{step}=~/1/ && $opt{step}=~/2/));
    $scaftigs_profiling .= " --outdir $opt{outdir}/Total/cover ";
    $gene_profiling_total .= " --outdir $opt{outdir}/Total/readsNum ";
    (-s "$opt{outdir}/Total/cover") || `mkdir -p $opt{outdir}/Total/cover`;
    (-s "$opt{outdir}/Total/readsNum") || `mkdir -p $opt{outdir}/Total/readsNum`;
    open(TABLE,">$opt{shdir}/step4.coverage_table.sh");
    print TABLE "cd $opt{outdir}/Total/cover\n",
    "$scaftigs_profiling --data_list $opt{outdir}/soap.coverage.list > screen.depth.log\n\n";
    ($opt{genel} && -s $opt{genel}) ? 
    print TABLE "cd $opt{outdir}/Total/readsNum\n$gene_profiling_total >  screen.depth.log\n\n" :
    print TABLE "\n";
    close TABLE;
    $locate_run .= "sh step4.coverage_table.sh\n";
    $qsub_run .= "$super_worker_bwt step4.coverage_table.sh  -splits '$splits' --prefix coverage_table \n";
}

$opt{notrun} && exit;
$opt{locate} ? system"cd $opt{shdir}
$locate_run" :
system"cd $opt{shdir}
$qsub_run";
