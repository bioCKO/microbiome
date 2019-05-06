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
	--outdir	[str]   default=/lib/02.Assembly/assembly_data_record \n";

my $indir=abs_path($opt{indir});
my $analysis=$1 if($indir=~/MICRO\/(\w+)\//);
my $trans="perl $Bin/../05.Function/lib/CARD/lib/tran_tab.pl";

$opt{outdir} ||="/lib/02.Assembly/assembly_data_record";
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
my $tmp = (split /\s+/,`sed -n 2p $indir/Shell/detail/02.Assembly/step1.assembly.sh`)[0];
my $software = (split /\//,$tmp)[-1];
my $nohostqc;
for(`ls $indir/01.DataClean`){
	chomp;
	$nohostqc = "$indir/01.DataClean/$_" if ($_ =~ /\S+NonHostQCstat\.info\.xls/);
}
my $QC = "$indir/01.DataClean/total.QCstat.info.xls";
my %qc;
if($nohostqc){
	for(`less $nohostqc`){
		chomp;
		/^#/ && next;
        my($sample,$clean,$nohost,$Q20,$Q30) = (split /\t|\s+/)[0,-6,-1,-5,-4];
        push @{$qc{$sample}},$clean,$nohost,$Q20,$Q30;
	}
}elsif(-s $QC){
	for(`less $QC`){
		chomp;
		/^#/ && next;
        my($sample,$clean,$Q20,$Q30) = (split /\t|\s+/)[0,-5,-4,-3];
        push @{$qc{$sample}},$clean,$clean,$Q20,$Q30;
	}
}else{
	print "Please check your QC\n";
}
#updat at 20180103 by zhangjing  [add tax info]
my $Relative="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/Relative";
my %zhushi;
my @level=('k','p','c','o','f','g','s');
foreach (@level){
		`$trans $Relative/Unigenes.relative.$_.xls  > $Bin/temp`;
		open IN,"$Bin/temp";
		<IN>;
		while(<IN>){
			next if ($_ =~ /^(k__|p__|c__|o__|f__|g__|s__)/);
			chomp;
                	my @or=split /\s+/;
			my $temp=1-$or[-1];
			push @{$zhushi{$or[0]}},$temp;
		}
		close IN;
		`rm -r $Bin/temp`;
}
open ASS,"$indir/02.Assembly/total.scaftigs.stat.info.xls";
my $head=<ASS>;
chomp $head;
print BAK "时间\t合同编号\t项目编号\t项目名称\t运营\t信息\tAssemblySoftware\t$head\tCleanData\tNohostData\tQ20\tQ30\tPEavailability\tSEavailability\tTotalavailability\tTax_k\tTax_p\tTax_c\tTax_o\tTax_f\tTax_g\tTax_s\tPath\n" if((!(-s $record)) || !($len>=2));
while(<ASS>){
	chomp;
	my $sample = (split /\t|\s+/)[0];
	my($Totalavailability,$PEavailability,$SEavailability);
	unless ($sample eq "NOVO_MIX"){ 
		if (-s "$indir/02.Assembly/NOVO_MIX/ReadsMapping/$sample/soap.log"){
			my $availability = "$indir/02.Assembly/NOVO_MIX/ReadsMapping/$sample/soap.log";
			for(`less $availability`){
				chomp;
				if(/^Paired:\s+\d+\s+\(\s?(\d+\.\d+)%\)\s+PE$/){
					$PEavailability = $1;
				}elsif(/^Singled:\s+\d+\s+\(\s?(\d+\.\d+)%\)\s+SE$/){
					$SEavailability = $1;
				}else{
					next;
				}
			}	
			$Totalavailability = $PEavailability + $SEavailability;
		}
		if(-s "$indir/02.Assembly/NOVO_MIX/ReadsMapping/$sample/bowtie.log"){
			my $availability = "$indir/02.Assembly/NOVO_MIX/ReadsMapping/$sample/bowtie.log";
			for(`less $availability`){
				chomp;
				if (/(\d+\.\d+)%\s+overall\s+alignment\s+rate$/){
					$Totalavailability= $1;
				}
			}
		}

		my $var=$zhushi{$sample};
		print BAK "$date\t$cname\t$pname\t$prname\t$acname\t$usr\t$software\t$_\t$qc{$sample}->[0]\t$qc{$sample}->[1]\t$qc{$sample}->[2]\t$qc{$sample}->[3]\t$PEavailability%\t$SEavailability%\t$Totalavailability%\t",join("\t",@$var),"\t$indir\n";
	}
}
close ASS;
`chmod 777 $record`;
