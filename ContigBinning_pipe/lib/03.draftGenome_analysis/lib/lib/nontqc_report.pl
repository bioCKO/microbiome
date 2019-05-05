#!/usr/bin/perl -w 
use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use List::Util qw(first max);
use FindBin qw($Bin);

my ($lst,$dir,$qcstat);
GetOptions(
		"list=s" => \$lst,
		"qcstat=s"	=> \$qcstat,
		"outdir=s"      => \$dir,
);
($lst && $qcstat) || die"
Name: $0
escription: Perl to get QC webreport.	
Date: 20160225  accodring to meta QC report 
Connector: lishanshan[AT]novogene.com
Version: v1.0
Usage1: perl $0 --list image.list --table qc_stat.xls --outdir .
Options:
	*-list  	 [str]      list of GC.png and Errer.png for cleandata
	*-qcstat 	 [str]		qc_stat.xls
	--outdir	 [str]		pathway for output.default = "."
";


for ($lst, $qcstat) { (-s $_) || die "Not exist: $_.\n"}
$dir ||= ".";
system("mkdir -p $dir $dir/QC_report  $dir/QC_report/image");
system("cp $Bin/logo.png $dir/QC_report/image/logo.png");

#read qc_stat.xls
my $qc_tab;
if(-s $qcstat){
	for(`less $qcstat`){
		/^#/ && $_=~s/^#//;
		chomp;
		my @l = split /\t/ ;
		if($qc_tab){
			$qc_tab .= "\t\t\t<tr><td class=\"center\">".join('</td><td class=\"center\">',@l)."</td></tr>\n";
		}else{
			$qc_tab = "\t\t<tr class=\"head\"><th>".join('</th><th>',@l)."</th></tr>\n";
		}
	}
}

#read image.list
my (%name, %png);
open Lst, $lst || die $!;
while(<Lst>){
    chomp;
    my $or_png=$_;
    my $bname=$or_png;
    my $sam_name = basename($_);
    $bname =~ s/.*\///;
    $sam_name=~s/\.(GC|Error)\.png$//;
    $name{$sam_name}=1;
    system "cp -f $or_png $dir/QC_report/image";
    $bname=~/GC\.png$/ && ($png{$sam_name}{"base"} = $bname);
    $bname=~/Error\.png$/ && ($png{$sam_name}{"qual"} = $bname);
}
close Lst;

#print 
my @name = sort keys %name;
open OUT,">$dir/QC_report/index.html" || die $!;
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
<p>1)	ȥ������ֵ��53����35���ļ���ﵽһ����Ŀ��Ĭ������Ϊ40����reads��</p>
<p>2)	ȥ����N�ļ���ﵽһ����Ŀ��Ĭ������Ϊ10����reads��</p>
<p>3)	ȥ��Adapter��Ⱦ��Ĭ��Adapter������reads������15 bp���ϵ�overlap����</p>
<h1>3.�ʿؽ������</h1>
<h2>3.1 �������ݲ���ͳ��</h2>
<ol>
<p>�Բ������������ݴ����������ͳ�ơ�Sample ID: ��Ʒ����ID�� Library Size(bp): �Ŀ����Ƭ�δ�С�� Clean Read Length(bp): ���������ð��ǰ��ֱ�ΪRead1��Read2�ĳ��ȣ� Raw Data(Mb): ����Raw Data���������� Raw Read1 Q20(%): Raw Data��Read1������ֵ���ڵ���20�ļ��ռ�������İٷֱȣ� Raw Read2 Q20(%): Raw Data��Read2������ֵ���ڵ���20�ļ��ռ�������İٷֱȣ� Clean Data(Mb): ������Ŀ����������Clean Data���������� Clean Read1 Q20(%): Clean Data��Read1������ֵ���ڵ���20�ļ��ռ�������İٷֱȣ� Clean Read2 Q20(%): Clean Data��Read2������ֵ���ڵ���20�ļ��ռ�������İٷֱȣ� Clean_dataata/Raw_data(%): Clean DataռRaw Data�İٷֱȣ���ʾ���ݿ����ʣ� Clean_data GC (%) ��ʾClean Data��GC��������İٷֱ� ��Duplication(%): ��ȫ��ͬ��PE Reads��ռ�ı����� N-Rate(%): ��N�ļ����ռrawdata�ı�����</p>
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
	
</br><h2>3.2 �ʿغ�ļ�������ֲ� & ��������ֲ�</h2>
<ol>
<p>�������ݵ�������Ҫ��ֲ���Q20���ϣ��������ܱ�֤�����߼��������������С��ݲ��������ص㣬����Ƭ��ĩ�˵ļ������һ����ǰ�˵ĵ͡��ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������ΪRead��λ���ϵ�ƽ�������ʰٷֱȡ��ڼ�������ֲ�ͼ�У�������ΪReads�ϵ�λ�ã�������Ϊĳ�ּ���ڸ�λ�õĺ�����������ɫ�ֱ��ʾATGC���ּ����δ������N�ĺ���������</p>
<p><b>��ͼ�У���ͼΪΪ�����������ֲ�ͼ����ͼΪ�����������ֲ�ͼ</b></p>
</ol>
	<div class=\"center\">
		<table class=\"noborder\">\n";

for(my $i=0; $i<=$#name; $i++){
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"qual\"}\" alt=\"qual\" width=\"540\"/></td><td class=\"noborder\"><img src=\"./image/$png{$name[$i]}{\"base\"}\" alt=\"base\" width=540\"/></td></tr>\n";
	print OUT "\t\t<tr class=\"noborder\"><td class=\"noborder\">$name[$i]����������ֲ���</td><td class=\"noborder\">$name[$i]����������ֲ���</td></tr>\n";
}

print OUT "		</table>
		<span class=\"fig\">ͼ 1&nbsp;&nbsp;�����������ֲ� & �����������ֲ�</span>
	</div>

<h1>4.��¼(��ϵ��Ϣ)</h1>
<p><b>����ŵ����Դ������Ϣ�Ƽ����޹�˾</b></p>
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
<p><b></b></p></font>
</dir>
<script type=\"text/javascript\">
<!--
genContent();
//-->
</script>
</body> 
<html> \n";
close OUT;
