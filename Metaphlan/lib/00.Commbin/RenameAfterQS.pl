#! /usr/bin/perl -w

=head1 Discription
	
	The pipeline for Rename sample's name after QC and Assembly.

=head1 Version

	V1.0, Date:2015-02-27, chenjunru[AT]novogene.com

=head1 Usage

	perl renameAfterQS.pl [options]
	*-refile         the rename file for sampleName,format=originalName\\trenameName
	*-work           the work directory for renaming, default is from data_list option
	#--group         the group file for sampleName, format=renameName\\tgroup,default will get it from workdir/all.mf
	--qn             giving the qn filename for QC_report, default from Shell/detail/01.DataClean/step2.DataStat.sh's last line
	--vf             resource for qsub,default=500M
	--shdir          output shell script directory,default=./
	--notrun         just produce shell script, not run
	--locate         run locate, not qsub
	--step           the steps for running,default=12
	                 step1: rename for 01.DataClean
	                 step2: rename for 02.Assembly

=cut

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;

#get options
my %opt = (
    step => '12',shdir => './',vf=>'500M',
);
GetOptions(
    \%opt,"refile:s","work:s","group:s","step:n","shdir:s","notrun","locate",
    "vf:s","qn:s",
);

#end for get options

#get soft & scripts pathway
my $ng_CreatReport_vmeta="perl /PROJ/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V2.2/lib/01.QC_Assembly/01.QC/lib/ng_CreatReport_vmeta.pl ";
my $super_worker="perl $Bin/super_worker.pl ";

#====================================================================================================================
#options set
($opt{refile} && -s $opt{refile}) || die `pod2text $0`;
$opt{work} && ($opt{work}=abs_path($opt{work}));
$opt{refile}=abs_path($opt{refile});
$opt{shdir}=abs_path($opt{shdir});
(-s $opt{shdir}) || `mkdir -p $opt{shdir}`;
$opt{vf} && ($super_worker .= " --resource vf=500M ");
my $splits = '\n\n';
$super_worker .= " --qopts ' -V ' --splits '$splits' --sleept 10 ";
#====================================================================================================================
#main script
##get working directory
$opt{work} && (my $workdir=$opt{work});
##refile
open(REFILE,"$opt{refile}");
my (%or2re,%orsamples);
while (<REFILE>) {
	chomp;
	my @or=split/\s+/;
	$or2re{$or[0]}=$or[1];
	$orsamples{$or[0]}=1;
}
close REFILE;

my ($locate_run,$qsub_run);
##step1: for QC
if ($opt{step}=~/1/) {
	(! -s "$workdir/01.DataClean/SystemClean/") && warn "01.DataClean is not exists at working directory!\n" && next;
	###for Dataclean.total.list
	open(SH,">$opt{shdir}/step1.QCothers.sh");
	$locate_run .= "sh step1.QCothers.sh & ";
	$qsub_run .= "$super_worker --prefix  QCothers  step1.QCothers.sh & ";
	if (-s "$workdir/01.DataClean/Dataclean.total.list") {
		open(OUT,">$workdir/01.DataClean/Dataclean.total.list.new");
		for(`less -S $workdir/01.DataClean/Dataclean.total.list`){
			chomp;
			my($oriName,$fqs)=(split/\t/)[0,1];
			my @fqs=split/,/,$fqs;
			print OUT "$or2re{$oriName}\t";
			my $i=1;
			foreach(@fqs){
				if(/(.*)$oriName\/$oriName(\_\d+(\.nohost)*\.fq[12]\.gz$)/){
					$i ==1 ?
					print OUT "$1$or2re{$oriName}\/$or2re{$oriName}$2," :
					print OUT "$1$or2re{$oriName}\/$or2re{$oriName}$2\n";
				}else{warn"the fqs format is uneven!\n";}
				$i++;
			}			
		}
		print SH "mv -f $workdir/01.DataClean/Dataclean.total.list.new $workdir/01.DataClean/Dataclean.total.list\n";
		close OUT;
	}else{warn"$workdir/01.DataClean/Dataclean.total.list is not exists!\n";}
	### for excels
	my $QCdir="$workdir/01.DataClean";
	print SH "cd $QCdir\n";
	my @excels=split/\s+/,`cd $QCdir;ls *.xls`;
	foreach my $excel (@excels){
		my $reExcel=$excel.".new";
		&excel($QCdir,$excel,$reExcel);
		print SH "mv -f $reExcel $excel\n";
	}
	###for 01.DataClean/HostClean directory
	if (-s "$workdir/01.DataClean/HostClean") {
		opendir(ODIR,"$workdir/01.DataClean/HostClean");
		my $oriHostdir = "$workdir/01.DataClean/HostClean";
		while(my $or=readdir(ODIR)){
			next if ($or=~/^(\.|\.\.)$/);
			my $hostdir=$oriHostdir."/$or";
			my $shHost="$opt{shdir}/step1.$or.sh";
			$locate_run .= "sh step1.$or.sh & ";
			$qsub_run .= "$super_worker --prefix $or  step1.$or.sh & ";
			&change_samples($hostdir,$shHost);
		}
		closedir ODIR;
	}
	###for 01.DataClean/SystemClean directory
	if (-s "$workdir/01.DataClean/SystemClean") {
		my $oriSysdir = "$workdir/01.DataClean/SystemClean";
		my $shSys="$opt{shdir}/step1.SystemClean.sh";
		$locate_run .= "sh step1.SystemClean.sh & ";
		$qsub_run .= "$super_worker --prefix SystemClean  step1.SystemClean.sh & ";
		&change_samples($oriSysdir,$shSys);
	}else{warn"$workdir/01.DataClean/SystemClean is not exists!\n";}
	close SH;
	$locate_run .= "wait\n";
	$qsub_run .= "wait\n";
	###for QC report
	open SH,">$opt{shdir}/step1.qc_report.sh";
	$locate_run .= "sh step1.qc_report.sh & ";
	$qsub_run .= "$super_worker --prefix qc_report step1.qc_report.sh & ";
	if($opt{qn}){
		(-s "$workdir/01.DataClean/$opt{qn}")?
		print SH "cd $workdir/01.DataClean\n",
		"ls  $workdir/01.DataClean/SystemClean/*/*.png > $workdir/01.DataClean/png.list\n",
		"$ng_CreatReport_vmeta -l $workdir/01.DataClean/png.list -qn $workdir/01.DataClean/$opt{qn} -q $workdir/01.DataClean/novototal.QCstat.info.xls\n" :
		warn"Please check qn: the file $workdir/01.DataClean/$opt{qn} is not exists!\n";
	}else{
		(-s "$workdir/Shell/detail/01.DataClean/step2.DataStat.sh")?
		my $qc_report=`tail -n 1 $workdir/Shell/detail/01.DataClean/step2.DataStat.sh`:
		warn"$workdir/Shell/detail/01.DataClean/step2.DataStat.sh is not exists!\n";
		my $qn_opt=$1 if($qc_report && $qc_report=~/\s+-qn\s+(\S+)\s+/);
		my $qn_input=$1 if($qn_opt && $qn_opt=~/.*\/(.*)/);
		print SH "cd $workdir/01.DataClean\n",
		"ls  $workdir/01.DataClean/SystemClean/*/*.png > $workdir/01.DataClean/png.list\n",
		"$ng_CreatReport_vmeta -l $workdir/01.DataClean/png.list -qn $workdir/01.DataClean/$qn_input -q $workdir/01.DataClean/novototal.QCstat.info.xls\n" if($qn_input);
	}
	close SH;
}

##step2: for assembly
if ($opt{step}=~/2/) {
	(!-s "$workdir/02.Assembly/") || warn"02.Assembly is not exists at working directory!\n" && next;
}

$opt{notrun} && exit;
$opt{locate} ?
print "cd $opt{shdir};$locate_run":
`cd $opt{shdir};$qsub_run`;



#====================================================================================================================
#sub routines
#====================================================================================================================
#=================for QC excles
sub excel{
#=================
	my($dir,$a,$reA)=@_;
	if (-s "$dir/$a") {
		open(OUT,">$dir/$reA");
		for my $or(`less -S $dir/$a`){
			chomp$or;
			if($or=~/^#/){
				print OUT "$or\n";
				next;
			}
			my $sample=$1 if($or=~/^(.*?)\t.*/);
			$or2re{$sample} ? 
			($or=~s/^$sample\t/$or2re{$sample}\t/):
			warn"$dir\nthe rename for sample:$sample is not exists!\n";
			print OUT "$or\n";			
		}
		close OUT;
	}else{warn"$dir/$a is not exists!\n";}
}
#=================for change samples at $dir
sub change_samples{
#=================
	my($dir,$shell)=@_;
	open(SHFILE,">$shell");
			opendir(HOST,"$dir");
			while (my $sample=readdir(HOST)) {
				next if ($sample=~/^(\.|\.\.)$/);
				if ($orsamples{$sample}) {
					my $sampledir=$dir."/$sample";
					my @sampleFiles=split/\s+/,`cd $sampledir;ls`;
					print SHFILE "cd $sampledir\n";
					foreach my $file (@sampleFiles){
						my $reFile=$file;
						$or2re{$sample} ? 
						$reFile=~s/^$sample/$or2re{$sample}/ :
						warn "the rename for sample:$sample is not exists!\n";
						print SHFILE "mv -f $file $reFile\n";
					}
					my $reSampledir=$dir."/$or2re{$sample}";
					print SHFILE "mv -f $sampledir $reSampledir\n";
				}else{warn "$sample is not exists in $dir!\n";}
			}
			closedir HOST;
	close SHFILE;
}