#!/usr/bin/perl -w
use strict;
use File::Basename;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use lib "$Bin/../00.Commbin/";
my $lib = "$Bin/..";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";

## set default options
my ( $Pinfo, $outdir, $shdir, $fq_pattern, $adapter_pattern, @hostfa, $alnP, $alnopt, $filteropt, $notrun, $qsubopt, $help, $qsubhelp, $filterhelp,$locate,$step,$bvf,$svf,$hvf,$dvf,$read_len,$info,
);
$alnP            = "soap";
$outdir          = abs_path("./");
$shdir           = $outdir if ( !$shdir );
$qsubopt         = " --qopts='-q all.q,micro.q,novo.q -V ' ";
$filteropt       = "-z -q  38,40  -n  10 -l 15 ";
$fq_pattern      = "*_[12].fq.gz";
$adapter_pattern = "*_[12].adapter.list.gz";
$bvf             = '8G';
$svf             = '8G';
$hvf             = '8G';
$dvf             = '7G';
$step            = '0123';
$read_len        = 150;


## get options
GetOptions(
	"help=s"       => \$help,"data_list=s"  => \$Pinfo,"outdir=s" => \$outdir,"shdir=s"  => \$shdir,
	"fqp=s"    => \$fq_pattern,"adp=s"    => \$adapter_pattern,"host=s"   => \@hostfa,
	"method=s"   => \$alnP,"me_opts=s" => \$alnopt,"rf_opts=s"   => \$filteropt,"notrun" => \$notrun,
	"qopts=s"   => \$qsubopt,"locate" => \$locate,"step:s" => \$step,"bvf:s" => \$bvf,
	"svf:s" => \$svf,"hvf:s" => \$hvf,"dvf:s" => \$dvf,"read_len:n" => \$read_len,
);
$read_len == 150 || $read_len == 125 || die "read_len just can be choose for 150|125!\n";
if ( $alnP eq "soap" && !$alnopt  && $read_len == 150 ) {
	$alnopt ||= " -p 8 -s 135 -l 30 -v 7  -m 200  -x 400 ";
}elsif($alnP eq "soap" && !$alnopt  && $read_len == 125 ){
	$alnopt ||= " -p 8 -s 112 -l 30 -v 7  -m 200  -x 400 ";
}elsif ( $alnP eq "bwa" && !$alnopt ) {
	$alnopt ||= " -t 6 -k 50 -a ";
}

## get software pathway
my ($readfq,$fqcheck,$soap,$soapindex,$bwa,$superl_work,$sh_contral) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(ReadFQ Fqcheck SOAP SOAPINDEX BWA SUPER_WORK SH_CONTRAL)],$Bin,$lib);
my $extractread        = "perl $Bin/lib/ExtractReadsfromSamfiles.pl";
my $qcstat_fqcheck     = "perl $Bin/lib/MetaGenomics.fqcheck.v3.pl";
my $distribute_fqcheck = "perl $Bin/lib/distribute_fqcheck.pl";
my $qc_report          = "perl $Bin/lib/ng_CreatReport_vmeta.pl "; ##add for QC report 2014-09-10

## get help information
my $log ="$Bin/CHANGELOG.txt";
if($help){
    ($help eq 'rf') ? system "$readfq" :
    ($help eq 'log') ? system "cat $log" :
    die"error: --help just can be selected from rf|log\n";
    exit;
}
#====================================================================================================================
($Pinfo && -s $Pinfo) || die "Name: $0
Description: script to QC

Version: v3.0, 2015-07-10, the stable version 

Connector: chenjunru[AT]novogene.cn

Usage1:perl $0 <Project.info> <out.dir>
  *--data_list          input Project info file,example :#Samplename,RawDataPath,InsertSize(bp),Datasize(M),LibraryID,Description
  *-read_len            input reads length, important for soapaligner.defult=150.
  --outdir              output directory, defult [./]
  --shdir               shell script otuput directory,the default is the same as the -outdir
  --fqp                 the fastaq files regular expression¡ê?defult [*_[12].fq.gz]
  --adp                 the adapter list files regular expression¡ê?defult [*_[12].adapter.list.gz]
  --host                the host ref genome
  --method              the alignment method for removing host contamination,defult[soap]
  --me_opts             the option value for --method ,soap defult is according to read_len.
  --rf_opts             the filter options for QC,defult [-z -q 38,40 -n 10 -l 15],use --help rf for more info
  --bvf                 resource for step0, default=8G
  --svf                 resource for step1, default=8G
  --hvf                 resource for step2, default=8G
  --dvf                 vf cutoff, while --qalter, deault=7G
  --step                steps for running,default=13,when you given host option, default=0123
                        step0: index building
                        step1: SystemClean
                        step2: HostClean if host option is giving
                        step3: DataStat
  --notrun              just product shell script, not qsub
  --locate              run locate, not qsub.
  --qopts               other super work options
  --help                print help info, 
                        rf: print readfq help info
                        log: output CHANGLOG information to screen.

Example: 
  perl $0 -data_list /PROJ/GR/MICRO/metagenomics/NHT130001/Metagenomics.cfg.template2.txt 
  perl $0 -data_list sample.cfg --host host1.genome.fasta --host host2.genome.fasta

Note:
  1. for data_list, must include #Samplename,RawDataPath,InsertSize(bp),Datasize(M),LibraryID\n"; 
#===========================================================================================================================================
## get options for soft
$qsubopt && ($superl_work .= "  $qsubopt ");
$dvf && ($superl_work .= " --dvf $dvf ");
$readfq .= " $filteropt ";
$bwa .= "  mem $alnopt ";
$soap .= " $alnopt ";
#===========================================================================================================================================
## main script
my ( %sample_insert, %path, %datasize, %samploutdir );
&getPinfo( $Pinfo, \%sample_insert, \%path, \%datasize );
 ( -s $outdir ) || `mkdir -p $outdir`;
my $SystemClean = abs_path($outdir);
$SystemClean .= "/SystemClean";
( -s $SystemClean ) || `mkdir -p $SystemClean `;
my $HostClean   = "";
my (%hostdir,@HostClean);
if (@hostfa) {
	$HostClean = abs_path($outdir) . "/HostClean";
	`mkdir -p $HostClean `   if ( !-d $HostClean );
	foreach(@hostfa){
		my $hostname=$1 if(~/.*\/(.*)/);
		`mkdir -p $HostClean/$hostname` if(!-d "$HostClean/$hostname");
		push @HostClean,"$HostClean/$hostname";
	}
}

`mkdir -p $shdir ` if ( !-d $shdir );
$shdir = abs_path($shdir); #add for abs path
#open RawCheckSH, ">$shdir/Rawcheck.sh";
foreach my $key ( keys %sample_insert ) {
	my @temp = split( /\t/, $key );
	if ( !exists( $samploutdir{ $temp[0] } ) ) {
		$samploutdir{ $temp[0] } = $SystemClean . "/" . $temp[0];
		( -d $samploutdir{ $temp[0] } ) || `mkdir -p $samploutdir{$temp[0]}`;
	}
	my $listname = $key;
	$listname =~ s/\t/_/;
	open LIST, ">$samploutdir{$temp[0]}/$listname.list"
	  or die "Can not open file $samploutdir{$temp[0]}/$listname.list $! .";
	my @temppath = split( /\t/, $path{$key} );
	foreach my $tmp (@temppath) {
		chomp $tmp;
		chomp( my @fqs      = `ls $tmp/$fq_pattern` );
		chomp( my @adapters = `ls $tmp/$adapter_pattern` );
        my $num1=scalar @fqs; ## 20170614
        my $num2=scalar @adapters; ## 20170614  
        if ($num1 > 2 || ($num1 > 2) && ($num2 > 2)){ ## add for novaseq data whose libary lane number > 2; 20170614
            for(my $i=0;$i<$num1;$i+=2){ ## 20170614
                print LIST "$fqs[$i],$fqs[$i+1]\t$adapters[$i],$adapters[$i+1]\n"; ## 20170614
            }
        }else{ ## 20170614
            print LIST join( ",", @fqs ) . "\t" . join( ",", @adapters ) . "\n";
        }
	}
	close LIST;
}


open STAT, ">$shdir/step0.bwt.sh" if(@hostfa); ## 2014-09-10
my @IndexDB ;
foreach my $hostfa (@hostfa){
if ( $hostfa && -s $hostfa ) {
	if ( $alnP eq "soap" ) {
		if ( -s "$hostfa.index.sai" ) {
			push @IndexDB,"$hostfa.index";
			my $hostname=$1 if($hostfa=~/.*\/(.*)/);#2015-09-20 yu
			(-d "$shdir/Index/$hostname") || ` mkdir -p $shdir/Index/$hostname/ `;#
			print STAT "date >$shdir/Index/$hostname/Index_data.fin\n\n";#
		}
		else {
			my $hostname=$1 if($hostfa=~/.*\/(.*)/);
			my $index = $shdir . "/Index/$hostname";
			$hostfa = abs_path($hostfa);
			my $hostfaIndex = $index . "/" . basename($hostfa);
			`mkdir -p $index ` if ( !-d $index );
			print STAT "cd $index\nln -s $hostfa\n$soapindex $hostfaIndex\ndate >$index/Index_data.fin\n\n";
			push @IndexDB,"$hostfaIndex.index";
		}
	}
	elsif ( $alnP eq "bwa" ) {
		if ( -s "$hostfa.bwt" ) {
			push @IndexDB,"$hostfa";
			print STAT "date >$shdir/Index_data.fin\n\n";
		}
		else {
			my $index = $shdir . "/Index";
			$hostfa = abs_path($hostfa);
			my $hostfaIndex = $index . "/" . basename($hostfa);
			`mkdir -p $index ` if ( !-d $index );
			print STAT "cd $index\nln -s $hostfa\n$bwa index $hostfaIndex\ndate >$index/Index_data.fin\n\n";
			push @IndexDB,"$hostfaIndex";
		}
	}
	else {
		die print ">>>Give a  available parameter values for -alnP $! <<<\n" && &usage;
	}
}
}
my ($locate_run,$qsub_run);
my $splits = '\n\n';
if( @hostfa){
	close STAT;
	$locate_run .= "sh step0.bwt.sh &\n" if($step=~/0/);
	$qsub_run .= "$superl_work --prefix bwt --resource vf=$bvf --splits \"$splits\" step0.bwt.sh &\n" if($step=~/0/) ;
}
my $check_total_finish;
open STAT,">$shdir/step2.DataStat.sh"; ##split indexdb to DataStat.sh, in order to control vf. 2014-09-10
open(SampleSH,">$shdir/step1.DataClean.sh");
open(HOST,">$shdir/step1.HostClean.sh") if @IndexDB;
open(LIST,">$outdir/Dataclean.total.list");
foreach my $key ( keys %samploutdir ) {
	my $fqP = "fq[12].gz";
	chomp( my @temp = `find $samploutdir{$key} -name "*_[0-9]*list" ` );
    my $check_finish_sample_insertsize; ##add for check finish
    my $fqs_dir = $SystemClean . "/$key"; ##moved from line 166
    my @host_sample;
	foreach my $tmp (@temp) {
		my $fqname = basename($tmp);
		$fqname =~ s/.list//;
		( $tmp =~ m#.+/(\S+)_(\d+)\.# );
		my $datasize_id = $1 . "\t" . $2;
		print SampleSH "cd $samploutdir{$key}/\n";
		my $readfq_mid=$readfq;
		if ($datasize{$datasize_id}) {
			my $gain = rand(0.15) + 1;                                           ##set a small gain in order to make data size is diff
			my $tempdata = sprintf( "%.3f", $datasize{$datasize_id} * $gain );
			$readfq_mid .= " -o $tempdata ";
		}
		print SampleSH "$readfq_mid -f $tmp -3 $samploutdir{$key}/$fqname.fq1 -4 $samploutdir{$key}/$fqname.fq2 1>$fqname.out.stat 2>$fqname.out.err \n";
		print SampleSH "$fqcheck -r $samploutdir{$key}/$fqname.fq1.gz -c $samploutdir{$key}/$fqname.fq1.check & \n";
		print SampleSH "$fqcheck -r $samploutdir{$key}/$fqname.fq2.gz -c $samploutdir{$key}/$fqname.fq2.check \n";
		print SampleSH "$sh_contral $samploutdir{$key}/$fqname.fq1.check \n";
		print SampleSH "$distribute_fqcheck $samploutdir{$key}/$fqname.fq1.check $samploutdir{$key}/$fqname.fq2.check -o $samploutdir{$key}/$fqname &\n";
        if(! @IndexDB){  #add for default output list
            print LIST "$key\t$samploutdir{$key}/$fqname.fq1.gz,$samploutdir{$key}/$fqname.fq2.gz\n";
        }
#my $fqs_dir = $SystemClean . "/$key";
		if (@IndexDB) {
			#my $host_sample = $HostClean[-1] . "/$key";
			#`mkdir -p $host_sample` if ( !-d $host_sample );
			if ( $alnP eq "soap" ) {
				my($read_a,$read_b);
				foreach my $IndexDB (@IndexDB){
					my $hostdir=$1 if($IndexDB=~/.*\/(.*)\.index$/);
					my $host_sample2=$HostClean."/$hostdir/$key";
					(-s $host_sample2) || `mkdir -p $host_sample2`;
					$fqs_dir    = $host_sample2;
					$read_a="$samploutdir{$key}/$fqname.fq1.gz" if(!$read_a);
					$read_b="$samploutdir{$key}/$fqname.fq2.gz" if(!$read_b);
					print HOST "$sh_contral $shdir/Index/$hostdir/Index_data.fin\n";
					print HOST
					"$soap -D $IndexDB -a $read_a -b $read_b -o $host_sample2/$fqname.PE.soap -2 $host_sample2/$fqname.SE.soap 2>$host_sample2/$fqname.soap.log \n";
				 	print HOST
				 	"$extractread $read_a $read_b $host_sample2/$fqname.PE.soap  $host_sample2/$fqname.SE.soap $host_sample2 \n";
				 	print HOST "$fqcheck -r $host_sample2/$fqname.nohost.fq1.gz -c $host_sample2/$fqname.nohost.fq1.check & \n";
				 	print HOST "$fqcheck -r $host_sample2/$fqname.nohost.fq2.gz -c $host_sample2/$fqname.nohost.fq2.check \n";
				 	push @host_sample,$host_sample2;
				 	#print SampleSH "find $fqs_dir -name \"*" . $fqP . "\" >$fqs_dir/$key.fqs.list\n";
        			##modify
        			print HOST "date > $host_sample2/$fqname.finish\n"; 
        			$check_finish_sample_insertsize .= " $host_sample2/$fqname.finish ";
        			$check_total_finish .= " $host_sample2/$fqname.finish ";
                    $fqname .= ".nohost";
        			$read_a="$host_sample2/$fqname.fq1.gz";
        			$read_b="$host_sample2/$fqname.fq2.gz";
				} ## add for default output list
				print LIST "$key\t$read_a,$read_b\n";
			}
			elsif ( $alnP eq "bwa" ) {
				foreach my $IndexDB(@IndexDB){
					my $hostdir=$1 if($IndexDB=~/(.*)\.(fa|fasta)$/);
					my $host_sample2=$HostClean."/$hostdir/$key";
					print HOST
				  "$bwa $IndexDB $samploutdir{$key}/$fqname.fq1.gz $samploutdir{$key}/$fqname.fq2.gz 1>$host_sample2/$fqname.bwa.sam 2>$host_sample2/$fqname.bwa.err \n";
				}	
			}
		}else{
			print SampleSH "date > $samploutdir{$key}/$fqname.finish\n";
			$check_finish_sample_insertsize .= " $samploutdir{$key}/$fqname.finish ";
        	$check_total_finish .= " $samploutdir{$key}/$fqname.finish ";
		}
		print SampleSH "\n";
		print HOST "\n" if @IndexDB;
	}
    #	print SampleSH "\n";
    #	modify
    ##print STAT "$triggerAgent --status create --all --notsend $check_finish_sample_insertsize\n" if($check_finish_sample_insertsize);
          #"find $fqs_dir -name \"*" . $fqP . "\" >$fqs_dir/$key.fqs.list &\n";
    my $QCstat_info;
    @IndexDB?($QCstat_info="$key.NonHostQCstat.info.xls"):($QCstat_info="$key.QCstat.info.xls");
    if (@IndexDB){ 
    	foreach my $host_sample(@host_sample){
    	        print STAT "$qcstat_fqcheck -indir $samploutdir{$key}/ -outdir $host_sample -nohdir $host_sample &\n";
    	        #"$triggerAgent --status create $host_sample/$QCstat_info --title \"Data Clean has finished(sample:$key)\" --message \"Data Clean has finished for sample $key,please check the QC information.\" --attach $host_sample/$QCstat_info\n";
    	    }
    }else{ 
        print STAT "$qcstat_fqcheck -indir $samploutdir{$key}/ -outdir $samploutdir{$key} &\n";
        #"$triggerAgent --status create $samploutdir{$key}/$QCstat_info --title \"Data Clean has finished(sample:$key)\" --message \"Data Clean has finished for sample $key,please check the QC information.\" --attach $samploutdir{$key}/$QCstat_info\n";
    }
    print STAT "\n";
}
close LIST;
close SampleSH;
close HOST if @IndexDB;
$outdir=abs_path($outdir);
print STAT "cd $outdir\n";
      ##"$triggerAgent --status create --all --notsend $check_total_finish\n" if($check_total_finish);
my $qn_file;
if (@IndexDB){
	foreach(@IndexDB){
		my $hostdir=$1 if(~/.*\/(.*)\.index$/);
   		print STAT "$qcstat_fqcheck -indir $SystemClean -outdir $outdir -nohdir $HostClean/$hostdir --perfix total.$hostdir\n";
   		$qn_file="$outdir/total.$hostdir.NonHostQCstat.info.xls";
	}
    print STAT "$qcstat_fqcheck -indir $SystemClean -outdir $outdir --perfix total \n";
}else{print STAT "$qcstat_fqcheck -indir $SystemClean -outdir $outdir --perfix total \n";}
## add for qc report 2014-09-10
if(@IndexDB){
    print STAT "ls  $SystemClean/*/*.png > $outdir/png.list\n";
}else{print STAT "ls $SystemClean/*/*.png > $outdir/png.list\n";}
$qn_file || ( $qn_file = "$outdir/total.QCstat.info.xls");
print STAT 'perl -ne \'chomp;my @or=split/\t/;print "$or[0]\t$or[1]\t$or[2]\t$or[3]\t$or[10]\t$or[11]\t$or[12]\t$or[13]\t$or[14]\n";\''." $outdir/total.QCstat.info.xls > $outdir/novototal.QCstat.info.xls\n";
print STAT "$qc_report -l $outdir/png.list -qn  $qn_file -q $outdir/novototal.QCstat.info.xls\n",
            "cd $HostClean\n",
            "rm -r */*.soap\n";   #add by zhangjing at 2016-05-03

close STAT;

$locate_run .= "sh step1.DataClean.sh\n" if($step=~/1/) ;
$qsub_run .= "$superl_work --prefix DataClean --resource vf=$svf --splits \"$splits\" step1.DataClean.sh\n" if($step=~/1/);
if (@IndexDB){
	$locate_run .= "sh step1.HostClean.sh\n" if($step=~/2/);
	$qsub_run .="$superl_work --prefix HostClean --resource vf=$hvf --splits \"$splits\" step1.HostClean.sh\n" if($step=~/2/);
}
$locate_run .= "sh step2.DataStat.sh\n" if($step=~/3/);
$qsub_run .= "$superl_work --prefix DataStat --resource vf=800M --splits \"$splits\" step2.DataStat.sh\n" if($step=~/3/);

open WORK,">$shdir/Data_Clean.sh";#yu 2015-11-10
if($notrun){
    print WORK "cd $shdir\n$qsub_run\n";
	exit;
}
$locate ? ( print WORK "cd $shdir\n$locate_run\n" && system"cd $shdir
$locate_run" ) : ( print WORK "cd $shdir\n$qsub_run\n" && system"cd $shdir
$qsub_run" );

close WORK;

#=====End of Main=====#

sub getPinfo() {
	my ( $Pinfo, $sample_insert, $path, $datasize ) = @_;
	open INFO, $Pinfo or die "can not open $Pinfo $!";
	while (<INFO>) {
		next if /^#/;
		next if /^$/;
		chomp;
		my @tmp = split(/\s+/);
		die "Please assign a available value for  $tmp[0] $. ."
		  if $#tmp < 4;
        if(! -s "$tmp[1]/$tmp[4]"){
            warn"$tmp[0]'s RawData Pathway is not exists!\n";
            next;
        }
		my $tmpID = $tmp[0] . "\t" . $tmp[2];    #Samplename\tInsertsize
		$sample_insert->{$tmpID} = $tmpID
		  if !exists( $sample_insert->{$tmpID} );
		$path->{$tmpID} .= $tmp[1] . "/" . $tmp[4] . "\t";
		$tmp[3] =~ s/,//;
		$datasize->{$tmpID} += $tmp[3];
	}
	close INFO;
}
