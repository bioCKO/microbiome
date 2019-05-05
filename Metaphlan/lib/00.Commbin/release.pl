#!usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use File::Basename;
use utf8;
my %opt;
GetOptions(\%opt,"resultdir:s","outdir:s","info:s","resultfile:s","rpm_path:s","notrun","locate","mem_path:s");

=head1 options:
	--resultdir*        The resultputdir of our project
	--info*             The info of project(r.info/pj.list)
	--outdir*           The outdir of shell
	--resultfile        The result file name 
	--rpm_path          The RRM path you would to mv the result
	--mem_path			The path of member's meta_recodr_release : for example "/TJPROJ1/MICRO/zhanghao/meta_release"
    --notrun            Only print shell not run
=head1 Usage example:
perl release.pl --resultdir /TJPROJ1/MICRO/zhanghao/meta/5.0test/MetaGenome_pipeline_V5.0_result_20180323 --info /TJPROJ1/MICRO/zhanghao/meta/5.0test/pj.list --outdir /TJPROJ1/MICRO/zhanghao/meta/5.0test/Shell 

=cut
($opt{resultdir}) && ($opt{info}) && $opt{outdir}||  die `pod2text $0`;
###输入结果目录，输出shell/step8,delivery.sh,rm_theree_month.sh,rm_half_year.sh
my $check_size="perl $Bin/dirCheckSize.pl";
my $super_work="perl $Bin/super_worker.pl";
foreach ($opt{resultdir},$opt{info},$opt{outdir})
{
        $_=abs_path($_);
}
open INFO ,"< $opt{info}" ||  die "can not open $!\n";
my $info=<INFO>;
close INFO;
chomp $info;
my @info=split (/\t/,$info);
my @res_path=split (/\//,$opt{resultdir});	
#print "$opt{resultdir}\n@res_path\n$res_path[3]\n";
my $rpm_path;
my $resultfile ;
my $result_tar;
my $mem_record_path;
#my $mem_record_path=join ("\/",$res_path[1],$res_path[2],$res_path[3],"meta_release");
$opt{mem_path} ?  $mem_record_path = abspath($opt{mem_path}) :  $mem_record_path="/$res_path[1]/$res_path[2]/$res_path[3]/meta_release";
(-s "$mem_record_path") || `mkdir -p $mem_record_path`;
($opt{rpm_path}) ? $rpm_path = abs_path($opt{rpm_path}) : $rpm_path = "/RRM/MICRO/meta/$res_path[3]/"; 
(-s "$rpm_path") || `mkdir -p $rpm_path`;#指定冷存储路径
if ($opt{resultfile})
{
	$resultfile = abs_path($opt{resultfile}) ; 
	$result_tar = basename($resultfile);
	
}
else 
{
	$resultfile = abs_path($opt{resultdir});
	$result_tar = $res_path[-1];
}


###P101SC17080349-01	P101SC17080349-01-B1-3	暨南大学12个食品和肠道样品的宏基因组测序分析技术服务（委托）合同	C101SC17080329	王士燕	张昊
###jilu表格meta_release_rm_info.list


open LIST ,">>  /PUBLIC/software/MICRO/share/MetaGenome_pipeline/meta_release_rm_info.list";
open MEM_LIST, ">> $mem_record_path/$res_path[3]_meta_release_rm_info.list";

my $delivery_time = `date +%Y%m%d`;
chomp $delivery_time;
####执行就生成的shell 可以加notrun不执行
#chdir $opt{resultdir};
my $res_size=(split (/\s+/,`du -sL  $opt{resultdir} -B G`))[0];
#print "$res_size\n";
chop $res_size;
#print "$res_size\n";
open SH,"> $opt{outdir}/delivery_$delivery_time.sh";
if ($res_size >=100)
{
	print SH "#cd $opt{resultdir}/01.CleanData
#tar -zchf QC_raw_report.tar.gz QC_raw_report
#rm -rf QC_raw_report
cd $opt{resultdir}
tar -zcvhf 03.GenePredict.tar.gz 03.GenePredict & tar -zchvf 04.TaxAnnotation.tar.gz 04.TaxAnnotation & tar -zcvhf 05.FunctionAnnotation.tar.gz 05.FunctionAnnotation
wait
rm -rf 03.GenePredict & rm -rf 04.TaxAnnotation & rm -rf 05.FunctionAnnotation
$check_size $opt{resultdir} 2>../error.log\n";
}
else
{
	print SH "#cd $opt{resultdir}/01.CleanData
#tar -zchf QC_raw_report.tar.gz QC_raw_report
#rm -rf QC_raw_report
cd $opt{resultdir}
tar -zcvhf 01.CleanData.tar.gz 01.CleanData & tar -zcvhf 02.Assembly.tar.gz 02.Assembly & tar -zcvhf 03.GenePredict.tar.gz 03.GenePredict & tar -zchvf 04.TaxAnnotation.tar.gz 04.TaxAnnotation & tar -zcvhf 05.FunctionAnnotation.tar.gz 05.FunctionAnnotation
wait 
rm -rf 01.CleanData & rm -rf 02.Assembly & rm -rf 03.GenePredict & rm -rf 04.TaxAnnotation & rm -rf 05.FunctionAnnotation
$check_size $opt{resultdir} 2>../error.log\n";
}
close SH ;
###Delivery_Date	P_ID	Report_ID	Project_name	C_ID	OM_name	Bioinfo_name	Step	Exec_Date	Exec_Shell	Project_Path
#print LIST join ("\t",@info),"\t","step1\t$delivery_time\t$opt{outdir}/delivery.sh\t$opt{resultdir}\n";
#
#####rm_theree_month.sh
my $exc_three_month_time=`date -d "+3 months" +%Y%m%d`;
chomp $exc_three_month_time;
open SH ,"> $opt{outdir}/rm_three_month_$exc_three_month_time.sh";
print SH "cd $opt{resultdir}/../
tar -zcvhf $result_tar.tar.gz $result_tar 
mv $result_tar.tar.gz $rpm_path
rm -rf $result_tar/* 
if [ -s 01.DataClean ] ; then  
    rm -rf 01.DataClean
fi 
if [ -s 02.Assembly ] ; then 
    rm -rf 02.Assembly
fi
rm -rf 03.GenePredict
rm -rf 04.TaxAnnotation
rm -rf 05.FunctionAnnotation
rm -rf $info[1]
";
close SH;
###P_ID	Report_ID	Project_name	C_ID	OM_name	Bioinfo_name	Step	Exec_Date	Exec_Shell	Project_Path
print LIST "$delivery_time\t",join ("\t",@info),"\t","step1\t$exc_three_month_time\t$opt{outdir}/rm_three_month_$exc_three_month_time.sh\t$opt{resultdir}\n";
print MEM_LIST "$delivery_time\t",join ("\t",@info),"\t","step1\t$exc_three_month_time\t$opt{outdir}/rm_three_month_$exc_three_month_time.sh\t$opt{resultdir}\n";

######rm_half_year.sh
my $exc_half_year_time=`date -d "+6 month" +%Y%m%d`;
chomp $exc_half_year_time;
open SH , "> $opt{outdir}/rm_half_year_$exc_half_year_time.sh";
print SH "rm -rf $rpm_path/$result_tar.tar.gz\n";
######
###P_ID	Report_ID	Project_name	C_ID	OM_name	Bioinfo_name	Step	Exec_Date	Exec_Shell	Project_Path
print LIST "$delivery_time\t",join ("\t",@info),"\t","step2\t$exc_half_year_time\t$opt{outdir}/rm_half_year_$exc_half_year_time.sh\t$opt{resultdir}\n";
print MEM_LIST "$delivery_time\t",join ("\t",@info),"\t","step2\t$exc_half_year_time\t$opt{outdir}/rm_half_year_$exc_half_year_time.sh\t$opt{resultdir}\n";
close LIST;
close MEM_LIST;
close SH;
#####
open del_SH ,"> $opt{outdir}/release_rm_$delivery_time.sh";
print del_SH 
"#$super_work --qalter --cyqt 1 --maxjob 200 --sleept 600  --qopts=' -q micro1.q,micro.q -V ' $opt{outdir}/delivery_$delivery_time.sh --dvf 2G  --prefix delivery  --resource vf=2G --splits '\\n\\n'
#$super_work --qalter --cyqt 1 --maxjob 200 --sleept 600   --qopts=' -q micro1.q,micro.q -V ' $opt{outdir}/rm_three_month_$exc_three_month_time.sh --dvf 2G  --prefix rm_three_month  --resource vf=2G --splits '\\n\\n'
#$super_work --qalter --cyqt 1 --maxjob 200 --sleept 600   --qopts=' -q micro1.q,micro.q -V ' $opt{outdir}/rm_half_year_$exc_half_year_time.sh --dvf 2G  --prefix rm_half_year  --resource vf=2G --splits'\\n\\n'\n";
close del_SH;

##--qalter --cyqt 1 --maxjob 200 --sleept 600   --qopts='-q micro1.q,micro.q -V '   --dvf 7G  --prefix bwt --resource vf=8G --splits "\n\n"
my $qsub="$super_work --qalter --cyqt 1 --maxjob 200 --sleept 600   --qopts='-q micro1.q,micro.q -V '  $opt{outdir}/delivery_$delivery_time.sh --dvf 2G  --prefix delivery --resource vf=2G --splits \"\n\n\"\n";
my $locate_run="sh $opt{outdir}/delivery_$delivery_time.sh \n ";
$opt{locate} && system ("$locate_run");
$opt{notrun} || system ("$qsub");
