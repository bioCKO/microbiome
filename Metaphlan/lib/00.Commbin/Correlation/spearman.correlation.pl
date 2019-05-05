#!/usr/bin/perl -w
=head1 Description

    For spearman correlation between samples

=head1 Version

    Contact: chenjunru@novogene.com 
    Version: 3.0  Date: 2014-07-06, Updating

=head1 Usage

  perl [-options]
   *-input   [str]   input taxonomy relative directory.
   --data    [str]   input function relative directorys.
   --pattern [str]   pattern for get levels and dbs, default=1
                     1: '.*\/(KEGG|CAZy|eggNOG|MicroNR)\/\1\_stat\/(?:MetaStats|Metastats)\/(kingdom|phylum|class|order|family|genus|species|ec|ko|og|level1|level2|level3|EC)\/.*_diff_relative.xls$'
                     2: '.*\/(KEGG|CAZy|eggNOG|MicroNR)\/$1\_stat\/Relative(\/Unigenes.relative.(ec|ko|og|level1|level2|level3|[kpcofgs]).xls)?$');.*\/(KEGG|CAZy|eggNOG|MicroNR)\/$1\_stat\/Relative(\/Unigenes.relative.(ec|ko|og|level1|level2|level3|[kpcofgs]).xls)?$'
                     or any others
   --top     [num]   only correlatin top x, default=35
   --outdir  [str]   output directory, default=./
   --shdir   [str]   output shell directory, default=./Shell
   --notrun          just produce shell script, not qsub    
   --locate          run locate, not qsub  
   --vf      [str]   resource for qsub, default=1g
   --qopts   [str]   other qsub options 

=cut

#====================================================================================================================

use strict;
use Cwd qw(abs_path);
use Data::Dumper;
use FindBin qw($Bin);
use Getopt::Long;

#get options
my %data;
my %opt = (
    outdir=>'./',shdir=>'./Shell',
    top=>35,vf=>'1G',
    pattern=>1,
);
GetOptions(
    \%opt,"input:s","data:s"=> \%data,"pattern:s","outdir:s","top:n","shdir:s","notrun","locate","vf:s","qopts:s"
);
#end for get options

#get software & scripts' pathway
use lib "$Bin/..";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($Rscript,$R,$convert,$super_worker) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(Rscript R CONVERT SUPER_WORK)],$Bin,$lib);
my $spearman="perl $Bin/spearman.correlation.heatmap.pl ";

#====================================================================================================================
#options set
($opt{input} && -s $opt{input} && %data) || die `pod2text $0`;
(-s $opt{outdir}) || `mkdir -p $opt{outdir}`;
(-s $opt{shdir}) || `mkdir -p $opt{shdir}`;
$opt{outdir}=abs_path($opt{outdir});
$opt{shdir}=abs_path($opt{shdir});
$opt{qopts} && ($super_worker .= " $opt{qopts} ");
$opt{pattern} eq '1' &&($opt{pattern}='.*\/(KEGG|CAZy|eggNOG|MicroNR)\/\1\_stat\/(?:MetaStats|Metastats)\/(kingdom|phylum|class|order|family|genus|species|ec|ko|og|level1|level2|level3|EC)\/.*_diff_relative.xls$');
$opt{pattern} eq '2' &&($opt{pattern}='.*\/(KEGG|CAZy|eggNOG|MicroNR)\/\1\_stat\/Relative(\/Unigenes.relative.(ec|ko|og|level1|level2|level3|[kpcofgs]).xls)?$');

#main
my %ranks=(
    'k','kingdom',
    'p','phylum',
    'c','class',
    'o','order',
    'f','family',
    'g','genus',
    's','species',
);
my $splits='\n\n';
open(SH,">$opt{shdir}/correlation.sh");
foreach my $file (`less -S $opt{input}`){
    chomp$file;
    next if($file eq '.' || $file eq '..');
    if ($file=~/$opt{pattern}/) {
        my $db=$1;
        my $level=$2;
        $level=$ranks{$level} if($ranks{$level});
        (-s "$opt{outdir}/$level") || mkdir "$opt{outdir}/$level";
        foreach my $data (keys %data){
            (-s "$opt{outdir}/$level/$data") || mkdir "$opt{outdir}/$level/$data";
            $data{$data}=abs_path($data{$data});
            foreach my $db_file(`less -S $data{$data}`){
                chomp$db_file;
                next if($db_file eq '.' || $db_file eq '..');
                if ($db_file=~/$opt{pattern}/) {
                    my $db_level=$2;
                    (-s "$opt{outdir}/$level/$data/$db_level")||mkdir "$opt{outdir}/$level/$data/$db_level";
                    print SH 
                    "$spearman $db_file $file $level-$data-$db_level $opt{outdir}/$level/$data/$db_level $opt{top}\n\n";
                }else{next;}
            }
        }
    }else{next;}
}
close SH;

$opt{notrun} && exit;
$opt{locate} ? system"cd $opt{shdir}
sh correlation.sh " :
system"cd $opt{shdir}
$super_worker correlation.sh --resource=$opt{vf}  --prefix correlation -splits '$splits'\n";

#====================================================================================================================
