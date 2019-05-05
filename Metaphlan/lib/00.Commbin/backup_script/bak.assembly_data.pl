#!usr/bin/perl -w 
use strict;

use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);
my %opt=();
GetOptions(\%opt,"indir:s","Rinfo:s","outdir:s",);
$opt{indir} || die "
========================================================================================
Shell for record assembly data
Contact: Jing Zhang, zhangjing2232[AT]novogene.com 
Version: 1.0  Date: 2017-06-08

Usage:perl $0 --indir indir/ --Rinfo Rinfo --help
	--indir*    [str]   must set
	--Rinfo*	[str]   default=indir/Rinfo.list
	--outdir	[str]   default=/PUBLIC/software/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V4.2/lib/02.Assembly/assembly_data_record \n";

my $indir=abs_path($opt{indir});
my $analysis=$1 if($indir=~/MICRO\/(\w+)\//);

$opt{outdir} ||="/PUBLIC/software/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V4.2/lib/02.Assembly/assembly_data_record";
my $outdir=abs_path($opt{outdir});
(-d $outdir) || mkdir "$outdir";
$opt{Rinfo} ||="$indir/Rinfo.list"; 
my $Rinfo=abs_path($opt{Rinfo});
my $record="$outdir/assembly_record.xls";
my $length=`wc -l $record` if(-s $record);
my $len=(split /\s+/,$length)[0] if(-s $record);

chomp(my $date = `date +"%Y""%m""%d"`);

my $info=`cat $Rinfo`;
my($pname,$prname,$cname,$acname,$usr)=(split/\s+/,$info)[0,2,3,4,5];

open BAK,">>$record";
open ASS,"$indir/02.Assembly/total.scaftigs.stat.info.xls";
my $head=<ASS>;
print BAK "时间\t合同编号\t项目编号\t项目名称\t运营\t信息\t$head" if((!(-s $record)) || !($len>=2));
while(<ASS>){
	print BAK "$date\t$cname\t$pname\t$prname\t$acname\t$usr\t$_";
	close $record;
}
close ASS;
`chmod 775 $record`;
