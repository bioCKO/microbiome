#!/usr/bin/perl -w 
#===============================================================================
=head1 Name

	ng_CreatReport_v1.0

=head1 Version

	Author:   Tian Shilin,tianshilin@novogene.cn
	Company:  NOVOGENE                                 
	Version:  1.0                                  
	Created:  05/08/2012 10:52:53 AM

=head1 Description
	
	l|lst|list (file) input Sample png list. eg:
		/PROJ/MICRO/MetaGenome/01.DataClean/t/t_300.base.png
        /PROJ/MICRO/MetaGenome/01.DataClean/t/t_300.qual.png
		t and s are Sample name;
	o|dir (str) output dir of report.(default : .)
	q  (file)  QCstat for all sample(Interior)
	qn (file)  QCstat for all sample(Outer)
	
=head1 Usage
	
	ng_CreatReport_v1.0 -l <png list> -q <qcstat.xls> -qn <qcstat_novo.xls> 

=cut

#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use List::Util qw(first max);

my ($help,$lst,$dir,$type,$qcstat,$falen,$qcstat_all);
GetOptions(
		"h|?|help"     => \$help,
		"l|lst|list=s" => \$lst,
		"q|qcstat=s"	=> \$qcstat,
		"qn=s"    => \$qcstat_all,
		"o|dir=s"      => \$dir,
);
die `pod2text $0` if $help;
#print STDERR "Begin at:\t".`date`."\n";
die `pod2text $0` unless $lst;
use FindBin qw($Bin);
#use lib "$Bin/../../00.Commbin";
#use PATHWAY;
#my $lib="$Bin/../../";
#(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin, $!\n";
#my($logo)=get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(LOGO)],$Bin,$lib);
my $logo = "$Bin/logo.png";
my $date = `date +"%Y"-"%m"-"%d"`;
$dir ||= ".";
$type ||= "raw";
open Lst,$lst || die $!;
my (%raw_read,%raw_base,%effective_rate,%q20,%q30,%gc,%png,%error,%Len);
my $qc_tab;
my $qc_tab_all;
my %sample2nohost;
(-s "$dir/QC\_$type\_report") || `mkdir -p $dir/QC\_$type\_report`;

if($qcstat_all && -s $qcstat_all){
#print $qcstat_all,"\n";
	open QCM," >$dir/QC\_$type\_report/monitor.xls";
	if($qcstat_all =~ /total\.\S+QCstat\.info\.xls/)
    {
       print QCM "#Sample\tInsertSize(bp)\tSeqStrategy\tRawData\tCleanData\tClean_Q20\tClean_Q30\tClean_GC(%)\tEffective(%)\tNonHostData\tNonHost_Effective(%)\n";
    }
    elsif($qcstat_all =~ /total\.QCstat\.info\.xls/)
    {
        print QCM "#Sample\tInsertSize(bp)\tSeqStrategy\tRawData\tCleanData\tClean_Q20\tClean_Q30\tClean_GC(%)\tEffective(%)\n";
    }
    my ($n,$m)=(0,0);
	for(`less $qcstat_all`){
		/^#/ && $_=~s/^#//;
		chomp;
		my @l = split/\t/;
		$sample2nohost{$l[0]}=$l[-1] if (!$sample2nohost{$l[0]});
		#print "$l[0]\n";
####for QC monitor###
        if($qcstat_all =~ /total\.\S+QCstat\.info\.xls/)
        {
		    if($l[0]  ne "Sample")
		    {
			    my $nohost =$l[-1];
			    my $raw=$l[3];
			    $nohost=~s/\,//g;
			    $raw=~s/\,//g;
    			#print "$raw,$nohost\n";
	    		my $noeffec= ($nohost/$raw)*100;
		    	if ($nohost < 6000 || $noeffec < 50 )
		    	{
			    	print QCM join ("\t",$l[0],$l[1],$l[2],$l[3],$l[10],$l[11],$l[12],$l[13],$l[14],$l[15]),"\t";
			    	printf QCM "%2.2f\n",$noeffec;
			    	$m++;
			    }
		
    		}
        }
        elsif($qcstat_all =~ /total\.QCstat\.info\.xls/)
        {
            if($l[0]  ne "Sample")
            {
                my $clean = $l[10];
                $clean =~ s/\,//g;
                if($clean < 6000 || $l[-1] < 50)
                {
                    print QCM join ("\t",$l[0],$l[1],$l[2],$l[3],$l[10],$l[11],$l[12],$l[13],$l[14]),"\n";
                    $m++;
                }
            }
        }
	
	######for novo.html###3
		if($qc_tab_all){
			$qc_tab_all .= "\t\t\t<tr><td class=\"center\">".join('</td><td class=\"center\">',@l)."</td></tr>\n";
			$n++;
		}
		else{
			$qc_tab_all = "\t\t<tr class=\"head\"><th>".join('</th><th>',@l)."</th></tr>\n";
		}
	}  
    if($qcstat_all =~ /total\.\S+QCstat\.info\.xls/)
    {
        print QCM "#######The number of samples (NonHostData < 6G or NonHost_Effective(%)<50) is $m\n#######The number of total samples is $n\n";
    	close QCM;
    }
    elsif($qcstat_all =~ /total\.QCstat\.info\.xls/)
    {
        print QCM "#######The number of samples (CleanData < 6G or Effective(%) < 50%) is $m\n#######The number of total samples is $n\n";
        close QCM;
	}
	
}
if($qcstat && -s $qcstat){####add monitor by zhanghao 20180102
	for(`less $qcstat`){
		/^#/ && $_=~s/^#//;
		chomp;
		my @l = split/\t/;
		if($qc_tab){
			if($qcstat_all && $qcstat_all =~ /total\.\S+QCstat\.info\.xls/)
			{
				$qc_tab .= "\t\t\t<tr><td class=\"center\">".join('</td><td class=\"center\">',@l,$sample2nohost{$l[0]})."</td></tr>\n";
			}else
			{
			$qc_tab .= "\t\t\t<tr><td class=\"center\">".join('</td><td class=\"center\">',@l)."</td></tr>\n";
			}
		}else{
			if($qcstat_all && $qcstat_all =~ /total\.\S+QCstat\.info\.xls/)
			{
			$qc_tab = "\t\t<tr class=\"head\"><th>".join('</th><th>',@l,"NonHostData")."</th></tr>\n";
			}else
			{
			$qc_tab = "\t\t<tr class=\"head\"><th>".join('</th><th>',@l)."</th></tr>\n";
			}
		}
	}
}

system("mkdir -p $dir/QC_$type\_report/image");
my %name;
while(<Lst>){
	chomp;
	my $or_png=$_;
	my $bname=$or_png;
	my $sam_name = basename($_);
	$bname =~ s/.*\///;
	$sam_name=~s/\.(base|qual)\.png$//;
	$name{$sam_name}=1;
    system"cp -f $or_png $dir/QC_raw_report/image";
    $bname=~/base\.png$/ && ($png{$sam_name}{"base"} = $bname);
	$bname=~/qual\.png$/ && ($png{$sam_name}{"qual"} = $bname);
}
my @name=sort keys %name;

system("cp $logo $dir/QC_$type\_report/image/logo.png");

open OUT,">$dir/QC_$type\_report/index.html" || die $!;

print OUT "<html>                                                    
<head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=gb2312\">
<title>����ŵ����Դ�����ʿأ�QC������</title>
<style type=\"text/css\">
<!--
body {background-color: #fff; font-size: bigger; margin: 0px; border-left: 12px solid #00f;}
.title {font-size: 32px; font-weight: 900;}
.c1 {text-indent: 2em;}
.c2 {text-indent: 4em;}
.c3 {text-indent: 6em;}
.c4 {text-indent: 8em;}
.noul {text-decoration: none;}
h1 {font-size: 28px; font-weight: 900; padding-top: 10px; margin-left: -10px; padding-left: 10px; border-top: 5px solid #bbf;}
h2 {font-size: 24px; font-weight: 900; text-indent: 1em;}
h3 {font-size: 20px; font-weight: 900; text-indent: 2em;}
h4 {font-size: 16px; font-weight: 900; text-indent: 3em;}
p {text-indent: 2em;}
img {border: 0px; margin: 10px 0;}
table {width: 60%; text-align: center; border-top: solid #000 1px; border-bottom: solid #000 1px; margin: 15px auto 15px auto; border-collapse: collapse;}
caption, .fig {font-weight: 900;}
.center {text-align: center;}
tr.head {background-color: rgb(214, 227, 188); text-align: center;}
th, td {border: solid #000 1px;}
.noborder {border: none; }
.button, .buttonLast {border-bottom: 1px solid #f00; padding: 0 2em; display: table-cell; cursor: pointer; text-align: center;}
.button {border-right: 1px solid #f00;}
.note {color: #f00;}
-->
</style>
<script type=\"text/javascript\">
<!--
function genContent() {
	html = document.body.innerHTML;
	titles = html.match(/<h(\\d)>(.*)<\\/h\\1>/gi);
	content = \"<div id='content'><a name='content' /><h1>Ŀ¼</h1>\";
	for (i = 0; i < titles.length; i++) {
		j = titles[i].replace(/<h(\\d)>(.*)<\\/h\\1>/i, \"\$1\");
		title = titles[i].replace(/<h(\\d)>(.*)<\\/h\\1>/i, \"\$2\");
		html = html.replace(titles[i], \"<h\" + j + \"><a name='content\" + i + \"' />\" + title + \"&nbsp;<a href='#content' title='back to content' class='noul'>^</a></h\" + j + \">\");
		content += \"<div class='c\" + j + \"'><a href='#content\" + i + \"' class='noul'>\" + title + \"</a></div>\";
	}
	content += \"</div>\";
	html = html.replace(/(<h\\d>)/i, content + \"\$1\");
	document.body.innerHTML = html;
}

function tabView(data, title, prefix) {
	var n = data.length;
	var tab = \"<div id='\" + prefix + \"'><center><div style='margin: 10px 0;'>\";
	var code = \"\";
	for (i = 0; i < n; i++) {
		tab += \"<span id='\" + prefix + \"_button_\" + i + \"' class='button' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + i + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", \" + i + \");'>\" + title[i] + \"</span>\";
		code += \"<div id='\" + prefix + \"_\" + i + \"'>\" + data[i] + \"</div>\";
	}
	tab += \"<span style='background-color: #f00;' id='\" + prefix + \"_button_\" + i + \"' class='button' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + i + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", \\\"all\\\");'>All</span><span id='\" + prefix + \"_button_\" + (i + 1) + \"' class='buttonLast' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + (i + 1) + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", -1);'>None</span></div>\";
	code = tab + code + \"</center></div>\";
	return code;
}

function display(prefix, total, target) {
	for (var i = 0; i < total; i++) {
		var showFlag = (i == target || target == \"all\")? \"\" : \"none\";
		document.getElementById(prefix + \"_\" + i).style.display = showFlag;
	}
}

function highlight(prefix, total, target) {
	for (var i = 0; i < total; i++) {
		bgColor = (i == target)? \"#ff0\" : \"#fff\";
		document.getElementById(prefix + \"_\" + i).style.backgroundColor = bgColor;
	}
}
//-->
</script>
</head>
<body>
<div id=\"header\"><img src=\"./image/logo.png\" width=\"20%\" height=\"12%\" border=\"0\" alt=\"Data QC\" /></div>
<ol>
<h1>1.����˵��</h1>
<ol>
<p>�������ݵĲ����Ǿ�����DNA��ȡ�����⡢����������ģ�Ȼ������Щ�����в�������Ч���ݻ��������Ϣ���ݸ߼������������صĸ��ţ����罨��׶λ���ֽ��ⳤ�ȵ�ƫ�����׶λ���ֲ���������������Ǳ���ͨ��һЩ�ֶν���Щ��Ч���ݹ����ų������Ա�֤������Ϣ�������������С�</p>
</ol>
<h2>1.1 ԭʼ�������� </h2>
<ol>
<p>����õ���ԭʼͼ�����ݾ� base calling ת��Ϊ�������ݣ����ǳ�֮Ϊ raw data �� raw reads������� fastq �ļ���ʽ�洢 ���ļ�����*.fq����fastq �ļ�Ϊ�û��õ�����ԭʼ�ļ�������洢 reads �������Լ� reads �Ĳ����������� fastq ��ʽ�ļ���ÿ�� read ������������</p>
		<pre>
		\@HWI-EAS80_4_4_1_554_126
		GTATGCCGTCTTCTGCTTGAAAAAAAAAAACATAAAACAA
		+HWI-EAS80_4_4_1_554_126
		hhhhhhhhhhhhhhhhhhh[hEhSJPLeLdCLEN>IXHAA
		</pre>
		<p><b>ÿ�����й��� 4 ����Ϣ��</b></p>
		<ol>
			<p>�� 1 �����������ƣ��ɲ����ǲ���������index���м�read1��read2��־��</p>
			<p>�� 2 ��������,�ɴ�д��ACGTN����ɣ�</p>
			<p>�� 3 ��������ID��Ҳ��ʡ����ID���ƺ�ֱ���á�+����ʾ��</p>
			<p>�� 4 �������еĲ���������ÿ���ַ���Ӧ�� 2 ��ÿ�������</p>
		</ol>
		<p><b>Solexa����������ֵ�ı�ʾ����:</b></p>
		<ol>
			<p>���������������ASCIIֵ��ʾ�ģ����ݲ���ʱ���õ����������Ĳ�ͬ������ʮ���Ƶ�����ֵ�ķ���Ҳ�������𣬳����ļ��㷽��������ʾ��</p>
			<ol>
				<p>��1������ֵ = �ַ���ASCIIֵ - 64</p>
				<p>��2������ֵ = �ַ���ASCIIֵ - 33</p>
			</ol>
			<p>Solexa����������ֵ�ķ�Χ��[0,40]����ASCIIֵ��ʾΪ[B,h] �� [#,I]��</p>
		</ol>
		<p>Solexa ������������������ֵ������Ӧ��ϵ������أ��������������� E ��ʾ��Solexa �������ֵ�� Q ��ʾ���������¹�ϵ �� <b>Q =-10 log10(E)</b></p>
</ol>
<h2>1.2 ��Ч���� </h2>
<ol>
<p>ԭʼ���������л������ͷ��Ϣ�������������δ����ļ������N��ʾ������Щ��Ϣ��Ժ�������Ϣ������ɺܴ�ĸ��ţ�ͨ����ϸ�Ĺ��˷�������Щ������Ϣȥ���������յõ������ݼ�Ϊ��Ч���ݣ����ǳ�֮Ϊclean data �� clean reads�����ļ������ݸ�ʽ��Raw data��ȫһ����</p>
</ol>
<h1>2.���ݹ��˷���</h1>
<p>1)	ȥ������ֵ��38�ļ���ﵽһ����Ŀ��Ĭ������Ϊ40����reads��</p>
<p>2)	ȥ����N�ļ���ﵽһ����Ŀ��Ĭ������Ϊ10����reads��</p>
<p>3)	ȥ��Adapter��Ⱦ��Ĭ��Adapter������reads������15 bp���ϵ�overlap����</p>
<p>4)	����������Ⱦ�����Ե�ǰ���£������������ݿ���бȶԣ����˵�������������Ⱦ��reads��Ĭ�����ñȶ�һ���ԡ�90%��readsΪ������Ⱦ����</p>
<h1>3.�ʿؽ������</h1>
<h2>3.1 �������ݲ���ͳ��</h2>
<ol>
<p>�Բ������������ݴ�����������ͳ�ƣ��԰�����Ϊ��λ����Sample ID��ʾ��Ʒ���ƣ�Raw Data��ʾ�»�ԭʼ����(Raw Data)��Low_Quality��ʾ�������ļ�����ݣ�N-num ��ʾ��N������ݣ�Adapter ��ʾAdapter���ݣ�Clean Data��ʾ���˵õ�����Ч����(Clean Data)��Q20,Q30��ʾClean Data�в��������С��0.01(����ֵ����20)��0.001(����ֵ����30)�ļ����Ŀ�İٷֱȣ�GC (%) ��ʾClean Data��GC��������İٷֱȣ�Effective Rate��ʾ��Ч����(Clean Data)��ԭʼ����(Raw Data)�İٷֱȡ�</p>
<p><b>ͳ�ƽ������1��ʾ��</b></p>
</ol>
<ol>
		<div class=\"center\">
		<table>
			<caption>�� 1&nbsp;&nbsp;���ݲ���ͳ����Ϣ</caption>\n";
			if($qc_tab){
				print OUT $qc_tab;
				$qc_tab = "";
			}
	print OUT "		</table>
		</div>
</ol>
	
</br><h2>3.2 ��������ֲ� & ��������ֲ�</h2>
<ol>
<p>�������ݵ�������Ҫ��ֲ���Q20���ϣ��������ܱ�֤�����߼��������������С��ݲ��������ص㣬����Ƭ��ĩ�˵ļ������һ����ǰ�˵ĵ͡��ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������ΪReads��λ���ϵļ�������ֲ����ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������Ϊĳ�ּ���ڸ�λ�õĺ�����������ɫ�ֱ��ʾATGC���ּ����δ������N�ĺ���������</p>
<p><b>��ͼ�У���ͼΪ�����������ֲ�ͼ����ͼΪ�����������ֲ�ͼ</b></p>
</ol>
	<div class=\"center\">
		<table class=\"noborder\">\n";

for(my $i=0;$i<=$#name;$i++){
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"qual\"}\" alt=\"qual\" width=\"540\"/></td><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"base\"}\" alt=\"base\" width=540\"/></td></tr>\n";
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\">$name[$i]����������ֲ���</td><td class=\"noborder\">$name[$i]����������ֲ���</td></tr>\n";
}

print OUT "		</table>
		<span class=\"fig\">ͼ 1&nbsp;&nbsp;�����������ֲ� & �����������ֲ�</span>
	</div>

<h1>4.��¼(��ϵ��Ϣ)</h1>
<p><b>����ŵ����Դ�Ƽ��ɷ����޹�˾</b></p>
<ol>
<p>�绰��010-82837801</p>
<p>���棺010-82837801</p>
<p>���䣺novogene\@novogene.cn</p>
<p>����֧�֣�support\@novogene.cn</p>
<p>Website��<a href=\"http://www.novogene.cn\" target=\"_blank\">www.novogene.cn</a></p>
<p>��ַ������������ѧ��·38�Ž������B��21�㣨100083��</p>
</ol>
</ol>
<div class=\"center\">
<font style=\"font-size:20px; width: 100%;\">
<p><b>Thanks!</b></p></font>
</dir>
<script type=\"text/javascript\">
<!--
genContent();
//-->
</script>
</body> 
<html> \n";
close OUT;

$qcstat_all || die;
open OUT,">$dir/QC_$type\_report/novo.html" || die $!;

print OUT "<html>                                                    
<head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=gb2312\">
<title>����ŵ����Դ�����ʿأ�QC������</title>
<style type=\"text/css\">
<!--
body {background-color: #fff; font-size: bigger; margin: 0px; border-left: 12px solid #00f;}
.title {font-size: 32px; font-weight: 900;}
.c1 {text-indent: 2em;}
.c2 {text-indent: 4em;}
.c3 {text-indent: 6em;}
.c4 {text-indent: 8em;}
.noul {text-decoration: none;}
h1 {font-size: 28px; font-weight: 900; padding-top: 10px; margin-left: -10px; padding-left: 10px; border-top: 5px solid #bbf;}
h2 {font-size: 24px; font-weight: 900; text-indent: 1em;}
h3 {font-size: 20px; font-weight: 900; text-indent: 2em;}
h4 {font-size: 16px; font-weight: 900; text-indent: 3em;}
p {text-indent: 2em;}
img {border: 0px; margin: 10px 0;}
table {width: 60%; text-align: center; border-top: solid #000 1px; border-bottom: solid #000 1px; margin: 15px auto 15px auto; border-collapse: collapse;}
caption, .fig {font-weight: 900;}
.center {text-align: center;}
tr.head {background-color: rgb(214, 227, 188); text-align: center;}
th, td {border: solid #000 1px;}
.noborder {border: none; }
.button, .buttonLast {border-bottom: 1px solid #f00; padding: 0 2em; display: table-cell; cursor: pointer; text-align: center;}
.button {border-right: 1px solid #f00;}
.note {color: #f00;}
-->
</style>
<script type=\"text/javascript\">
<!--
function genContent() {
	html = document.body.innerHTML;
	titles = html.match(/<h(\\d)>(.*)<\\/h\\1>/gi);
	content = \"<div id='content'><a name='content' /><h1>Ŀ¼</h1>\";
	for (i = 0; i < titles.length; i++) {
		j = titles[i].replace(/<h(\\d)>(.*)<\\/h\\1>/i, \"\$1\");
		title = titles[i].replace(/<h(\\d)>(.*)<\\/h\\1>/i, \"\$2\");
		html = html.replace(titles[i], \"<h\" + j + \"><a name='content\" + i + \"' />\" + title + \"&nbsp;<a href='#content' title='back to content' class='noul'>^</a></h\" + j + \">\");
		content += \"<div class='c\" + j + \"'><a href='#content\" + i + \"' class='noul'>\" + title + \"</a></div>\";
	}
	content += \"</div>\";
	html = html.replace(/(<h\\d>)/i, content + \"\$1\");
	document.body.innerHTML = html;
}

function tabView(data, title, prefix) {
	var n = data.length;
	var tab = \"<div id='\" + prefix + \"'><center><div style='margin: 10px 0;'>\";
	var code = \"\";
	for (i = 0; i < n; i++) {
		tab += \"<span id='\" + prefix + \"_button_\" + i + \"' class='button' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + i + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", \" + i + \");'>\" + title[i] + \"</span>\";
		code += \"<div id='\" + prefix + \"_\" + i + \"'>\" + data[i] + \"</div>\";
	}
	tab += \"<span style='background-color: #f00;' id='\" + prefix + \"_button_\" + i + \"' class='button' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + i + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", \\\"all\\\");'>All</span><span id='\" + prefix + \"_button_\" + (i + 1) + \"' class='buttonLast' onclick='javascript: highlight(\\\"\" + prefix + \"_button\\\", \" + (n + 2) + \", \" + (i + 1) + \"); display(\\\"\" + prefix + \"\\\", \" + n + \", -1);'>None</span></div>\";
	code = tab + code + \"</center></div>\";
	return code;
}

function display(prefix, total, target) {
	for (var i = 0; i < total; i++) {
		var showFlag = (i == target || target == \"all\")? \"\" : \"none\";
		document.getElementById(prefix + \"_\" + i).style.display = showFlag;
	}
}

function highlight(prefix, total, target) {
	for (var i = 0; i < total; i++) {
		bgColor = (i == target)? \"#ff0\" : \"#fff\";
		document.getElementById(prefix + \"_\" + i).style.backgroundColor = bgColor;
	}
}
//-->
</script>
</head>
<body>
<ol>
<h1>1.����˵��</h1>
<ol>
<p>�������ݵĲ����Ǿ�����DNA��ȡ�����⡢����������ģ�Ȼ������Щ�����в�������Ч���ݻ��������Ϣ���ݸ߼������������صĸ��ţ����罨��׶λ���ֽ��ⳤ�ȵ�ƫ�����׶λ���ֲ���������������Ǳ���ͨ��һЩ�ֶν���Щ��Ч���ݹ����ų������Ա�֤������Ϣ�������������С�</p>
</ol>
<h2>1.1 ԭʼ�������� </h2>
<ol>
<p>����õ���ԭʼͼ�����ݾ� base calling ת��Ϊ�������ݣ����ǳ�֮Ϊ raw data �� raw reads������� fastq �ļ���ʽ�洢 ���ļ�����*.fq����fastq �ļ�Ϊ�û��õ�����ԭʼ�ļ�������洢 reads �������Լ� reads �Ĳ����������� fastq ��ʽ�ļ���ÿ�� read ������������</p>
		<pre>
		\@HWI-EAS80_4_4_1_554_126
		GTATGCCGTCTTCTGCTTGAAAAAAAAAAACATAAAACAA
		+HWI-EAS80_4_4_1_554_126
		hhhhhhhhhhhhhhhhhhh[hEhSJPLeLdCLEN>IXHAA
		</pre>
		<p><b>ÿ�����й��� 4 ����Ϣ��</b></p>
		<ol>
			<p>�� 1 �����������ƣ��ɲ����ǲ���������index���м�read1��read2��־��</p>
			<p>�� 2 ��������,�ɴ�д��ACGTN����ɣ�</p>
			<p>�� 3 ��������ID��Ҳ��ʡ����ID���ƺ�ֱ���á�+����ʾ��</p>
			<p>�� 4 �������еĲ���������ÿ����ĸ��Ӧ�� 2 ��ÿ�������</p>
		</ol>
		<p><b>Solexa����������ֵ�ı�ʾ����:</b></p>
		<ol>
			<p>���������������ASCIIֵ��ʾ�ģ����ݲ���ʱ���õ����������Ĳ�ͬ������ʮ���Ƶ�����ֵ�ķ���Ҳ�������𣬳����ļ��㷽��������ʾ��</p>
			<ol>
				<p>��1������ֵ = �ַ���ASCIIֵ - 64</p>
				<p>��2������ֵ = �ַ���ASCIIֵ - 33</p>
			</ol>
			<p>Solexa����������ֵ�ķ�Χ��[0,40]����ASCIIֵ��ʾΪ[B,h] �� [#,I]��</p>
		</ol>
		<p>Solexa ������������������ֵ������Ӧ��ϵ������أ��������������� E ��ʾ��Solexa �������ֵ�� Q ��ʾ���������¹�ϵ �� <b>Q =-10 log10(E)</b></p>
</ol>
<h2>1.2 ��Ч���� </h2>
<ol>
<p>ԭʼ���������л������ͷ��Ϣ�������������δ����ļ������N��ʾ������Щ��Ϣ��Ժ�������Ϣ������ɺܴ�ĸ��ţ�ͨ����ϸ�Ĺ��˷�������Щ������Ϣȥ���������յõ������ݼ�Ϊ��Ч���ݣ����ǳ�֮Ϊclean data �� clean reads�����ļ������ݸ�ʽ��Raw data��ȫһ����</p>
</ol>
<h1>2.���ݹ��˷���</h1>
<p>1)	ȥ������ֵ��38�ļ���ﵽһ����Ŀ��Ĭ������Ϊ40����reads��</p>
<p>2)	ȥ����N�ļ���ﵽһ����Ŀ��Ĭ������Ϊ10����reads��</p>
<p>3)	ȥ��Adapter��Ⱦ��Ĭ��Adapter������reads������15 bp���ϵ�overlap����</p>
<p>4)	����������Ⱦ�����Ե�ǰ���£������������ݿ���бȶԣ����˵�������������Ⱦ��reads��Ĭ�����ñȶ�һ���ԡ�90%��readsΪ������Ⱦ����</p>

<h1>3.�ʿؽ������</h1>
<h2>3.1 �������ݲ���ͳ��</h2>
<ol>
<p>�Բ������������ݴ�����������ͳ�ƣ��԰�����Ϊ��λ����Sample ID��ʾ��Ʒ���ƣ�Raw Data��ʾ�»�ԭʼ����(Raw Data)��Low_Quality��ʾ�������ļ�����ݣ�N-num ��ʾ��N������ݣ�Adapter ��ʾAdapter���ݣ�Clean Data��ʾ���˵õ�����Ч����(Clean Data)��Q20,Q30��ʾClean Data�в��������С��0.01(����ֵ����20)��0.001(����ֵ����30)�ļ����Ŀ�İٷֱȣ�GC (%) ��ʾClean Data��GC��������İٷֱȣ�Effective Rate��ʾ��Ч����(Clean Data)��ԭʼ����(Raw Data)�İٷֱȡ�</p>
<p><b>ͳ�ƽ������1��ʾ��</b></p>
</ol>
<ol>
		<div class=\"center\">
		<table>
			<caption>�� 1&nbsp;&nbsp;���ݲ���ͳ����Ϣ</caption>\n";
			if($qc_tab_all){
				print OUT $qc_tab_all;
				$qc_tab_all = "";
			}
	print OUT "		</table>
		</div>
</ol>
	
</br><h2>3.2 ��������ֲ� & ��������ֲ�</h2>
<ol>
<p>�������ݵ�������Ҫ��ֲ���Q20���ϣ��������ܱ�֤�����߼��������������С��ݲ��������ص㣬����Ƭ��ĩ�˵ļ������һ����ǰ�˵ĵ͡��ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������ΪReads��λ���ϵļ�������ֲ����ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������Ϊĳ�ּ���ڸ�λ�õĺ�����������ɫ�ֱ��ʾATGC���ּ����δ������N�ĺ���������</p>
<p><b>��ͼ�У���ͼΪ�����������ֲ�ͼ����ͼΪ�����������ֲ�ͼ</b></p>
</ol>
	<div class=\"center\">
		<table class=\"noborder\">\n";
for(my $i=0;$i<=$#name;$i++){
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"qual\"}\" alt=\"qual\" width=\"540\"/></td><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"base\"}\" alt=\"base\" width=540\"/></td></tr>\n";
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\">$name[$i]����������ֲ���</td><td class=\"noborder\">$name[$i]����������ֲ���</td></tr>\n";
}

print OUT "		</table>
		<span class=\"fig\">ͼ 1&nbsp;&nbsp;�����������ֲ� & �����������ֲ�</span>
	</div>

<h1>4.��¼(��ϵ��Ϣ)</h1>
<p><b>����ŵ����Դ�Ƽ��ɷ����޹�˾</b></p>
<ol>
<p>�绰��010-82837801</p>
<p>���棺010-82837801</p>
<p>���䣺novogene\@novogene.cn</p>
<p>����֧�֣�support\@novogene.cn</p>
<p>Website��<a href=\"http://www.novogene.cn\" target=\"_blank\">www.novogene.cn</a></p>
<p>��ַ������������ѧ��·38�Ž������B��21�㣨100083��</p>
</ol>
</ol>
<div class=\"center\">
<font style=\"font-size:20px; width: 100%;\">
<p><b>Thanks!</b></p></font>
</dir>
<script type=\"text/javascript\">
<!--
genContent();
//-->
</script>
</body> 
<html> \n";

close OUT;

#print STDERR "Finaly at:\t".`date`."\n";