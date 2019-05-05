#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
sub abs_path{chomp(my $tem = $_[1] || `pwd`);($_[0]=~/^\//) ? $_[0] : "$tem/$_[0]";}
sub arr_path{my @out;foreach(@_){push @out,abs_path($_);}@out;}
use Getopt::Long;
my ($qsub_opt,$resource,$run,$soap_dir,$soap_opt,$dvf,$verbous,$help,$maxjob,$sd,$gzip,$nt_dir,
        $cov_dir,$cov_opt,$revi_opt,$gc_dir,$step,$gc_opt,$insert_dir);
my %opt;
GetOptions(
	"insert:s"=>\$opt{insert},       "sd:s"=>\$sd,
	"qopts:s"=>\$qsub_opt,       "run:s"=>\$run,
	"soap_vf:s"=>\$resource,     "soap_dir:s"=>\$soap_dir,
	"soap_opts:s"=>\$soap_opt,	"bwt_vf:s"=>\$dvf,           
    "cov_dir:s"=>\$cov_dir,     "cov_opts:s"=>\$cov_opt,
    "revi_opts:s"=>\$revi_opt,
	"verbose"=>\$verbous,        "help"=>\$help,
    "gzip"=>\$gzip,              "maxjob:i"=>\$maxjob,
    "gc_dir:s"=>\$gc_dir,       "step:s"=>\$step,
    "gc_opts:s"=>\$gc_opt,      "insert_dir:s"=>\$insert_dir,
    "nt_dir:s"=>\$nt_dir,           "name:s"=>\$opt{name},
    "cover_cut:f"=>\$opt{cover_cut},     "cluster_range:s"=>\$opt{cluster_range},
    "megablast"=>\$opt{megablast},       "mega_opts:s"=>\$opt{mega_opts},
    "len:i"=>\$opt{len},         "cpu:i"=>\$opt{cpu},   "cpu2:i"=>\$opt{cpu2},
    "blast_vf:s"=>\$opt{blast_vf},       "ntdb:s"=>\$opt{ntdb},
    "gidTaxid:s"=>\$opt{gidTaxid},       "node:s"=>\$opt{node},
    "incomp_del"=>\$opt{incomp_del},    "sortsoap"=>\$opt{sortsoap},
    "prefix:s"=>\$opt{prefix},          "dibc"=>\$opt{dibc},
    "resoap"=>\$opt{resoap},            "shdir:s"=>\$opt{shdir},
    "outdir:s"=>\$opt{outdir},          "subdir:s"=>\$opt{subdir},
    "lis_dir:s"=>\$opt{lis_dir},        "add_num:i"=>\$opt{add_num},
    "seq_lim:f"=>\$opt{seq_lim},        "top:i"=>\$opt{top},
    "wgs"=>\$opt{wgs},      "Ngapl:i"=>\$opt{Ngapl},
    "scafl:i"=>\$opt{scafl},        "contl:i"=>\$opt{contl},
    "linel:i"=>\$opt{linel},         "random"=>\$opt{random},
    "scaftig:s"=>\$opt{scaftig},    "organism:s"=>\$opt{organism},
    "tax_id:i"=>\$opt{tax_id},      "assembly_name:s"=>\$opt{assembly_name},
    "plasm_opts:s"=>\$opt{plasm_opts}, "plasm_dir:s"=>\$opt{plasm_dir},
    "srelate_opts:s"=>\$opt{relate_opts}, "sr_dir:s"=>\$opt{sr_dir},
    "reflist:s"=>\$opt{reflist},    "cdslist:s"=>\$opt{cdslist},
    "kmer:s"=>\$opt{kmer},      "ref_dir:s"=>\$opt{ref_dir},
    "refcover_opts:s"=>\$opt{refcover_opts}, "wgs2"=>\$opt{wgs2},
    "small_insert:i"=>\$opt{small_insert},"blast_opts:s"=>\$opt{blast_opts}
);
$opt{incomp_del} ||= 0;############### NOTE!!
#GetOptions(
#    \%opt,"cluster_range:s","cover_cut:f","blast_opts:s","megablast",
#    "mega_opts:s","len_cut:i","cpu:i","blast_vf:s","ntdb:s","gidTaxid:s",
#    "name:s","node:s"
#);
(@ARGV != 2 || $help) && die"
Name
    population_soap.pl
\nDescription
    script to run SOAP2, soap.coverage, base.revision, GC_depth or soap2_insert, nt blast, plasmid blast,
    Scaffold relation analysis, Reference repeat and coverage analysis
\nAuthor
    liuwenbin, liuwenbin\@genomic.org.cn
\nVersion
    V1.0,  Date: 2011-03-14
    V1.1,  Last modify: 2012-6-05
\nUsage: perl population_soap.pl <reads.lis> <index_lib.lst>  [-option]
    reads.lis               PE reads or Single reads pathway list list(if one sample, use Bin/run_soap.pl)
    index_lib               soap -D set list, when not end with .index, index lib will build
    --outdir <dir>          output directory, default=.
    --subdir <dir>          add subdir at eacth subdir, default not set.
    --shdir <dir>           work directory, default=Shell
    --step <num>            step to run: 1 soapalign, 2 soap.coverage, 3 base.revision, 4 GC_depth,
                            5 soap2_insert, 6 nt blast, 7 Plasmid analysis, 8 Scaffold relation,
                            9 reference coverage, 0 make WGS upload form, defualt=1
    --insert <str>          insert lst: name avg_ins, set to caculate -m -x, when PE reads
    --sd <str>              sd to caculate -m -x for small,big lane, default=0.2,0.3
    --qopts <str>           option for qsub, e.g. '-P bc_mg -q bc.q', default not set
    --run <srt>             parallel type, qsub, or multi, default=qsub
    --maxjob <num>          maxjob, default=qsub?100:4

    1.soapalign:
    --soap_vf <str>         resource for SOAP, default 'vf=2g'
    --bwt_vf <str>          resource for 2bwt-builder, default vf=500M
    --soap_opts <str>       other soap option, default '-p 6 -v 3'
    --soap_dir <dir>        SOAP2 result output directory, default=./01.Soapalign
    --incomp_del            to delect the incomplete soap2 result, I am sorry to hear that soap2 has the bug!!
    --sortsoap              sort the soapalign result
    --prefix <str>          sortSoap prefix, default=all

    2.soap.coverage:
    --cov_dir <dir>         soap.coverage out dir, default=./02.Coverage
    --cov_opts <str>        soap.coverage option, default '-p 8'
    --small_insert <num>    only use insertSize less than the cutoff for soap.coverage and GC-depth anlysis, not set

    3.base.revision
    --revi_opts <str>       set base.revision option, default='-m 1 --cc 20'
    --dibc                  output output.dibc(-d set)

    4.GC_depth:
    --gc_dir <dir>          GC-depth analysis directory, default=./03.GC_depthi
    --gc_opts <str>         set GC-depth options, default='--gc_range 0,100 --dep_cut 400 '

    5.soap2_insert:
    --insert_dir <dir>      soap2_insert output directory, defualt=./04.Insert

    6.NT blast:
    --nt_dir <dir>          NT blast output directory, default=./05.Nt
    --cluster_range <str>   cluster_num frequence range see the cluster as enthetic, default=0.001,0.1
    --cover_cut <flo>       sequence enthetic coverage cutoff to selected out, defaut=0.5
    --blast_opts <str>      blast options, default='-e 1e-5 -F F -b 5'
    --megablast             use megablast instead of blastall, it maybe run faste
    --mega_opts <str>       megablast options, default='-p 0.8 -b 5 -v 5'
    --len <num>             blast m8 match min length, defualt=200
    --top <num>             output specified number of besthit for eatch scaffold, default=5
    --add_num <num>         add num main scaffold to outseq file
    --seq_lim <flo>         limit the size of add scaffold(Kb), default the whold sequence
    --wgs                   use the whold genomics for nt blast alignment, not selected portion even some parameters set.
    --cpu <num>             thread for the nt blast process, default=5
    --run <str>             run type, qsub or mutil, default=qsub
    --blast_vf <str>        resultce for qsub blast m8, defalt=3G
    --ntdb <file>           NT database, default=/{ifs1,ifshk1}/pub/database/ftp.ncbi.nih.gov/blast/db/20110911/nt
    --gidTaxid <file>       gi_taxid_nucl.dmp from NCBI taxonomy, default 20101123 version
    --name <file>           names.dmp from NCBI taxonomy, default 20101123 version
    --node <file>           nodes.dmp from NCBI taxonomy, default 20101123 version
    
    07.WGS upload form:
    --Ngapl <num>           Ngap length cutoff, default=10
    --contl <num>           contig within scaffold leng cutoff, default=50
    --scafl <num>           alone contig or scaffold leng cutoff, default=200
    --linel <num>           sequence leng per line, default=60
    --random                output sequenc in random turn, default natural ordering
    About AGP head info:
    --organism <str>        species name, default=' '
    --tax_id <num>          TAX_ID, default=' '
    --assembly_name <str>   ASSEMBLY NAME, default=' '

    Others:
    --plams_opts <str>      Plasmid_analysis.pl optins, default not set
    --wgs2                  use the whold genomics for plasm blast, not selected portion even some parameters set.
    --cpu2 <num>            thread for the plasm blast process, default=1
    --plams_dir <dir>       Plasm analysis directory, default=./06.Plasm_analysis
    --srelate_opts <str>    Scafrelation optinos, default=' -x 5 -c 500'
    --sr_dir <str>          Scafrelation directory, default=./07.Scafrelation
    --reflist <file>        input referance file list(multi fasta files) or can be one fasta file for --step 9
    --cdslist <file>        input referance cds file for --step 9
    --kmer <file>           set kmer stat table, or kmer analysis Gsize(bp)
    --ref_dir <dir>         reference coverage directory, default=./08.Refcoverage
    --refcover_opts <str>   Ref_cover.pl options, default not set
    --verbose               output running information
    --gzip                  gzip soap result
    --help                  output help information to screen
\nNote:
    1 The full output: 00.Index/ 01.Soapalign/ 02.Coverage/ 03.GC_depth/ 04.Insert/ 05.Nt, all process shell at Shell/
    2 The result for SOAP2 and soap.coverage and base.revision are the same, set by -soap_vf option.
    3 when set -refile, step 3 will run without seting -step 3.
\nExample:
    nohup perl population_soap.pl reads.lst fasta.lst  -step 12 -insert InsertSize.txt --sd 0.2,1 &\n\n";

###   check error   ===========================================================================================
my ($reads_lst0, $index_lib0) = &arr_path(@ARGV);
(-s $reads_lst0) || die"error can't fine valid file: $reads_lst0, $!\n";
foreach("2bwt-builder","soap2.21","soap.coverage","super_worker.pl","line_diagram.pl","Ref_cover.pl",
    "base.revision","soap2_insert.pl","cover_table.pl","run_nt_2.3.pl","super_scaffold3.pl"){
    (-s "$Bin/$_") || die"error can't find $_ at $Bin, $!\n";
}
#our $PERL = "/PROJ/GR/share/Software/perl/bin/perl";
#### option value   ===========================================================================================
$resource ||= "vf=2g";
$soap_opt ||= "-p 6 -v 3";
$cov_opt ||= "-p 8";
$revi_opt ||= '-m 1 --cc 20';
$gc_opt ||= ' --gc_range 0,100 ';   #del --dep_cut 400 by wangmeng at 150916
$step ||= 1;
$dvf ||= 'vf=500M';
$run ||= 'qsub';
$sd ||= "0.2,0.3";
my @sd = split/,/,$sd;
$maxjob ||= ($run eq 'qsub') ? 100 : 4;
my $outlst = "soap.lst";
$soap_dir ||= "01.Soapalign";
$cov_dir ||= "02.Coverage";
$gc_dir ||= "03.GC_depth";
$insert_dir ||= "04.Insert";
$nt_dir ||= "05.Nt";
$opt{cpu} ||= 5;
$opt{plasm_dir} ||= "06.Plasm_analysis";
$opt{sr_dir} ||= "07.Scafrelation";
$opt{ref_dir} ||= "08.Refcoverage";
$opt{srelate_opts} ||= "-x 5 -c 475";
my $outdir = ($opt{outdir} || '.');
(-d $outdir) || `mkdir -p $outdir`;
$outdir = abs_path($outdir);
$opt{lis_dir} ||= $outdir;
(-d $opt{lis_dir}) || mkdir($opt{lis_dir});
$opt{reflist} && ($opt{reflist} = abs_path($opt{reflist}));
$opt{cdslist} && ($opt{cdslist} = abs_path($opt{cdslist}));
$opt{kmer} && ($opt{kmer} = abs_path($opt{kmer}));
#foreach($outlst,$soap_dir,$cov_dir,$insert_dir,$gc_dir,$nt_dir){$_ = &abs_path($_,$outdir);}
#### preces pathway   ==========================================================================================
$qsub_opt ||= '';
my $bwt_builder = "$Bin/2bwt-builder";
my $soap_path = "$Bin/soap2.21";
my $soap_coverage = "$Bin/soap.coverage";
my $super_worker = "perl $Bin/super_worker.pl --maxjob $maxjob  --qalter --cyqt 1 --sleept 60";
my $line_diagram = "perl $Bin/line_diagram.pl";
my $revision = "$Bin/base.revision $revi_opt";
my $mutil_process = "perl $Bin/multi-process.pl";
my $soap_insert = "perl $Bin/soap2_insert.pl";
my $gc_depth_pl = "perl $Bin/GC_depth_dis.pl";
my $nt_blast = "perl $Bin/run_nt_2.3.pl";
my $plasm_blast = "perl $Bin/Plasmid_analysis.pl";
my $run_scafrelation = "perl $Bin/super_scaffold3.pl $opt{srelate_opts}";
my $Ref_cover = "perl $Bin/Ref_cover.pl --multiref ";
$opt{insert} && (-s $opt{insert}) && ($opt{insert} = abs_path($opt{insert})) && ($run_scafrelation .= " -i $opt{insert}");
my $wgs_upload = "perl $Bin/population_WGS_uplod_Seq.pl -id_prefix Scaffold ";
$qsub_opt && ($super_worker .= " --qopts=\"$qsub_opt\"", $nt_blast .= " --qopts=\"$qsub_opt\"", $plasm_blast .= " --qopts=\"$qsub_opt\"", $Ref_cover .= " --qopts=\"$qsub_opt\"");
foreach(qw(Ngapl contl scafl linel organism tax_id assembly_name)){
    $opt{$_} && ($wgs_upload .= " --$_ $opt{$_}");
}
$opt{random} && ($wgs_upload .= " --random");
$nt_blast =~ s#[^/]+/\.\./##g;
($run ne 'qsub') && ($super_worker .= " --bgrun --sleept 100",$nt_blast .= " --run mutil");
####============================================================================================================
#
#                                      MAIN PROCESS
#
####   build bwt    ============================================================================================
our $TESTING = 0;
my $shdir = abs_path($opt{shdir} || "Shell");
(-d $shdir) || mkdir($shdir);
my $dir;
my %index_lib;
my %fasta;
my $run_bwt;
my $index_lib00 = $index_lib0;
if($step=~/0/){
    open NL,">$opt{lis_dir}/ncbifa.lst" || die$!;
    open GL,">$opt{lis_dir}/ncbiagp.lst" || die$!;
    open SL,">$opt{lis_dir}/scaftig.lst" || die$!;
    foreach(`less $index_lib0`){
        (/(\S+)\s*=?\s*(\S+)/) || die"error at $index_lib0, line:$_";
        print NL "$1\t$2.fna\n";
        print GL "$1\t$2.agp\n";
        print SL "$1\t$2.scaftig\n";
    }
    close NL;
    close GL;
    close SL;
    ($step=~/3|6/) || ($wgs_upload .= " -ass_stat -lisdir $opt{lis_dir}");
    open SH,">$shdir/wgs_upload1.sh" || die$!;
    print SH "$wgs_upload $index_lib0 $opt{lis_dir}/ncbifa.lst $opt{lis_dir}/ncbiagp.lst -scaftig $opt{lis_dir}/scaftig.lst\n";
    close SH;
    system"cd $shdir; sh wgs_upload1.sh > wgs_upload1.sh.o 2> wgs_upload1.sh.e";
    $index_lib0 = "$opt{lis_dir}/ncbifa.lst";
    ($step=~/6/) && ($wgs_upload .= " --tax_list $opt{lis_dir}/max_tax_organism");
    ($step=~/3|6/) && ($wgs_upload .= " -ass_stat -lisdir $opt{lis_dir}");
}
foreach(`less $index_lib0`){
    (/(\S+)\s*=?\s*(\S+)/) || die"error at $index_lib0, line:$_";
    my ($samp_name, $index_lib) = ($1, $2);
    my $fa_file = $index_lib;
    if(-s "$index_lib.sai" && $index_lib=~/\.index$/){
        $fa_file =~ s/\.index$//;
    }elsif(-s "$index_lib.index.sai"){
        $index_lib .= ".index";
    }elsif($index_lib !~ /\.index$/ && -s $index_lib){
        my $indir = $opt{subdir} ? "$outdir/$samp_name/$opt{subdir}/00.Index" :
            "$outdir/$samp_name/00.Index";
	    (-d $indir) || `mkdir -p $indir`;
    	my $lin_lib = "$indir/" . (split/\//,$index_lib)[-1];
        (-s $lin_lib) || `ln -s $index_lib $indir`;
        $index_lib = $lin_lib;
        (-s "$index_lib.index.sai") || ($run_bwt .= "cd $indir; $bwt_builder $index_lib\n");
	    $index_lib .= ".index";
    }else{
        die"can't find file $index_lib,$!";
    }
    $index_lib{$samp_name} = $index_lib;
    $fasta{$samp_name} = $fa_file;
}
if($run_bwt && $step=~/1/){
    $verbous && (print STDERR localtime() . " --> start building bwt\n");
    open BSH,">$shdir/bul_bwt.sh" || die$!;
    print BSH $run_bwt;close BSH;
    system"cd $shdir;$super_worker -resource $dvf -prefix bwt bul_bwt.sh --sleept 30 ";
    $verbous && (print STDERR localtime() . " --> finish building bwt\n");
}

####  write shell file to run soap   ===========================================================================
$verbous && (print STDERR localtime() . " --> writing shell to run soap\n");
my %lib_ins;
my %inserth;
my %small_insert;
if($opt{insert}){
	open LB,$opt{insert} || die $!;
	while(<LB>){
		my @l = split/\s+/;
        $inserth{$l[0]} = $l[-1];
        my $avg_ins = (@l==5) ? $l[4] : $l[1];
        if($opt{small_insert} && $avg_ins < $opt{small_insert}){
            $small_insert{$l[0]} = 1;
        }
        my $n = ($avg_ins > 1000) ? 1 : 0;
		my ($m,$x) = (@l>=4) ? @l[2,3] : ((1-$sd[$n])*$l[1], (1+$sd[$n])*$l[1]);
		$lib_ins{$l[0]} = " -m $m -x $x";
        $n && ($lib_ins{$l[0]} .= " -R");
	}
}
my $gzip2 = $gzip ? 1 : 0;# to gzip after all step finish
($step=~/3/) || ($opt{resoap} = 0);
($step=~/[23]/ || $opt{sortsoap} || $opt{resoap}) && ($gzip = 0);
$gzip && ($gzip2 = 0);
my $suffix = $gzip ? "soap.gz" : "soap";
my $mask_sign = $opt{resoap} ? 1 : 0;
my %soap_dir;
my $run_soap_sh = "run_soap.sh";
write_soapsh("$shdir/$run_soap_sh",$outdir,$reads_lst0,$step,$gzip,$mask_sign,$soap_dir,$insert_dir,
        $soap_path,$bwt_builder,$soap_opt,$opt{insert},\%opt,\%lib_ins,\%index_lib,\%soap_dir);

my $splits = '\n\n';
my %soap_dir2 = %soap_dir;
###  step1/5 to run soap/soap2_insert ===============================================================================
if($step =~ /1/){
    $verbous && (print STDERR localtime() . " --> start to run soap\n");
	if ($TESTING) {print STDERR "evaluate: 1soap? check file: $shdir/1soap\n"; while (!-e "$shdir/1soap") { sleep 30;}} #for testing
    `cd $shdir;$super_worker -resource $resource -splits \"$splits\" $run_soap_sh -prefix soap -clean`;
	if ($TESTING) {print STDERR "finish 1soap\n";}
    foreach( values %soap_dir2){
        `ls $_/*.$suffix > $_/$outlst`;
        if($opt{small_insert}){
            open SLL,">$_/$outlst.small" || die$!;
            foreach(`less $_/$outlst`){
                my $bf = (split/\//)[-1];
                (($bf=~/L\d+_(\S+)\.extendedFrags/ || $bf=~/L\d+_([^_]+)\.notCombined/ || $bf=~/L\d+_([^_]+)_[12]/) && $small_insert{$1}) || next;
                print SLL;
            }
            close SLL;
        }
        $opt{resoap} && ($_ .= 2);
    }
    $verbous && (print STDERR localtime() . " --> finesh runnint soap\n");
    if($opt{sortsoap}){
        open SOR,">$shdir/sortSoap.sh" || die"$!";
        open SLS,">$opt{lis_dir}/sortsoap.lst";
        foreach(keys %soap_dir2){
            my $prefix = $_;
            print SOR "cd $soap_dir2{$_}; less ./*.soap* | $Bin/msort -k 'm8,n9' > $prefix.sort\n";#date > $shdir/sort.frec\n";
            print SLS "$prefix = $soap_dir{$_}/$prefix.sort\n";
        }
        close SLS;
        close SOR;
        open SR,">$shdir/run_sortSoap.sh" || die$!;
        print SR ($run ne 'qsub') ?  "cd $shdir;sh sortSoap.sh\ndate > $shdir/sort.frec\n" :
        "cd $shdir;$super_worker -resource $resource sortSoap.sh -prefix sortsoap\ndate > $shdir/sort.frec\n";
        close SR;
        if(!$opt{resoap}){
			if ($TESTING) {print STDERR "1sort? check file: $shdir/1sort\n"; while (!-e "$shdir/1sort") { sleep 30;}} #for testing
            system"cd $shdir;sh run_sortSoap.sh &";
        }
    }
}
###  step2 run soap.coverage  ========================================================================================
if($step !~ /[23456789]/){
    ($step=~/1/ && $opt{sortsoap}) && `perl -e 'until(-s \"$shdir/sort.frec\"){sleep(10);}'`;
    exit(0);
}
#foreach(values %index_lib){s/\.index$//;}
%index_lib = %fasta;
if(!$opt{resoap} && $gzip2){
    (-s "$shdir/gzip.sh") && `rm $shdir/gzip.sh`;
    if ($step =~ /3/){
        open GZ,">$shdir/gzip.sh" || die$!;
        foreach my $d(values %soap_dir){
            foreach(`less $d/$outlst`){print GZ "gzip $_";}
        }
        close GZ;
    }
#    ($step =~/3/) && (open GZ,">$shdir/gzip.sh" || die$!); #L374-L380by lss at 201603 
#    foreach my $d(values %soap_dir){
#        ($step =~/3/) || (open GZ,">$d/gzip.sh" || die$!);
#        foreach(`less $d/$outlst`){print GZ "gzip $_";}
#        ($step =~/3/) || close(GZ);
#    }
#   ($step =~/3/) && close(GZ);
}
my (%revi_file,%rev_log);
open SH,">$shdir/after_soap2.sh";
($step=~/3/) && (open VL,">$opt{lis_dir}/revi_file.lst" || die$!);
($step=~/4/) && (open CL,">$opt{lis_dir}/cluster_node.lst" || die$!);

open SOC,">$shdir/soap.coverage.sh"||die$!;
foreach (keys %soap_dir){
    my $cov_dir0 = $opt{subdir} ? "$outdir/$_/$opt{subdir}/$cov_dir" : "$outdir/$_/$cov_dir";
###  step2 run soapcoverage ========================================================================================
    if($step=~/2/){
        (-d $cov_dir0) || `mkdir -p $cov_dir0`;
        my $soap_lst = $opt{small_insert} ? "$soap_dir{$_}/$outlst.small" : "$soap_dir{$_}/$outlst";
        print SOC "cd $cov_dir0\n$soap_coverage  -cvg -refsingle $index_lib{$_} -il $soap_lst ",
        "-depthsingle soap.coverage.depthsingle -o  coverage.depth ",
        "-plot coverage.plot 0 400 $cov_opt 2> cover.log \n",
        "$line_diagram coverage.plot --signh --frame -x_title 'Sequencing depth(X)' ",
        "-y_title 'Sequencing depth frequence'  > coverage_depth.svg\n",
        "`/usr/bin/convert coverage_depth.svg coverage_depth.png` 2>/dev/null\n",
        "perl $Bin/cover_table.pl coverage.depth > coverage_depth.table\n";
###  step4 run GC depth    ========================================================================================
        if($step=~/4/){
            my $gc_dir0 = $opt{subdir} ? "$outdir/$_/$opt{subdir}/$gc_dir" :
            "$outdir/$_/$gc_dir";
            (-d $gc_dir0) || `mkdir -p $gc_dir0`;
            print SOC "#Draw GC_depth\ncd $gc_dir0\n$gc_depth_pl $index_lib{$_} $cov_dir0/soap.coverage.depthsingle $gc_opt\n",
                  "convert GC_depth.pos.pdf GC_depth.png\n";
            print CL "$_ $gc_dir0/GC_depth.pos.cluster\n";
        }
        if(!($step =~/3/) && !$opt{resoap} && $gzip2){
            my $gz = "";
            foreach(`less $soap_dir{$_}/$outlst`){chomp; $gz .=  "gzip $_; rm -r $_ & ";}
            print SOC "$gz\n";
#            print SOC "$mutil_process $soap_dir{$_}/gzip.sh\n";
        }
        $gzip2 && (print SOC "gzip $cov_dir0/soap.coverage.depthsingle\n");
    }
### step3 base.revision   ==========================================================================================
    if($step=~/3/){
        my @soap_ps;
        foreach(`less $soap_dir{$_}/$outlst`){
            chomp;
            /\.PE\.soap/ ? ($soap_ps[0] .= " $_") : ($soap_ps[1] .= " $_");
        }
        my $refile0 = $index_lib{$_};
        my $revi_file0 = "$index_lib{$_}.revi";
        $opt{dibc} && ($revision .= " -d $revi_file0.dibc");
        $revi_file{$_} = $revi_file0;
        print VL "$_ $revi_file0\n";
        print SOC "#step3\ncd $soap_dir{$_};$revision -i $refile0 -p $soap_ps[0] -s $soap_ps[1] -o $revi_file0 2> revision.log\n";
        $rev_log{$_} = "$revi_file0.log";
    }
    print SOC "\n";
}
close SOC;


my $sign;
($step=~/2/) && ($sign = "soap.coverage ");
if($step=~/4/){
    close CL;
    $sign .= "GC_depth ";
}
if($step=~/3/){
    close VL;
    close CL;
    $sign .= "base.revision";
    $index_lib00 = "$opt{lis_dir}/revi_file.lst";
    $index_lib0 = "$opt{lis_dir}/revi_file.lst";
}
#close SH;
$verbous && (print STDERR localtime() . " --> start to run $sign\n");
if ($TESTING) {print STDERR "after soap? check file: $shdir/after_soap\n"; while (!-e "$shdir/after_soap") { sleep 30;}} #for testing
#(-s "$shdir/after_soap2.sh") &&  system"cd $shdir; $super_worker -resource $resource after_soap2.sh -prefix afsoap -clean";
if (-s "$shdir/soap.coverage.sh"){system"cd $shdir; $super_worker -resource $resource soap.coverage.sh -prefix soap_coverage -splits '\n\n'";} else{ `rm "$shdir/soap.coverage.sh"`;};
if ($TESTING) {print STDERR "finish after soap\n";}
#if($step=~/4/ && @cluster_dis){
#    (-d "$opt{lis_dir}/gcdep_fig") || mkdir"$opt{lis_dir}/gcdep_fig";
#    foreach(@cluster_dis){
#        `convert $_->[1] $opt{lis_dir}/gcdep_fig/$_->[0].GC_depth.png`;
#    }
#} by lss at 201603
$verbous && (print STDERR localtime() . " --> finish running $sign\n");
### rerun soap  ===============================================================================================
if($opt{resoap} && %revi_file){
    $soap_dir =~ s/\/$//;
    $soap_dir .= "2";
    open BWT,">$shdir/re_bwt.sh" || die$!;
    foreach(keys %soap_dir){
        my $indir = "$soap_dir{$_}/../00.index";
        (-d $indir) || mkdir($indir);
        (-s $indir) && `rm -r $indir/*`;
        `ln -s $revi_file{$_} $indir`;
        my $revi_bname = (split/\//,$revi_file{$_})[-1];
        print  BWT "cd $indir; $bwt_builder $revi_bname\n";
        $index_lib{$_} = "$indir/$revi_bname.index";
    }
    close BWT;
write_soapsh("$shdir/rerun_soap.sh",$outdir,$reads_lst0,$step,$gzip2,0,$soap_dir,$insert_dir,
        $soap_path,$bwt_builder,$soap_opt,$opt{insert},\%opt,\%lib_ins,\%index_lib);
    open SH,">$shdir/run_rerun_soap.sh" || die$!;
    print  SH "cd $shdir\n$super_worker -resource $dvf -prefix bwt re_bwt.sh --sleept 60 \n",
    "$super_worker -resource $resource -splits \"$splits\" rerun_soap.sh -prefix resoap\n";
    $opt{sortsoap} && (print SH "cd $shdir ; sh run_sortSoap.sh\n");
    print SH "date > $shdir/resoap.frec\n";
    close SH;
    (-s "$shdir/resoap.frec") && `rm $shdir/resoap.frec`;
    $verbous && (print STDERR localtime() . " --> start to run soap again\n");
	system"cd $shdir; sh run_rerun_soap.sh &";
}
### step6 nt blast  ===========================================================================================
my @frec_file;
#if($step=~/6/ && -s "$opt{lis_dir}/revi_file.lst" && -s "$opt{lis_dir}/cluster_node.lst"){
if($step=~/6/ && -s $index_lib0){
    my $nt_opts = " --outdir $outdir --ntdir $nt_dir --shdir $shdir -lisdir $opt{lis_dir}";
    $opt{wgs} && ($nt_opts .= " --wgs");
    foreach(qw(cluster_range cover_cut len cpu blast_vf ntdb gidTaxid name node subdir add_num seq_lim top)){
        $opt{$_} && ($nt_opts .= " --$_ $opt{$_}");
    }
    foreach(qw(blast_opts mega_opts)){$opt{$_} && ($nt_opts .= " --$_=\"$opt{$_}\"");}
    $opt{megablast} && ($nt_opts .= " --megablast");
    (-s "$shdir/ntblast.frec") && `rm $shdir/ntblast.frec`;
    push @frec_file,["$shdir/ntblast.frec","running ntdb blast"];
    open SH,">$shdir/run_nt.sh" || die"$!\n";
    print SH "$nt_blast $index_lib0 $opt{lis_dir}/cluster_node.lst $nt_opts\ndate > ntblast.frec\n";
    close SH;
    $verbous && (print STDERR localtime() . " --> start to run ntdb blast\n");
    system"cd $shdir;sh run_nt.sh >run_nt.sh.o 2> run_nt.sh.e &";
#    $verbous && (print STDERR localtime() . " --> finish running ntdb blast\n");
}
### step7 plasmid blast  =======================================================================================
#if($step =~ /7/ && -s "$opt{lis_dir}/revi_file.lst" && -s "$opt{lis_dir}/cluster_node.lst"){
if($step =~ /7/ && -s $index_lib0){
    my $plasm_opts = " --outdir $outdir --pldir $opt{plasm_dir} --shdir $shdir -lisdir $opt{lis_dir} ";
    $opt{plasm_opts} && ($plasm_opts .= $opt{plasm_opts});
    $opt{cpu} = ($opt{cpu2} || 1);
    foreach(qw(cluster_range cover_cut len cpu  subdir)){
        $opt{$_} && ($plasm_opts .= " --$_ $opt{$_}");
    }
    $opt{wgs2} && ($plasm_opts .= " --wgs");
    (-s "$shdir/plasmid.frec") && `rm $shdir/plasmid.frec`;
    push @frec_file,["$shdir/plasmid.frec","plsamid blast"];
    open SH,">$shdir/run_Plasm_analsyis.sh" || die$!;
#   print SH "$plasm_blast $index_lib0 $opt{lis_dir}/cluster_node.lst $plasm_opts\ndate > plasmid.frec\n";
    print SH "$plasm_blast $index_lib0 $plasm_opts\ndate > plasmid.frec\n";#Add by liuchen to get Plasm_analsyis result according to all scaffolds.
    close SH;
    $verbous && (print STDERR localtime() . " --> start to run plsamid blast\n");
    system"cd $shdir;sh run_Plasm_analsyis.sh > run_Plasm_analsyis.sh.o 2> run_Plasm_analsyis.sh.e &";
#    $verbous && (print STDERR localtime() . " --> finish running plsamid blast\n");
}
### stat base.revi info  =======================================================================================
if(%rev_log){
    my $rev_log_out;
    foreach(keys %rev_log){
        ($revi_file{$_} =~ /^(.+)\//) || next;
        my $d = $1;
        my $log_f = "$d/ass_stat.tab.ncbi";
        (-s $log_f) || ($log_f = "$d/ass_stat.tab");
        (-s $log_f) || next;
        my $genomic_tol_length = (split/\s+/,`sed -n '12p' $log_f`)[2];
        my $genomic_tol_length0 = $genomic_tol_length;
        $genomic_tol_length =~ s/,//g;
        my $corr_base = (-s $rev_log{$_}) ? (split/\s+/,`wc -l $rev_log{$_}`)[0] : 0;
        $rev_log_out .= join("\t",$_,$genomic_tol_length0,$corr_base,int(10**6*$corr_base/$genomic_tol_length+0.5)/10**4)."\n";
    }
    if($rev_log_out){
        open LL,">$opt{lis_dir}/base_correct.stat.xls" || die$!;
        print LL "Sample_name\tGenomics_Size(bp)\t#Correct_base\tError_rate(%)\n",$rev_log_out;
        $rev_log_out = "";
        close LL;
    }
}
($step=~/1/ && $opt{sortsoap}) && `perl -e 'until(-s \"$shdir/sort.frec\"){sleep(10);}'`;
if($opt{resoap}){
    `perl -e 'until(-s \"$shdir/resoap.frec\"){sleep(10);}'`;
    $verbous && (print STDERR localtime() . " --> finish rerun soap at ".`cat $shdir/resoap.frec`);
#$verbous && (print STDERR localtime() . " --> finish rerun soap at ".`less $shdir/resoap.frec`);
    foreach(keys %soap_dir){
        system"rm -r $soap_dir{$_}; mv -f $soap_dir2{$_} $soap_dir{$_}";
    }
	foreach (values %soap_dir) {
		my $suffix2 = $gzip2 ? "soap.gz" : "soap";
        `ls $_/*.$suffix2 > $_/$outlst`;
        if($opt{small_insert}){
            open SLL,">$_/$outlst.small" || die$!;
            foreach(`less $_/$outlst`){
                my $bf = (split/\//)[-1];
                (($bf=~/L\d+_(\S+)\.extendedFrags/ || $bf=~/L\d+_([^_]+)\.notCombined/ || $bf=~/L\d+_([^_]+)_[12]/) && $small_insert{$1}) || next;
                print SLL;
            }
            close SLL;
        }
	}
}
if(-s "$shdir/gzip.sh"){
    $verbous && (print STDERR localtime() . " --> start gzip soap result\n");
    system"cd $shdir;$super_worker -prefix gzip -resource 75M gzip.sh";
    foreach(values %soap_dir){
        `ls $_/*.soap.gz >$_/$outlst`;
    }
    $verbous && (print STDERR localtime() . " --> finish gzip soap result\n");
}
if(%soap_dir){
    my (@sample_name,@sub_dir);
    foreach(keys %soap_dir){
        push @sample_name,$_;
        push @sub_dir,"$soap_dir{$_}/../";
    }
    mega_coverage(\@sub_dir,"$opt{lis_dir}/all_coverage.stat.xls",\@sample_name,0,0,"$opt{lis_dir}/all_reads_mapped.stat.xls",0,\%inserth);
}
### step9 reference coverage analysis ==============================================================================
if($step=~/9/ && $opt{reflist} && -s $opt{reflist}){
    $opt{subdir} && ($opt{ref_dir} = "$opt{subdir}/$opt{ref_dir}");
    my $ref_opts = "$Ref_cover $reads_lst0 $opt{reflist} --synteny $index_lib0 -gzip --ref_repeat --clean -subdir $opt{ref_dir} ";
#$ref_opts .= " --outdir $opt{outdir} --lisdir $opt{lis_dir} ";
    $ref_opts .= " --outdir $outdir --lisdir $opt{lis_dir} ";
    $opt{insert} && (-s $opt{insert}) && ($ref_opts .= " -insert $opt{insert} ");
    $opt{cdslist} && (-s $opt{cdslist}) && ($ref_opts .= " --cds $opt{cdslist} ");
    $opt{kmer} && (-s $opt{kmer}) && ($ref_opts .= " --kmer $opt{kmer} ");
    $opt{refcover_opts} && ($ref_opts .= $opt{refcover_opts});
    (-s "$shdir/refcov.frec") && `rm $shdir/refcov.frec`;
    push @frec_file,["$shdir/refcov.frec","Reference coverage analysis"];
    open SH,">$shdir/run_Reference_cover.sh" || die$!;
    print SH $ref_opts , "\ndate > refcov.frec\n";
    close SH;
    $verbous && (print STDERR localtime() . " --> start Reference coverage analysis\n");
    system"cd $shdir; sh run_Reference_cover.sh run_Reference_cover.sh.o 2> run_Reference_cover.sh.e &";
#    $verbous && (print STDERR localtime() . " --> finish Reference coverage analysis\n");
}
### step8 scaffold relation  ======================================================================================
if($step =~ /8/){
    open SH,">$shdir/run_Scafrelation.sh" || die$!;
    foreach(`less $index_lib0`){
        my @t = split/[\s=]+/;
        my $sr_dir = "$soap_dir{$t[0]}/../$opt{sr_dir}";
        (-d $sr_dir) || mkdir($sr_dir);
        print SH "cd $sr_dir ; $run_scafrelation -f $t[1] -s $soap_dir{$t[0]}/$outlst -o Scafrelation\n";
    }
    close SH;
    $verbous && (print STDERR localtime() . " --> start Scaffold relation analysis\n");
    system"cd $shdir;$super_worker -prefix relation -resource 100M run_Scafrelation.sh -sleept 60";
    $verbous && (print STDERR localtime() . " --> finish Scaffold relation analysis\n");
}
### check finish file   ++=========================================================================================
if(@frec_file){
    foreach(@frec_file){
        `perl -e 'until(-s \"$_->[0]\"){sleep(10);}'`;
        $verbous && (print STDERR localtime() . " --> finish $_->[1] at ".`cat $_->[0]`);
#$verbous && (print STDERR localtime() . " --> finish $_->[1] at ".`less $_->[0]`);
    }
}
### make wgs upload ===============================================================================================
if($step=~/0/ && $step=~/3|6/){
    open SH,">$shdir/wgs_upload2.sh" || die$!;
    print SH "$wgs_upload $index_lib00 $opt{lis_dir}/ncbifa.lst $opt{lis_dir}/ncbiagp.lst -scaftig $opt{lis_dir}/scaftig.lst\n";
    close SH;
    $index_lib0 = "$opt{lis_dir}/ncbifa.lst";
    system"cd $shdir;sh wgs_upload2.sh";
}
foreach(values %soap_dir){(-d "$_/../00.Index") && `rm -r $_/../00.Index`;}

#============================================================================================================================
## SUB
sub write_soapsh{
    my ($shell,$outdir,$reads_lst0,$step,$gzip,$mask_sign,$soap_dir,$insert_dir,$soap_path,$bwt_builder,$soap_opt,
            $lib_lst,$opt,$lib_ins,$index_lib,$soap_dirh) = @_;
    open OUT,">$shell" || die$!;
    ($step=~/5/ && !$mask_sign) && (open IL,">$opt->{lis_dir}/soap2insert.lst" || die$!);
    foreach(`less $reads_lst0`){
        chomp;
        my ($samp_name, $reads_lst);
        if(-s $_){
            $samp_name = (split/\//)[-2];
            $reads_lst = $_;
        }elsif(/(\S+)\s*=?\s*(\S+)/ && (-s $2)){
            ($samp_name, $reads_lst) = ($1, $2);
        }else{
            die"error at $reads_lst0, line:$_";
        }
        my ($soap_dir0,$insert_dir0);
        $soap_dir0 = $opt->{subdir} ? "$outdir/$samp_name/$opt->{subdir}/$soap_dir" :
        "$outdir/$samp_name/$soap_dir";
        (-d $soap_dir0) || `mkdir -p $soap_dir0`;
        $soap_dir0 =~ s/\/$//;
        $soap_dirh && ($soap_dirh->{$samp_name} = $soap_dir0);
        open IN,$reads_lst || die $!;
        while(<IN>){
	        chomp;
			if (/L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || /L\d+_([^_]+)_[12]\.fq/) {
				my $soapopts = "-a $_";
				my $soap_opt_cur = $soap_opt;
				my $bname = (split/\//)[-1];
				if($lib_lst){
						chomp(my $b = <IN>);
						my $libname;
						($bname =~ /L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || $bname =~ /L\d+_([^_]+)_[12]\.fq/) && ($libname = $1);
						$lib_ins->{$libname} || ((print STDERR "Note: can't find lib_ins $libname in $lib_lst\n"),next);
						$soapopts .= " -b $b $lib_ins->{$libname}";
						$soap_opt_cur =~ s/-v\s+\d+//g;
						$soap_opt_cur .= " -v " . int((get_read_length($_) + get_read_length($b)) / 2 * 0.03);
				}
				print OUT "cd $soap_dir0\n$soap_path $soapopts -D $index_lib->{$samp_name} $soap_opt_cur -o $bname.PE.soap -2 $bname.SE.soap 2> $bname.log\n";

   	         	if($opt->{incomp_del}){
                	print OUT "awk '(\$12 && length(\$2)==length(\$3))' $bname.PE.soap > $bname.PE.soap2\n",
                  	"awk '(\$12 && length(\$2)==length(\$3))' $bname.SE.soap > $bname.SE.soap2\n",
                  	"rm -f $bname.PE.soap\nrm -f $bname.SE.soap\nmv -f $bname.PE.soap2 $bname.PE.soap; mv -f $bname.SE.soap2 $bname.SE.soap\n";
            	}
            	if($step=~/5/ && !$mask_sign){
                	$insert_dir0 = $opt->{subdir} ? "$outdir/$samp_name/$opt->{subdir}/$insert_dir" :
                	"$outdir/$samp_name/$insert_dir";
                	(-d $insert_dir0) || `mkdir -p $insert_dir0`;
                	print OUT "cd $insert_dir0\n$soap_insert $soap_dir0/$bname.{PE,SE}.soap\n";
                	print IL "$insert_dir0/$bname.PE.soap.insert\n";
            	}
#           	print OUT ($gzip ? "cd $soap_dir0\ngzip $bname.PE.soap & gzip $bname.SE.soap & wait\n\n" : "\n");
            	print OUT ($gzip ? "cd $soap_dir0\ngzip $bname.PE.soap\ngzip $bname.SE.soap\n\n" : "\n");
			}
			else { # single-end reads # add at 2014.05.24
				my $soapopts = "-a $_";
                my $soap_opt_cur = $soap_opt;
				my $bname = (split/\//)[-1];
				if($lib_lst){
					my $libname;
					($bname =~ /L\d+_(\S+)\.extendedFrags\.f[aq]/) && ($libname = $1);
					$lib_ins->{$libname} || ((print STDERR "Note: can't find lib_ins $libname in $lib_lst\n"),next);
					$soap_opt_cur =~ s/-v\s+\d+//g;
                	$soap_opt_cur .= " -v " . int(get_read_length($_) / 2 * 0.03);
				}
				print OUT "cd $soap_dir0\n$soap_path $soapopts -D $index_lib->{$samp_name} $soap_opt_cur -o $bname.SE.soap 2> $bname.log\n";
   	         	if($opt->{incomp_del}){
                	print OUT "awk '(\$12 && length(\$2)==length(\$3))' $bname.SE.soap > $bname.SE.soap2\n",
                  	"rm -f $bname.SE.soap\nmv -f $bname.SE.soap2 $bname.SE.soap\n";
            	}
				print OUT ($gzip ? "cd $soap_dir0\ngzip $bname.SE.soap\n\n" : "\n");
			}
        }
        close IN;
    }
    close OUT;
    ($step=~/5/ && !$mask_sign) && close(IL);
}
#sub4
sub mega_coverage{
    my ($dir,$stat_tab,$sample_name,$sign,$find_max,$map_file,$ref_name,$inserth) = @_;
    $sign ||= "Sample_name";
    $ref_name && @{$ref_name} && ($sign .= "\tRef_name");
    my @sel;
    my $get_map = 'perl -ne \'if(/^(Total Reads:|Alignment:|Total Pairs:|Paired:|Singled:)\s+(\d+)/){print $2,"\n";}\'';
    my $get_dis = 'perl -ne \'if(/Peak:\s+(\S+)/){print abs($1),"\n";}elsif(/SD:\s+(\S+)/){print $1;exit;}\'';
    my $has_dis = 0;
    my %map_rate;
    open STAT,">$stat_tab" || die$!;
    print STAT "$sign\tRef_len(bp)\tCover_length\tCoverage(%)\tDeapth(X)\n";
    foreach my $i(0..$#$dir){
        my $covst;
        my $samp_name = $sample_name->[$i];
        $ref_name && $ref_name->[$i] && ($samp_name .= "\t$ref_name->[$i]");
        if(-s "$dir->[$i]/02.Coverage/coverage_depth.table"){
            $covst = `tail -1 $dir->[$i]/02.Coverage/coverage_depth.table`;
            $covst =~ s/^\S+/$samp_name/;
        }else{
            $covst = join("\t",$samp_name,0,0,0,0)."\n";
        }
        if($find_max){
            my @aa = split/\s+/,$covst;
            push @sel,[@aa[0,-2],$aa[-1]*$aa[-4],$i];
        }
        print STAT $covst;
        ($map_file && -d "$dir->[$i]/01.Soapalign/" && `ls $dir->[$i]/01.Soapalign/*.log`) || next;
        foreach(`ls $dir->[$i]/01.Soapalign/*.log`){
            chomp;
            /L(\d+)_(\S+)\.extendedFrags/ || /L(\d+)_([^_]+)\.notCombined/ || /L(\d+)_([^_]+)/ || next;
            my ($lib_len, $lib) = ($1, $2);
            my @a = split/\s+/,`$get_map $_`;
            s/01\.Soapalign/04.Insert/;
            s/log$/PE.soap.insert/;
            if($inserth->{$lib}){
                $lib_len = $inserth->{$lib};
            }
            if(-s $_){
                $has_dis = 1;
                my @dis_len = split/\s+/,`$get_dis $_`;
                $lib_len .= sprintf("\t%d\t%s\t%.2f",@dis_len,100*abs($dis_len[0]-$lib_len)/$lib_len);
            }
            (@a == 2) ? 
			(push @{$map_rate{single}},[$samp_name,$lib_len,sprintf("%s\t%s\t%s\t%d\t%d\t%.2f\n",$samp_name,$lib,$lib_len,$a[0],$a[1],100*$a[1]/$a[0])]) : #single soap
			(push @{$map_rate{pair}},[$samp_name,$lib_len,sprintf("%s\t%s\t%s\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\n",$samp_name,$lib,$lib_len,$a[0],100*($a[1]+$a[2]/2)/$a[0],$a[1],100*$a[1]/$a[0],$a[2],100*$a[2]/$a[0]/2)]); #pair soap
#Sample_name     Lib_name        InsertSize(bp)  Total_PE        Map_rate(%)     Map_PE  PE_rate(%)      Map_SE  SE_rate(%)
        }
    }
    close STAT;
	`rm $map_file` if (-e $map_file);
    if($map_file && exists $map_rate{single} && @{$map_rate{single}}){
        $sign .= "\tLib_name\tInsertSize(bp)";
        open MP,">$map_file" || die$!;
        print MP "$sign\tTotal_map\tMap_rate(%)\n";
        foreach(sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @{$map_rate{single}}){
            print MP $_->[-1];
        }
        close MP;
    }
    if($map_file && exists $map_rate{pair} && @{$map_rate{pair}}){
        $sign .= "\tLib_name\tInsertSize(bp)";
        $has_dis && ($sign .= "Peak(bp)\tSD\tInsert(%)");
        ((-e $map_file && -s $map_file) ? (open MP,">>$map_file") : (open MP,">$map_file")) || die$!;
        print MP "$sign\tTotal_PE\tMap_rate(%)\tMap_PE\tPE_rate(%)\tMap_SE\tSE_rate(%)\n";
        foreach(sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @{$map_rate{pair}}){
            print MP $_->[-1];
        }
        close MP;
    }
    if($find_max){
        @sel = sort {$b->[1] <=> $a->[1] || $b->[2] <=> $a->[2]} @sel;
        return(@{$sel[0]}[0,3]);
    }
}

sub get_read_length {
	my $read = $_[0];
#chomp (my $length = `less $read | head -n 2 | tail -n 1`);
	chomp (my $length = `cat $read | head -n 2 | tail -n 1`);
	return length $length;
}
