#!/usr/bin/perl -w
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use strict;

# set default options
my (
    $help, $fa, $split_num, $dblist, $samplename, 
    $blasttype, $blastopt, $outdir,$shdir,
    $notrun, $locate, $vf, $qsubopt, $step, 
    $fadir, $blastdir,$m8,$depth,$coverage,
    $length,$relative_folder,$group,$top,$bar,$tree,$treef,
    $single,$query_len,$filt_identity,$filt_coverage,
);
$split_num=100;
$dblist="MicroNT";
$samplename="Uniq.Scaftigs";
$blasttype="blastn";
$blastopt="-F:F:-m:8:-a:4:-e:1e-5:-b:50";
$outdir="./";
$shdir="./Shell";
$vf="8G";
$step='123';
$top=10;
$bar=' -right -grid -rotate=\'-45\' -x_title \'Sample Name\' -y_title \'Relative Abundance\'  --y_mun 0.25,4 ';
$tree=' --trantab -bun 0.25,4 -bline  --scal_title \'Bray-Curtis Distance\' -width 200 -type 3 ';
$filt_identity ||= 95;
$filt_coverage ||=0.9;

#get options from screen
GetOptions(
    "help:s" => \$help, "file=s" => \$fa,"split=i"  => \$split_num,
    "db=s" => \$dblist, "prefix=s"  => \$samplename, "btype=s"  => \$blasttype,
    "bopts=s"   => \$blastopt,"outdir=s" => \$outdir,"shdir:s" => \$shdir,
    "notrun" => \$notrun,"locate" =>\$locate,"vf:s" =>\$vf,
    "qopts=s"   => \$qsubopt,"step:i" =>\$step,"fadir:s" => \$fadir,
    "blastdir:s" => \$blastdir,"m8:s" => \$m8,"depth:s" => \$depth,
    "coverage:s" => \$coverage,"length:s" => \$length,"relative:s" => \$relative_folder,
    "group:s" => \$group,"top:s" => \$top,"bar:s" => \$bar,"tree:s" => \$tree,"treef:s" => \$treef,
    "single:s" => \$single, "query_len:s" => \$query_len,"filt_identity:s" => \$filt_identity,"filt_coverage:s" => \$filt_coverage,
);

#get software pathway
#use lib "$Bin/../00.Commbin";
use lib "share/MetaGenome_pipeline/MetaGenome_pipeline_V2.2/lib/00.Commbin";
my $lib = "$Bin";
use PATHWAY;
(-s "$Bin/Pathway_cfg.txt") || die"error: can't find config at $Bin, $!\n";
my (%DB,$super_worker,$blastall,$pca_cluster,$heatmap,$get_table_head2,$bar_diagram,$svg2xxx,$draw_tree,);
($DB{"MicroNT"},$super_worker,$blastall,$pca_cluster,$heatmap,$get_table_head2,$bar_diagram,$svg2xxx,$draw_tree) = get_pathway("$Bin/Pathway_cfg.txt",[qw(MicroNT SUPER_WORK BLAST PCA_CLUSTER HEATMAP GET_TABLE_HEAD2 BAR_DIAGRAM SVG2XXX DRAW_TREE)],$Bin,$lib);
my $split_fa   = "perl $Bin/lib/split_fa.pl ";
my $screen_m8  = "perl $Bin/lib/0.screening.blast.pl ";
my $LCA      = "perl $Bin/lib/1.LCA_anno_flow.binning.pl ";

if($help){
    ($help eq 'blast') ? system "$blastall " :
    die"error: --help just can be selected from blast\n";
    exit;
}
#====================================================================================================================
($fa && -s $fa) ||($m8 && -s $m8)|| 
die "Name: $0
Description: Script to annotation(Taxonomy) for contigs
Version: 0.1  Date: 2016-04-26 
Connector: chenjunru[AT]novogene.com
Usage1: perl $0 --file  Unique.gene.fa [options]
        *-file  <file>   input fa file to Taxonomy
        --split  <num>   the number of the divided file,defult [100].
        --db  <str>      annotation database,MicroNT,default=MicroNT
        --prefix <str>   the output file prefix, default is Uniq.Scaftigs
        --btype <str>    blast type, the order corresponding to the specified database,default[blastn]
        --bopts <str>    blast option, the  the order corresponding to the specified database,default[-F:F:-m:8:-a:4:-e:1e-5:-b:50]
        --outdir <str>   output directory, default [./]
        --step <str>     default is 123
                         step1: for file split                         
                         step2: for files(split files or file) blast annotation
                         step3: for lca annotation
        --shdir <str>    output shell directory, default is [./Shell]
        --notrun         just produce shell script, not qsub    
        --locate         run locate, not qsub  
        --vf  <str>      resource for qsub,the order corresponding to the specified database,default=8G
        --qopts <str>    other qsub options 
        --help <str>     blast:help information for blast
        \n";
#====================================================================================================================
###get options
(-d $outdir ) || system("mkdir -p $outdir");
$outdir=abs_path($outdir);
(-d $shdir) || system("mkdir -p $shdir");
$shdir=abs_path($shdir);
$fa &&( $fa=abs_path($fa));
$qsubopt && ($super_worker .= " $qsubopt ");
$fadir && ($fadir=abs_path($fadir));
$blastdir && ($blastdir = abs_path($blastdir));
$depth && ($depth=abs_path($depth));
$depth && ($LCA .= " --depth $depth ");
$coverage && ($coverage =abs_path($coverage));
$coverage && ($LCA .= " --coverage $coverage ");
$length && ($length=abs_path($length));
$length && ($LCA .= "--length $length ");
$bar && ($bar_diagram .= " $bar ");
$tree && ($draw_tree .= " $tree ");
#====================================================================================================================
#main script
## begin for set blast, db, options
my (%blastopt,%blasttype,%blastvf);

my @dbs       = split( "-", $dblist ) if $dblist;
my @blasttype = split( "-", $blasttype ) if $blasttype;
my @blastopt  = split( ";", $blastopt ) if $blastopt;
my @blastvf   = split( "-", $vf ) if $vf;

die "the number of db unequal to the number of btype" if ($#blasttype ne $#dbs);

my $i;
for ( $i = 0 ; $i <= $#dbs ; $i++ ) {
    $blasttype{$dbs[$i]} = $blasttype[$i];
    $blastopt[$i]=~s/:/ /g;
    $blastopt{$dbs[$i]} = $blastopt[$i];
    $blastvf{$dbs[$i]} = $blastvf[$i];
}
## end for begin for set blast, db, options

my ($locate_run,$qsub_run);
## step1, for file split
my $splits = '\n\n';
my @falist;
my $falistpath = "$outdir/FA_List";
if($split_num && $fa && $step =~/1/){
    ( -d $falistpath ) || `mkdir -p $falistpath`; 
    open(SH,">$shdir/step1.split_fa.sh");
    my $split_fa_perfix;
    $samplename ? ($split_fa_perfix=$samplename) : ($split_fa_perfix = ( split /\//, $fa )[-1]);
    print SH "$split_fa n $split_num $fa $falistpath/$split_fa_perfix\n";
    close SH;
    $locate_run .= "sh step1.split_fa.sh\n";
    $qsub_run .= "$super_worker step1.split_fa.sh --resource 800M  --prefix split_fa -splits '$splits'\n";
    ## after file split, get the files pathway
    for my $nn (1..$split_num){
        push @falist,"$falistpath/$split_fa_perfix\_$nn.fa";
    }
}elsif($step=~/1/ && $fa){
    ( -d $falistpath ) || `mkdir -p $falistpath`;
    `cd $falistpath\nln -s $fa` if(!-s "$falistpath/$fa");
    ## after file split, get the files pathway
    $falist[0]=$fa;
}

## step2, shell script for annotation
my (@blastout_list);
$fadir && (@falist=`ls $fadir/*`);
if ($step=~/2/ && @falist) {
    my $j;
    for ( $j = 0 ; $j <= $#dbs ; $j++ ) {
        open(SH,">$shdir/step2.blast.$dbs[$j].sh");
        (-s "$outdir/$dbs[$j]/blastout") || system("mkdir -p $outdir/$dbs[$j]/blastout");
        (-s "$outdir/$dbs[$j]/$dbs[$j]\_stat") || system("mkdir -p $outdir/$dbs[$j]/$dbs[$j]\_stat"); 
        open(LIST,">$outdir/$dbs[$j]/$dbs[$j]\_stat/$dbs[$j].blastout.list");
        my $blasttype = $blasttype{$dbs[$j]};
        my $blastopt = $blastopt{$dbs[$j]};
        foreach my $tmp (@falist){
            chomp $tmp;
            my $split_fa_perfix = ( split /\//, $tmp )[-1];
            print SH "$blastall -i $tmp -d $DB{$dbs[$j]} -o $outdir/$dbs[$j]/blastout/$split_fa_perfix.blastout -p $blasttype $blastopt\n\n";
            print LIST "$outdir/$dbs[$j]/blastout/$split_fa_perfix.blastout\n";
        }
        close SH;
        close LIST;
        $locate_run .= "sh step2.blast.$dbs[$j].sh & ";
        $qsub_run .= "$super_worker step2.blast.$dbs[$j].sh  --resource $blastvf{$dbs[$j]} --prefix $dbs[$j] --splits '$splits' & ";
        push @blastout_list,"$outdir/$dbs[$j]/$dbs[$j]\_stat/$dbs[$j].blastout.list";
    }  
    $locate_run .= " wait \n";
    $qsub_run .= " wait \n"; 
}

#step3 cat m8files
my %db2cat;
$blastdir && (@blastout_list=`ls $blastdir`);
if ($step=~/3/ && @blastout_list) {
    open (SH, ">$shdir/step3.Taxonomy.sh");
    for (my $j = 0 ; $j <= $#dbs ; $j++ ) {
    my $list=$blastout_list[$j];
    my $db=$dbs[$j];
    print SH "cd $outdir/$db/$db\_stat\n",
    "$screen_m8 $list $query_len $samplename.screening.m8.xls $filt_identity $filt_coverage\n",
    "$LCA --m8 $samplename.screening.m8.xls --output $samplename -outdir $outdir/$db/$db\_stat\n",
    }
    close SH;
    $locate_run .= "sh step3.Taxonomy.sh\n";
    $qsub_run .= "$super_worker step3.Taxonomy.sh  --prefix Taxonomy --resource 3G --splits '$splits'\n";
}

$notrun && exit;
$locate ? system"cd $shdir
$locate_run" :
system"cd $shdir
$qsub_run";
