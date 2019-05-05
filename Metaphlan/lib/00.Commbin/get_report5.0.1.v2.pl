#!/usr/bin/perl
## end for begin for set blast, db, options
#Version 2.0, Date: 2014-11-20, add default template for metagenomeV2.0.
#Version:2.1, Date: 2015-01-26, add option s2
#Version:3.0, Date: 2015-07-13, report for pepiline3.0
#Version:3.0, Date: 2016-04-01, report for pepiline3.2
#Contact: chenjunru[AT]novogene.com lilifeng[AT]novogene.com
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
my %opt;
$opt{outdir}='./';
GetOptions(\%opt,"s2","ipath","vs","lefse","type:s","stat:s","outdir:s","resultdir:s","info:s","contact:s","rf");
($opt{resultdir} && -s $opt{resultdir}  && $opt{stat} && -s $opt{stat}) || die
"usage: perl get_report.pl <resultdir> <out_dir/>\n
    options:
    *-resultdir [str]  input result directory
    --outdir    [str]  output directory,default=./
    *-stat      [str]  stat.info to generate report.html
    *-type      [str]  choose different assembly Methods discription according to deffirent type
    --s2               to creat result directory for two samples(or just 1 sample)
    --ipath            if there is ipath analysis
    --vs               if there is metastasts analysis
	--lefse			   if there is lefse analysis
    --info      [file] input information of project,format:NHID\\tReportID\\tProject Name
    --contact   [str]  contact name, default=yaonana
    \n";
#get scripts
my $tab2json="perl $Bin/tab2json_meta.pl ";
my $html2pdf="$Bin/html2pdf/html2pdf.sh ";
my $combine="perl $Bin/combine_fig.pl";
my $modify="perl $Bin/modify_img_2_square.pl";
#get software pathway
use lib "$Bin/../00.Commbin";
my $lib = "$Bin/../../lib";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my ($conver,$convert,$css,$logo) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(CONVERT SVG2XXX KEGG_CSS KEGG_LOGO)],$Bin,$lib);
$convert .= " -t png -dpi 300 ";

#get options
my ($id,$report_id,$pro);
if ($opt{info} && -s $opt{info}){
    my $temp=`cat $opt{info}`;
    chomp $temp;
    ($id,$report_id,$pro) = ($temp =~/\t/) ? (split /\t/,$temp) : (split /\s+/,$temp);
}
my $report = ($report_id) ? $report_id : "report";
my $outdir=$opt{outdir};
(-d $outdir) || `mkdir -p $outdir`;
my $resultdir = abs_path($opt{resultdir});
$outdir = abs_path($outdir);
#my $report="$outdir/report";
my %contact=(
    'yaoyuanyuan',['姚远远','15313817852','yaoyuanyuan@novogene.com'],
    'huopianpian',['霍翩翩','18322102992','huopianpian@novogene.com'],
    'yaonana',['姚娜娜','15313835256','yaonana@novogene.com'],
    'yuanyuqi',['袁玉琦','15313835302','yuanyuqi@novogene.com'],
    'zhangqi',['张启','15313835272','zhangqi2820@novogene.com'],
    'liuyue',['刘月','15613283835','liuyue@novogene.com'],
    'wangkun',['王坤','15313817753','wangkun@novogene.com'],
    'wangzhenshan',['王振删','17310771686','wangzhenshan@novogene.com'],
    'zhangyongjing',['张永婧','15313817792','zhangyongjing@novogene.com'],
    'wangshiyan',['王士燕','15313835302','wangshiyan@novogene.com'],
    'chenmengmeng',['陈萌萌','17600612735','chenmengmeng@novogene.com'],
    'difurong',['邸富荣','17310779003','difurong@novogene.com'],
    'yinxueting',['殷雪婷','18811597599','yinxueting@novogene.com'],
    'lichenlu',['李晨露','17805956438','lichenlu@novogene.com'],
    'wangcuiying',['王翠颖','15071413538','wangcuiying@novogene.com'],
    'guchaoyang',['谷朝阳','15153189685','guchaoyang@novogene.com'],
    'gengqingli',['耿庆丽','18602247559','gengqingli@novogene.com'],
    'zhangchunrui',['张春蕊','13102229868','zhangchunrui@novogene.com'],
    'gujingchao',['顾敬超','13502073557','gujingchao@novogene.com'],
    'haoweiwei',['郝薇薇','18744015967','haoweiwei@novogene.com'],
    'zhangye',['张也','18526696267','zhangye@novogene.com'],
    'zhangwenwen',['张雯雯','17560608656','zhangwenwen@novogene.com'],
);
$opt{contact} ||= 'yaonana';
#$opt{id} ||= 'NHT100000';
$opt{contact} eq 'pianpian' && ($opt{contact}='huopianpian');
$opt{contact} eq 'yuanyuqi' && ($opt{contact}='yuanyuqi');
$opt{contact} eq 'yaonana' && ($opt{contact}='yaonana');
$opt{contact} eq 'zhangqi' && ($opt{contact}='zhangqi');
$opt{contact} eq 'liuyue' && ($opt{contact}='liuyue');
$opt{contact} eq 'wangkun' && ($opt{contact}='wangkun');
$opt{contact} eq 'wangzhenshan' && ($opt{contact}='wangzhenshan');
$opt{contact} eq 'zhangyongjing' && ($opt{contact}='zhangyongjing');
$opt{contact} eq 'wangshiyan' && ($opt{contact}='wangshiyan');
$opt{contact} eq 'chenmengmeng' && ($opt{contact}='chenmengmeng');
$opt{contact} eq 'difurong' && ($opt{contact}='difurong');
$opt{contact} eq 'yinxueting' && ($opt{contact}='yinxueting');
$opt{contact} eq 'lichenlu' && ($opt{contact}='lichenlu');
$opt{contact} eq 'wangcuiying' && ($opt{contact}='wangcuiying');
$opt{contact} eq 'guchaoyang' && ($opt{contact}='guchaoyang');
$opt{contact} eq 'gengqingli' && ($opt{contact}='gengqingli');
$opt{contact} eq 'zhangchunrui' && ($opt{contact}='zhangchunrui');
$opt{contact} eq 'gujingchao' && ($opt{contact}='gujingchao');
$opt{contact} eq 'haoweiwei' && ($opt{contact}='haoweiwei');
$opt{contact} eq 'zhangye' && ($opt{contact}='zhangye');
$opt{contact} eq 'zhangwenwen' && ($opt{contact}='zhangwenwen');
$opt{contact} eq 'yaoyuanyuan' || $opt{contact} eq 'huopianpian' || $opt{contact} eq 'yaonana' || $opt{contact} eq 'zhangqi' || $opt{contact} eq 'yuanyuqi' || $opt{contact} eq 'liuyue' || $opt{contact} eq 'wangkun' || $opt{contact} eq 'wangzhenshan' || $opt{contact} eq 'zhangyongjing' || $opt{contact} eq 'wangshiyan' || $opt{contact} eq 'chenmengmeng' ||$opt{contact} eq 'difurong' || $opt{contact} eq 'yinxueting' || $opt{contact} eq 'lichenlu' || $opt{contact} eq 'wangcuiying' || $opt{contact} eq 'guchaoyang' || $opt{contact} eq 'gengqingli' || $opt{contact} eq 'zhangchunrui' || $opt{contact} eq 'gujingchao' || $opt{contact} eq 'haoweiwei' || $opt{contact} eq 'zhangye' || $opt{contact} eq 'zhangwenwen' || die "contact just can be choosed from yaoyuanyuan|huopianpian|yaonana|yuanyuqi|zhangqi|liuyue|wangkun|wangzhenshan|zhangyongjing|wangshiyan|chenmengmeng|difurong|yinxueting|lichenlu|wangcuiying|guchaoyang|gengqingli|zhangchunrui|gujingchao|haoweiwei|zhangye|zhangwenwen\n";

########################main########################################

###start for get png, json and head
(-s $report) && `rm -rf $report`;
(-s $report) || `mkdir -p $report`;
(-s "$report.tar.gz") && `rm $report.tar.gz`;
`cp -rf $Bin/src/ $report/`;##

## for qc report
`cp -rf $resultdir/01.CleanData/QC_raw_report/ $report/src/ `;

#01.CleanData
my $CleanData_head;
if(-s "$resultdir/01.CleanData/novototal.QCstat.info.xls"){
    `$tab2json $resultdir/01.CleanData/novototal.QCstat.info.xls $report/src/json/clean_data.json`;
    my @CleanData_head=split /\t/,`head -n 1 $resultdir/01.CleanData/novototal.QCstat.info.xls`;
    splice(@CleanData_head,2,1); #delete SeqStrategy
    chomp($CleanData_head[$#CleanData_head]);
    $CleanData_head='                                            colNames:["'.(join "\",\"",@CleanData_head).'"],'."\n".'                                            colModel:['."\n";
    foreach(@CleanData_head){
        $CleanData_head.= "                                                {name:\"$_\",index:\"$_\",width:\"100\",align:\"center\"},\n";
    }
    $CleanData_head .= "                                            ],\n";
}
#02.Assembly
my $Assembly_head;
if(-s "$resultdir/02.Assembly/total.scaftigs.stat.info.xls"){
    `$tab2json $resultdir/02.Assembly/total.scaftigs.stat.info.xls $report/src/json/assembly.json `;
    my @Assembly_head=split /\t/,`head -n 1 $resultdir/02.Assembly/total.scaftigs.stat.info.xls`;
    chomp($Assembly_head[$#$Assembly_head]);
    $Assembly_head='                                            colNames:["'.(join "\",\"",@Assembly_head).'"],'."\n".'                                            colModel:['."\n";
    foreach(@Assembly_head){
        $Assembly_head.= "                                                {name:\"$_\",index:\"$_\",width:\"100\",align:\"center\"},\n";
    }
    $Assembly_head .= "                                            ],\n";
}

my @assembly_picts=split /\s+/,`ls $resultdir/02.Assembly/*/*.len.png`;
my $assembly_picts_name=basename($assembly_picts[0]);
my $assembly_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/02.Assembly/'.$assembly_picts_name.'" alt="'.$assembly_picts_name.'" title="'.$assembly_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
foreach(@assembly_picts){
    `cp -f $_ $report/src/pictures/02.Assembly/`;
    my $name=basename($_);
    $assembly_picts.='<li><a id="example2" href="src/pictures/02.Assembly/'.$name.'" ><img src="src/pictures/02.Assembly/'.$name.'" alt="'.$name.'" title="'.$name.'" /></a></li>'."\n";
}
$assembly_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";


#03.GeneComponet-01 total gene table
my $total_gene_table;
if(-s "$resultdir/03.GenePredict/UniqGenes/Unigenes.CDS.cdhit.fa.stat.xls"){
    $total_gene_table .= "<table>\n<tbody>\n";
    for(`less -S $resultdir/03.GenePredict/UniqGenes/Unigenes.CDS.cdhit.fa.stat.xls`){
        chomp;
        my @or=split/\t/;
        $total_gene_table .= '<tr>';
        foreach(@or){
            $total_gene_table .= '<td>'.$_.'</td>';
        }
        $total_gene_table .= '</tr>';
    }
    $total_gene_table .= '</tbody>'."\n".'</table>'."\n";
}
#(-s "$resultdir/06.GenePredict/GenePredict/Total.gene.CDS.fa.len.png") && `cp -f $resultdir/06.GenePredict/GenePredict/Total.gene.CDS.fa.len.png $report/src/pictures/04.GeneComp/`;

#03.GeneComponet-genestat
(-s "$resultdir/03.GenePredict/UniqGenes/Unigenes.CDS.cdhit.fa.len.png") && `cp -f $resultdir/03.GenePredict/UniqGenes/Unigenes.CDS.cdhit.fa.len.png $report/src/pictures/03.GeneComp/`;
(-s "$resultdir/03.GenePredict/GeneStat/correlation/correlation.heatmap.png") && `cp -f $resultdir/03.GenePredict/GeneStat/correlation/correlation.heatmap.png $report/src/pictures/03.GeneComp/`;
(-s "$resultdir/03.GenePredict/GeneStat/genebox/group.genebox.png") && `cp -f $resultdir/03.GenePredict/GeneStat/genebox/group.genebox.png $report/src/pictures/03.GeneComp/`;
if(-s "$resultdir/03.GenePredict/GeneStat/venn_flower/venn_flower_display.png"){
    `cp -f $resultdir/03.GenePredict/GeneStat/venn_flower/venn_flower_display.png $report/src/pictures/03.GeneComp/`;
}
(-s "$resultdir/03.GenePredict/GeneStat/core_pan/core.flower.png") && `cp -f $resultdir/03.GenePredict/GeneStat/core_pan/core.flower.png $report/src/pictures/03.GeneComp/`;


##04. taxonomy
#top10
if (-s "$resultdir/04.TaxAnnotation/top/figure/p10.dis.png" && -s "$resultdir/04.TaxAnnotation/top/figure/g10.dis.png") {
#    `$combine $resultdir/04.TaxAnnotation/top/figure/p10.dis.png $resultdir/04.TaxAnnotation/top/figure/g10.dis.png -ph 200 -ftext 'a,b' > $report/src/pictures/04.Taxonomy/top.pg.svg`;
#`$convert $report/src/pictures/04.Taxonomy/top.pg.svg $report/src/pictures/04.Taxonomy/`;
    `$conver +append  $resultdir/04.TaxAnnotation/top/figure/p10.dis.png $resultdir/04.TaxAnnotation/top/figure/g10.dis.png $report/src/pictures/04.Taxonomy/top.pg.png`;
}
if (-s "$resultdir/04.TaxAnnotation/top_group/figure/p10.group.dis.png"&& "$resultdir/04.TaxAnnotation/top_group/figure/g10.group.dis.png"){
#`$combine $resultdir/04.TaxAnnotation/top_group/figure/p10.group.dis.png $resultdir/04.TaxAnnotation/top_group/figure/g10.group.dis.png -ph 200 -ftext 'a,b' > $report/src/pictures/04.Taxonomy/top.pg.g.svg`;
# `$convert $report/src/pictures/04.Taxonomy/top.pg.g.svg $report/src/pictures/04.Taxonomy/`;
    `$conver +append $resultdir/04.TaxAnnotation/top_group/figure/p10.group.dis.png $resultdir/04.TaxAnnotation/top_group/figure/g10.group.dis.png $report/src/pictures/04.Taxonomy/top.pg.g.png`; 
}
#krona
(-s "$resultdir/04.TaxAnnotation/Krona/taxonomy.krona.html") && `cp -f $resultdir/04.TaxAnnotation/Krona/taxonomy.krona.html $report/src/pictures/04.Taxonomy/`;
#(-s "$resultdir/04.TaxAnnotation/Krona/taxonomy.krona.html.files") && `cp -rf $resultdir/04.TaxAnnotation/Krona/taxonomy.krona.html.files $report/src/pictures/04.Taxonomy/`;
(-s "$resultdir/04.TaxAnnotation/Krona/img") && `cp -rf $resultdir/04.TaxAnnotation/Krona/img/ $report/src/pictures/04.Taxonomy/`;
(-s "$resultdir/04.TaxAnnotation/Krona/src") && `cp -rf $resultdir/04.TaxAnnotation/Krona/src/ $report/src/pictures/04.Taxonomy/`;

#anosim
if(-s "$resultdir/04.TaxAnnotation/Anosim"){my @a=`ls $resultdir/04.TaxAnnotation/Anosim/Phylum/*png`;
chomp $a[0];
(-s $a[0] )&&`cp -rf $a[0] $report/src/pictures/04.Taxonomy/anosim.png`;
}

#LDA
my %show;
my ($tax_lda_pics,$tax_roc_pics,$lda_cluster_pics);
if(-s "$resultdir/04.TaxAnnotation/LDA/"){
    my @list;
	chomp(@list=`ls $resultdir/04.TaxAnnotation/LDA/`);
	for my $b(@list){
	    my $sign=$b;
	    my $num=$1 if($sign=~/^(\d+)/);
		$sign=~s/^\d+\_//;
	    if(-s "$resultdir/04.TaxAnnotation/LDA/$b/LDA.$num.png" && -s "$resultdir/04.TaxAnnotation/LDA/$b/LDA.$num.tree.png"){
		    $show{tax_lda}=1;
			system "cp $resultdir/04.TaxAnnotation/LDA/$b/LDA.$num.png $report/src/pictures/04.Taxonomy/LDA.png
			cp $resultdir/04.TaxAnnotation/LDA/$b/LDA.$num.tree.png $report/src/pictures/04.Taxonomy/LDA.tree.png";
			$tax_lda_pics='<table>'."\n".'    <tr>'."\n".'    <td>'."\n".'    <p class="center"><a href="src/pictures/04.Taxonomy/LDA.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/LDA.png" width="100%" height="80%"/></a></p>'."\n".'    </td>'."\n".'    <td>'."\n".'    <p class="center"><a href="src/pictures/04.Taxonomy/LDA.tree.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/LDA.tree.png" width="100%" height="100%"/></a></p>'."\n".'    </td>'."\n".'    </tr>'."\n".'</table>'."\n";
			if(-s "$resultdir/04.TaxAnnotation/LDA/$b/heatmap/cluster.png" ){
			    $show{tax_lda_hp}=1;
				system "cp $resultdir/04.TaxAnnotation/LDA/$b/heatmap/cluster.png $report/src/pictures/04.Taxonomy/lda_cluster.png";
				$lda_cluster_pics='<p class="center">'."\n".'<a href="src/pictures/04.Taxonomy/lda_cluster.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/lda_cluster.png" width="85%" height="85%"/></a>'."\n".'</p>';
			}
			if(-s "$resultdir/04.TaxAnnotation/LDA/$b/ROC/$sign\_ROC.png"){
			    $show{tax_hp_roc}=1;
			    system "cp $resultdir/04.TaxAnnotation/LDA/$b/ROC/*.png  $report/src/pictures/04.Taxonomy/roc.png";
			    $tax_roc_pics='<p class="center">'."\n".'<a href="src/pictures/04.Taxonomy/roc.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/roc.png" width="40%" height="40%"/></a>'."\n".'</p>';
			}			
			last;
		}
	}	
}

###rf roc
my $tax_rf_roc_pic;
if(-s "$resultdir/04.TaxAnnotation/rf_roc/")
{

	print "rest\t$resultdir/04.TaxAnnotation/rf_roc/\n";
	my %tax_show_rf_roc;
	for my $max_auc_train (`ls $resultdir/04.TaxAnnotation/rf_roc/*/*/*max*train.xls`)
	{
		chomp $max_auc_train;
		my @impplot;
		my @cv_auc_point;
		print "max\t$max_auc_train\n";
		if(-s "$max_auc_train")
		{
			#chomp $max_auc_train;
		print "max\t$max_auc_train\n";

			my($filename,$directories,$suffix)=fileparse($max_auc_train);
			print "directories\t$directories\n";
			if(-s "$directories/../trainset_group_max_roc.png")
			{
				$show{tax_show_rf_roc}=1;
				$tax_show_rf_roc{"3"}="tax_show_group_max_roc.png";
				system("cp -rf $directories/../trainset_group_max_roc.png $report/src/pictures/04.Taxonomy/tax_show_group_max_roc.png");
			}
			if (-s "$directories/trainset_auc.png")
			{
				$show{tax_nvar_roc}=1;
				$tax_show_rf_roc{"2"}="tax_show_var_auc.png";
				system("cp -rf $directories/trainset_auc.png $report/src/pictures/04.Taxonomy/tax_show_var_auc.png");
				
			}
			
			open MAX ,"< $max_auc_train";####找到*/group/max
			<MAX>;
			my $line =<MAX>;
			chomp $line;
			my @max=split(/\t/,$line);
			#my $max{$vs_dir}=$max[0];
			close MAX;

	
			for my $max_png (`ls $directories/$max[0]/*.png`)
			{
				chomp $max_png;
				push (@cv_auc_point,$max_png) if($max_png=~/cverrof\.png/);
				if($max_png=~/impplot.*\.png/)
				{
					push (@impplot,$max_png) 
				}
				if($max_png=~/trainset\.ROC\.png/)
				{
					$show{tax_dan_roc}=1;
					my $roc_png=basename($max_png);
					$tax_show_rf_roc{"1"}="tax_show_ROC.png";					
					system("cp -rf $max_png $report/src/pictures/04.Taxonomy/tax_show_ROC.png");
					
				}
			}
			if (-s "$directories/trainset.point_auc.png")
			{
				push (@cv_auc_point,"$directories/trainset.point_auc.png");
			}
			
##########combine png 
			if(scalar @cv_auc_point == 2 )
			{
				$show{tax_cv_auc_point}=1;
				my $cv_auc_point=join(" ",@cv_auc_point);
				system("$combine $cv_auc_point -ftext 'a,b' >  $report/src/pictures/04.Taxonomy/tax_show_ea.svg");
				system("$convert $report/src/pictures/04.Taxonomy/tax_show_ea.svg $report/src/pictures/04.Taxonomy/");
				system("rm -rf  $report/src/pictures/04.Taxonomy/tax_show_ea.svg");

			#	`$combine $kegg_dir/$i/cluster.$i.diff.png $kegg_dir/$i/PCA/PCA12_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg`;
			#	`$convert $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
			}
			if(scalar @impplot == 2)
			{
				$show{tax_imp}=1;
				my $impplot =join(" ",@impplot);
				system("$combine $impplot -ftext 'a,b' >  $report/src/pictures/04.Taxonomy/tax_imp.svg");
				system("$convert $report/src/pictures/04.Taxonomy/tax_imp.svg $report/src/pictures/04.Taxonomy/");
				system("rm -rf  $report/src/pictures/04.Taxonomy/tax_imp.svg");				
			}
		
		last ;
		#tax_roc_pics
		}
	}
	
	if($show{tax_show_rf_roc})
	{
		$tax_rf_roc_pic.=' <div class="albumSlider">
		<div class="fullview"> <img src="src/pictures/04.Taxonomy/'.$tax_show_rf_roc{"1"}. '" alt="' .$tax_show_rf_roc{"1"}. '" title="' .$tax_show_rf_roc{"1"}. '" /></div>
			<div class="slider">
				<div class="button movebackward" title="向上滚动"></div>
				<div class="imglistwrap">
				<ul class="imglist">';
		foreach my $num_key (sort keys %tax_show_rf_roc)
		{
			my $pic_name=$tax_show_rf_roc{$num_key};
			$tax_rf_roc_pic.=' <li><a id="example2" href="src/pictures/04.Taxonomy/'.$pic_name.'" ><img src="src/pictures/04.Taxonomy/'.$pic_name.'" alt="'.$pic_name.'" title="'.$pic_name.'" /></a></li>';
		}
		
		$tax_rf_roc_pic.='</ul>
				</div>
				<div class="button moveforward" title="向下滚动"></div>
			</div>
		</div>';
	}
	
	
}


















##Metastats
my $workdir = abs_path("$resultdir/../");
my $tax_dir = "$workdir/04.TaxAnnotation/MicroNR/MicroNR_stat/";
my @tax_list=("species","genus","family","order","class","phylum");
foreach my $i(@tax_list){
    if (-s "$resultdir/04.TaxAnnotation/MetaStats/$i/boxplot/top.12.png"){
	    $show{tax_box}=1;
		system"cp -rf $resultdir/04.TaxAnnotation/MetaStats/$i/boxplot/top.12.png $report/src/pictures/04.Taxonomy/";
		last;
	}
}


foreach my $i(@tax_list){
    if (-s "$resultdir/04.TaxAnnotation/MetaStats/$i/boxplot/combine_box/combined.png"){
        $show{diff_com}=1;
        system"cp -rf $resultdir/04.TaxAnnotation/MetaStats/$i/boxplot/combine_box/combined.png $report/src/pictures/04.Taxonomy/combined_tax.png";
        last;
    }
}

foreach my $i(@tax_list){
    if (-s "$resultdir/04.TaxAnnotation/MetaStats/$i/cluster.$i.diff.png"){
	    $show{tax_diff}=1;
		`$combine  $resultdir/04.TaxAnnotation/MetaStats/$i/cluster.$i.diff.png $resultdir/04.TaxAnnotation/MetaStats/$i/PCA/PCA12_2.png -ftext 'a,b' > $report/src/pictures/04.Taxonomy/tax.ph.svg`;
        `$convert $report/src/pictures/04.Taxonomy/tax.ph.svg $report/src/pictures/04.Taxonomy/`;
	    last;
	}
}

#PCA & NMDS
if(-s "$resultdir/04.TaxAnnotation/PCA/phylum/PCA12_2.png" && -s "$resultdir/04.TaxAnnotation/NMDS/genus/NMDS_2.png"){
    system "$combine  $resultdir/04.TaxAnnotation/PCA/phylum/PCA12_2.png $resultdir/04.TaxAnnotation/NMDS/phylum/NMDS_2.png -ftext 'a,b' > $report/src/pictures/04.Taxonomy/PCA_NMDS.svg
	$convert $report/src/pictures/04.Taxonomy/PCA_NMDS.svg $report/src/pictures/04.Taxonomy/";
}

#PCoA
if(-s "$resultdir/04.TaxAnnotation/PCoA/phylum/PCoA12.png"){
    `cp -f $resultdir/04.TaxAnnotation/PCoA/phylum/PCoA12.png $report/src/pictures/04.Taxonomy/PCoA.png`;
}

#cluster
if (-s "$resultdir/04.TaxAnnotation/GeneNums.BetweenSamples.heatmap/genus/genus.genenum.heatmap.txt.png"  && "$resultdir/04.TaxAnnotation/heatmap/figure/cluster.g.png") {
    `$combine  $resultdir/04.TaxAnnotation/GeneNums.BetweenSamples.heatmap/genus/genus.genenum.heatmap.txt.png  $resultdir/04.TaxAnnotation/heatmap/figure/cluster.g.png -ph 250 -ftext 'a,b' >$report/src/pictures/04.Taxonomy/heatmap.svg`;
    `$convert $report/src/pictures/04.Taxonomy/heatmap.svg $report/src/pictures/04.Taxonomy/`;
}

#tree
if (-s "$resultdir/04.TaxAnnotation/Cluster_Tree/figure/Bar.tree.p10.png" && -s "$resultdir/04.TaxAnnotation/NMDS/phylum/NMDS_2.png"){
    `cp $resultdir/04.TaxAnnotation/Cluster_Tree/figure/Bar.tree.p10.png $report/src/pictures/04.Taxonomy/`;
    `$combine  $resultdir/04.TaxAnnotation/Cluster_Tree/figure/Bar.tree.p10.png $resultdir/04.TaxAnnotation/NMDS/phylum/NMDS_2.png -ftext 'a,b' > $report/src/pictures/04.Taxonomy/tax.bp.svg`;
    `$convert $report/src/pictures/04.Taxonomy/tax.bp.svg $report/src/pictures/04.Taxonomy/`;
}

#05.FunctionAnontation
## for gene number picts
my $cazy_num_picts="$resultdir/05.FunctionAnnotation/CAZy/CAZy_Anno/cazy.unigenes.num.png";
my $kegg_num_picts="$resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/kegg.unigenes.num.png";
my $eggnog_num_picts="$resultdir/05.FunctionAnnotation/eggNOG/eggNOG_Anno/eggNOG.unigenes.num.png";
my @num_picts=($kegg_num_picts,$eggnog_num_picts,$cazy_num_picts);
my $num_picts_name=basename($num_picts[0]);
my $num_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$num_picts_name.'" alt="'.$num_picts_name.'" title="'.$num_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
foreach(@num_picts){
    `cp -f $_ $report/src/pictures/05.FunctionAnnotation/`;
    my $name=basename($_);
    $num_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
}
$num_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";


##for genenumber heatmp
my $genenum_heatmap_picts;
if (-s "$resultdir/05.FunctionAnnotation/CAZy/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png" && -s "$resultdir/05.FunctionAnnotation/eggNOG/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png") {
    `cp -f $resultdir/05.FunctionAnnotation/CAZy/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png $report/src/pictures/05.FunctionAnnotation/CAZy.level1.genenum.heatmap.txt-1.png`;
    my $cazy_genenum_heatmap="$report/src/pictures/05.FunctionAnnotation/CAZy.level1.genenum.heatmap.txt-1.png";
    `cp -f $resultdir/05.FunctionAnnotation/KEGG/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png $report/src/pictures/05.FunctionAnnotation/kegg.level1.genenum.heatmap.txt-1.png`;
    my $kegg_genenum_heatmap="$report/src/pictures/05.FunctionAnnotation/kegg.level1.genenum.heatmap.txt-1.png";
    `cp -f $resultdir/05.FunctionAnnotation/eggNOG/GeneNums.BetweenSamples.heatmap/level1/level1.genenum.heatmap.txt-1.png $report/src/pictures/05.FunctionAnnotation/eggNOG.level1.genenum.heatmap.txt-1.png`;
    my $eggnog_genenum_heatmap="$report/src/pictures/05.FunctionAnnotation/eggNOG.level1.genenum.heatmap.txt-1.png";
    my @genenum_heatmap_picts=($kegg_genenum_heatmap,$cazy_genenum_heatmap,$eggnog_genenum_heatmap);
    my $genenum_heatmap_name=basename($genenum_heatmap_picts[0]);
    $genenum_heatmap_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$num_picts_name.'" alt="'.$num_picts_name.'" title="'.$num_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@genenum_heatmap_picts){
        my $name=basename($_);
        $genenum_heatmap_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $genenum_heatmap_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}


## for function relative abundance picts
`cp -f $resultdir/05.FunctionAnnotation/CAZy/CAZy_Anno/Unigenes.level1.bar.png $report/src/pictures/05.FunctionAnnotation/CAZy.Unique.Genes.level1.bar.png`;
my $cazy_rel_picts="$report/src/pictures/05.FunctionAnnotation/CAZy.Unique.Genes.level1.bar.png";
`cp -f $resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/Unigenes.level1.bar.png  $report/src/pictures/05.FunctionAnnotation/KEGG.Unique.Genes.level1.bar.png`;
my $kegg_rel_picts="$report/src/pictures/05.FunctionAnnotation/KEGG.Unique.Genes.level1.bar.png";
`cp -f $resultdir/05.FunctionAnnotation/eggNOG/eggNOG_Anno/Unigenes.level1.bar.png $report/src/pictures/05.FunctionAnnotation/eggNOG.Unique.Genes.level1.bar.png`;
my $eggnog_rel_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG.Unique.Genes.level1.bar.png";
my @rel_picts=($kegg_rel_picts,$eggnog_rel_picts,$cazy_rel_picts);
my $rel_picts_name=basename($rel_picts[0]);
my $rel_picts='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$rel_picts_name.'" alt="'.$rel_picts_name.'" title="'.$rel_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
foreach(@rel_picts){
    my $name=basename($_);
    $rel_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
}
$rel_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";

## for function cluster picts
my $cluster_picts;
if (-s "$resultdir/05.FunctionAnnotation/CAZy/heatmap/cluster.level2.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/heatmap/cluster.ko.png" && -s "$resultdir/05.FunctionAnnotation/eggNOG/heatmap/cluster.og.png") {
#    `cp -f $resultdir/05.FunctionAnnotation/CAZy/heatmap/cluster.level2.png $report/src/pictures/05.FunctionAnnotation/CAZy.cluster.level2.png`;
	`$modify --png  $resultdir/05.FunctionAnnotation/CAZy/heatmap/cluster.level2.png  --out $report/src/pictures/05.FunctionAnnotation/CAZy.cluster.level2.png`;
    my $cazy_cluster_picts="$report/src/pictures/05.FunctionAnnotation/CAZy.cluster.level2.png";
#    `cp -f $resultdir/05.FunctionAnnotation/KEGG/heatmap/cluster.ko.png $report/src/pictures/05.FunctionAnnotation/KEGG.cluster.ko.png`;
	`$modify --png $resultdir/05.FunctionAnnotation/KEGG/heatmap/cluster.ko.png  --out $report/src/pictures/05.FunctionAnnotation/KEGG.cluster.ko.png`;
    my $kegg_cluster_picts="$report/src/pictures/05.FunctionAnnotation/KEGG.cluster.ko.png";
#    `cp -f $resultdir/05.FunctionAnnotation/eggNOG/heatmap/cluster.og.png $report/src/pictures/05.FunctionAnnotation/eggNOG.cluster.og.png`;
	`$modify --png $resultdir/05.FunctionAnnotation/eggNOG/heatmap/cluster.og.png --out $report/src/pictures/05.FunctionAnnotation/eggNOG.cluster.og.png`;
    my $eggnog_cluster_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG.cluster.og.png";
    my @cluster_picts=($kegg_cluster_picts,$eggnog_cluster_picts,$cazy_cluster_picts);
    my $cluster_picts_name=basename($cluster_picts[0]);
    $cluster_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$cluster_picts_name.'" alt="'.$cluster_picts_name.'" title="'.$cluster_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@cluster_picts){
        my $name=basename($_);
        $cluster_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $cluster_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

## function PCA & NMDS analysis
my ($pca_picts,$kegg_pca_picts,$eggnog_pca_picts,$cazy_pca_picts);
if(-s "$resultdir/05.FunctionAnnotation/CAZy/PCA/level2/PCA12_2.png" && -s "$resultdir/05.FunctionAnnotation/CAZy/NMDS/level2/NMDS_2.png"){
    system "$combine  $resultdir/05.FunctionAnnotation/CAZy/PCA/level2/PCA12_2.png $resultdir/05.FunctionAnnotation/CAZy/NMDS/level2/NMDS_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/CAZy_PCA_NMDS.svg
	$convert $report/src/pictures/05.FunctionAnnotation/CAZy_PCA_NMDS.svg $report/src/pictures/05.FunctionAnnotation/";
    $cazy_pca_picts="$report/src/pictures/05.FunctionAnnotation/CAZy_PCA_NMDS.png";
}
if(-s "$resultdir/05.FunctionAnnotation/KEGG/PCA/ko/PCA12_2.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/NMDS/ko/NMDS_2.png"){
    system "$combine  $resultdir/05.FunctionAnnotation/KEGG/PCA/ko/PCA12_2.png $resultdir/05.FunctionAnnotation/KEGG/NMDS/ko/NMDS_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/KEGG_PCA_NMDS.svg
	$convert $report/src/pictures/05.FunctionAnnotation/KEGG_PCA_NMDS.svg $report/src/pictures/05.FunctionAnnotation/";
    $kegg_pca_picts="$report/src/pictures/05.FunctionAnnotation/KEGG_PCA_NMDS.png";
}
if(-s "$resultdir/05.FunctionAnnotation/eggNOG/PCA/og/PCA12_2.png" && -s "$resultdir/05.FunctionAnnotation/eggNOG/NMDS/og/NMDS_2.png"){
    system "$combine  $resultdir/05.FunctionAnnotation/eggNOG/PCA/og/PCA12_2.png $resultdir/05.FunctionAnnotation/eggNOG/NMDS/og/NMDS_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/eggNOG_PCA_NMDS.svg
	$convert $report/src/pictures/05.FunctionAnnotation/eggNOG_PCA_NMDS.svg $report/src/pictures/05.FunctionAnnotation/";
    $eggnog_pca_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG_PCA_NMDS.png";

my @pca_picts=($kegg_pca_picts,$eggnog_pca_picts,$cazy_pca_picts);
my $pca_picts_name=basename($pca_picts[0]);
$pca_picts='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$pca_picts_name.'" alt="'.$pca_picts_name.'" title="'.$pca_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
foreach(@pca_picts){
    my $name=basename($_);
    $pca_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
}
$pca_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

## function PCoA analysis
my ($pcoa_picts,$kegg_pcoa_picts,$eggnog_pcoa_picts,$cazy_pcoa_picts);
if(-s "$resultdir/05.FunctionAnnotation/CAZy/PCoA/level1/PCoA12.png"){
    `cp -f $resultdir/05.FunctionAnnotation/CAZy/PCoA/level1/PCoA12.png $report/src/pictures/05.FunctionAnnotation/CAZy_PCoA.png`;
    $cazy_pcoa_picts="$report/src/pictures/05.FunctionAnnotation/CAZy_PCoA.png";
}
if(-s "$resultdir/05.FunctionAnnotation/KEGG/PCoA/level1/PCoA12.png"){
    `cp -f $resultdir/05.FunctionAnnotation/KEGG/PCoA/level1/PCoA12.png $report/src/pictures/05.FunctionAnnotation/KEGG_PCoA.png`;
    $kegg_pcoa_picts="$report/src/pictures/05.FunctionAnnotation/KEGG_PCoA.png";
}
if(-s "$resultdir/05.FunctionAnnotation/eggNOG/PCoA/level1/PCoA12.png"){
    `cp -f $resultdir/05.FunctionAnnotation/eggNOG/PCoA/level1/PCoA12.png $report/src/pictures/05.FunctionAnnotation/eggNOG_PCoA.png`;
    $eggnog_pcoa_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG_PCoA.png";

my @pcoa_picts=($kegg_pcoa_picts,$eggnog_pcoa_picts,$cazy_pcoa_picts);
my $pcoa_picts_name=basename($pcoa_picts[0]);
$pcoa_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$pcoa_picts_name.'" alt="'.$pcoa_picts_name.'" title="'.$pcoa_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
foreach(@pcoa_picts){
    my $name=basename($_);
    $pcoa_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
}
$pcoa_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

## for function tree
my $circ_picts;
if(-s "$resultdir/05.FunctionAnnotation/CAZy/CAZy_Anno/Unigenes.level1.bar.tree.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/Unigenes.level1.bar.tree.png" && -s "$resultdir/05.FunctionAnnotation/eggNOG/eggNOG_Anno/Unigenes.level1.bar.tree.png"){
    `cp -f $resultdir/05.FunctionAnnotation/CAZy/CAZy_Anno/Unigenes.level1.bar.tree.png $report/src/pictures/05.FunctionAnnotation/CAZy.Unique.Genes.level1.bar.tree.png`;
    my $cazy_circ_picts="$report/src/pictures/05.FunctionAnnotation/CAZy.Unique.Genes.level1.bar.tree.png";
    `cp -f $resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/Unigenes.level1.bar.tree.png $report/src/pictures/05.FunctionAnnotation/KEGG.Unique.Genes.level1.bar.tree.png`;
    my $kegg_circ_picts="$report/src/pictures/05.FunctionAnnotation/KEGG.Unique.Genes.level1.bar.tree.png";
    `cp -f $resultdir/05.FunctionAnnotation/eggNOG/eggNOG_Anno//Unigenes.level1.bar.tree.png $report/src/pictures/05.FunctionAnnotation/eggNOG.Unique.Genes.level1.bar.tree.png`;
    my $eggnog_circ_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG.Unique.Genes.level1.bar.tree.png";
    my @circ_picts=($kegg_circ_picts,$eggnog_circ_picts,$cazy_circ_picts);
    my $circ_picts_name=basename($circ_picts[0]);
    $circ_picts='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$circ_picts_name.'" alt="'.$circ_picts_name.'" title="'.$circ_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@circ_picts){
        my $name=basename($_);
        $circ_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $circ_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

##for function anosim
my ($kegg_anosim_picts,$eggnog_anosim_picts,$cazy_anosim_picts,$anosim_picts);
if(-s "$resultdir/05.FunctionAnnotation/CAZy/Anosim/level2/" && -s "$resultdir/05.FunctionAnnotation/eggNOG/Anosim/level1/" && -s "$resultdir/05.FunctionAnnotation/KEGG/Anosim/ko/"){
    chomp(my @f=`ls $resultdir/05.FunctionAnnotation/CAZy/Anosim/level2/*.png`);
	if(-s $f[0]){
        `cp -f $f[0] $report/src/pictures/05.FunctionAnnotation/CAZy_anosim.png`;
        $cazy_anosim_picts="$report/src/pictures/05.FunctionAnnotation/CAZy_anosim.png";
	}
    chomp(my @g=`ls $resultdir/05.FunctionAnnotation/KEGG/Anosim/ko/*.png`);
	if(-s $g[0]){
        `cp -f $g[0] $report/src/pictures/05.FunctionAnnotation/KEGG_anosim.png`;
        $kegg_anosim_picts="$report/src/pictures/05.FunctionAnnotation/KEGG_anosim.png";
	}
    chomp(my @h=`ls $resultdir/05.FunctionAnnotation/eggNOG/Anosim/level1/*.png`);
	if(-s $h[0]){
        `cp -rf $h[0] $report/src/pictures/05.FunctionAnnotation/eggNOG_anosim.png`;
        $eggnog_anosim_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG_anosim.png";
	}
    my @anosim_picts=($kegg_anosim_picts,$eggnog_anosim_picts,$cazy_anosim_picts);
    my $anosim_picts_name;
    if(-s $anosim_picts[0]){
        $anosim_picts_name=basename($anosim_picts[0]);
        $anosim_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$anosim_picts_name.'" alt="'.$anosim_picts_name.'" title="'.$anosim_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
        foreach(@anosim_picts){
            my $name=basename($_);
            $anosim_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
        }
        $anosim_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
    }
}



##for LDA

my (@lda_picts,@lda_hp_picts,@lda_roc_picts,$lda_picts,$lda_hp_picts,$lda_roc_picts);
my ($cazy_lda_png,$cazy_hp_png,$cazy_roc_png,$nog_lda_png,$nog_hp_png,$nog_roc_png,$kegg_lda_png,$kegg_hp_png,$kegg_roc_png);
if(-s "$resultdir/05.FunctionAnnotation/CAZy/LDA/level2/" || -s "$resultdir/05.FunctionAnnotation/eggNOG/LDA/og/" || -s "$resultdir/05.FunctionAnnotation/KEGG/LDA/ko/"){
   my @k=`ls $resultdir/05.FunctionAnnotation/KEGG/LDA/ko/*/LDA/*.png`;
   if(@k){
   		foreach my $k (@k)
		{
			chomp $k;
			my ($base,$path,$tmp_prefix) = fileparse($k);
			if (-s $k && -s ("$path/../heatmap/cluster.png")) 
			{
			$show{kegg_lda}=1;
			`cp -f $k $report/src/pictures/05.FunctionAnnotation/kegg_lda.png`;
			$show{kegg_lda} && ($kegg_lda_png="$report/src/pictures/05.FunctionAnnotation/kegg_lda.png") && (push @lda_picts,$kegg_lda_png);
			$show{kegg_lda_hp}=1;
			`$modify --png  $path/../heatmap/cluster.png --out $report/src/pictures/05.FunctionAnnotation/kegg_lda.hp.png`;
			$show{kegg_lda_hp} && ($kegg_hp_png ="$report/src/pictures/05.FunctionAnnotation/kegg_lda.hp.png") && (push @lda_hp_picts,$kegg_hp_png); 
			last;
			}
			elsif($k eq $k[-1])
			{
			$show{kegg_lda}=1;
			`cp -f $k $report/src/pictures/05.FunctionAnnotation/kegg_lda.png`;
			$show{kegg_lda} && ($kegg_lda_png="$report/src/pictures/05.FunctionAnnotation/kegg_lda.png") && (push @lda_picts,$kegg_lda_png);
			}
		
		}
   #chomp $k[0];
   #if(-s $k[0]){
   #    $show{kegg_lda}=1;
   #    `cp -f $k[0] $report/src/pictures/05.FunctionAnnotation/kegg_lda.png`;
   #}
   #$show{kegg_lda} && ($kegg_lda_png="$report/src/pictures/05.FunctionAnnotation/kegg_lda.png") && (push @lda_picts,$kegg_lda_png);
   #my ($base,$path,$tmp_prefix) = fileparse($k[0]);
   #if(-s "$path/../heatmap/cluster.png"){
    #   $show{kegg_lda_hp}=1;
   #    `cp -f $path/../heatmap/cluster.png $report/src/pictures/05.FunctionAnnotation/kegg_lda.hp.png`;
#		`$modify --png  $path/../heatmap/cluster.png --out $report/src/pictures/05.FunctionAnnotation/kegg_lda.hp.png`;
  # }
   #$show{kegg_lda_hp} && ($kegg_hp_png ="$report/src/pictures/05.FunctionAnnotation/kegg_lda.hp.png") && (push @lda_hp_picts,$kegg_hp_png); 
   #chomp(my @roc_kegg=`ls $path/../ROC/*.png`);   
   #if(@roc_kegg){
   #    $show{kegg_roc}=1;
   #    `cp -f $path/../ROC/*.png $report/src/pictures/05.FunctionAnnotation/kegg_lda.roc.png`;
   #}
   #$show{kegg_roc} && ($kegg_roc_png ="$report/src/pictures/05.FunctionAnnotation/kegg_lda.roc.png") && (push @lda_roc_picts,$kegg_roc_png);
   }  
   
   my @j=`ls $resultdir/05.FunctionAnnotation/eggNOG/LDA/level1/*/LDA/*.png`;
   if(@j){
		foreach my $j (@j)
		{
			chomp $j;
			my ($base,$path,$tmp_prefix) = fileparse($j);
			if (-s $j && -s ("$path/../heatmap/cluster.png")) 
			{
			$show{nog_lda}=1;
			`cp -f $j $report/src/pictures/05.FunctionAnnotation/nog_lda.png`;
			$show{nog_lda} && ($nog_lda_png="$report/src/pictures/05.FunctionAnnotation/nog_lda.png") && (push @lda_picts,$nog_lda_png);
			$show{nog_lda_hp}=1;
			`$modify --png $path/../heatmap/cluster.png  --out $report/src/pictures/05.FunctionAnnotation/nog_lda.hp.png`;
			$show{nog_lda_hp} && ($nog_hp_png ="$report/src/pictures/05.FunctionAnnotation/nog_lda.hp.png") && (push @lda_hp_picts,$nog_hp_png); 
			last;
			}
			elsif($j eq $j[-1])
			{
			 $show{nog_lda}=1;
			`cp -f $j  $report/src/pictures/05.FunctionAnnotation/nog_lda.png`;
			$show{nog_lda} && ($nog_lda_png="$report/src/pictures/05.FunctionAnnotation/nog_lda.png") && (push @lda_picts,$nog_lda_png);
			}

		}
   #chomp $j[0];
   #if(-s $j[0]){
   #    $show{nog_lda}=1;
   #    `cp -f $j[0] $report/src/pictures/05.FunctionAnnotation/nog_lda.png`;
   #}
   #$show{nog_lda} && ($nog_lda_png="$report/src/pictures/05.FunctionAnnotation/nog_lda.png") && (push @lda_picts,$nog_lda_png);
   #my ($base,$path,$tmp_prefix) = fileparse($j[0]);  
   #if(-s "$path/../heatmap/cluster.png"){
   #    $show{nog_lda_hp}=1;
#       `cp -f $path/../heatmap/cluster.png $report/src/pictures/05.FunctionAnnotation/nog_lda.hp.png`;
	#   `$modify --png $path/../heatmap/cluster.png  --out $report/src/pictures/05.FunctionAnnotation/nog_lda.hp.png`;
   #}
   #$show{nog_lda_hp} && ($nog_hp_png ="$report/src/pictures/05.FunctionAnnotation/nog_lda.hp.png") && (push @lda_hp_picts,$nog_hp_png); 
   #chomp(my @roc_nog=`ls $path/../ROC/*.png`);   
   #if(@roc_nog){
   #    $show{nog_roc}=1;
   #    `cp -f $path/../ROC/*.png $report/src/pictures/05.FunctionAnnotation/nog_lda.roc.png`;
   #}
   #$show{nog_roc} && ($nog_roc_png ="$report/src/pictures/05.FunctionAnnotation/nog_lda.roc.png") && (push @lda_roc_picts,$nog_roc_png);
   }
   
   my @i=`ls $resultdir/05.FunctionAnnotation/CAZy/LDA/level2/*/LDA/*.png`;
   if(@i){
	   		foreach my $i (@i)
		{
			chomp $i;
			my ($base,$path,$tmp_prefix) = fileparse($i);
			if (-s $i && -s ("$path/../heatmap/cluster.png")) 
			{
			$show{cazy_lda}=1;
			`cp -f $i[0] $report/src/pictures/05.FunctionAnnotation/cazy_lda.png`;
			$show{cazy_lda} && ($cazy_lda_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.png") && (push @lda_picts,$cazy_lda_png);
			$show{cazy_lda_hp}=1;
			`$modify --png $path/../heatmap/cluster.png --out  $report/src/pictures/05.FunctionAnnotation/cazy_lda.hp.png`;
			$show{cazy_lda_hp} && ($cazy_hp_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.hp.png") && (push @lda_hp_picts,$cazy_hp_png);
			last;
			}
			elsif($i eq $i[-1])
			{
			$show{cazy_lda}=1;
			`cp -f $i[0] $report/src/pictures/05.FunctionAnnotation/cazy_lda.png`;
			$show{cazy_lda} && ($cazy_lda_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.png") && (push @lda_picts,$cazy_lda_png);
			}
		}	
   
 #  chomp $i[0];
 #  if(-s $i[0]){
 #      $show{cazy_lda}=1;
 #      `cp -f $i[0] $report/src/pictures/05.FunctionAnnotation/cazy_lda.png`;
 #  }
 #  $show{cazy_lda} && ($cazy_lda_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.png") && (push @lda_picts,$cazy_lda_png);
 #  my ($base,$path,$tmp_prefix) = fileparse($i[0]);
 #  if(-s "$path/../heatmap/cluster.png"){
 #      $show{cazy_lda_hp}=1;
#       `cp -f $path/../heatmap/cluster.png $report/src/pictures/05.FunctionAnnotation/cazy_lda.hp.png`;
	#   `$modify --png $path/../heatmap/cluster.png --out  $report/src/pictures/05.FunctionAnnotation/cazy_lda.hp.png`;
   #}
   #$show{cazy_lda_hp} && ($cazy_hp_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.hp.png") && (push @lda_hp_picts,$cazy_hp_png);
   #chomp(my @roc_cazy=`ls $path/../ROC/*.png`);
   #if(@roc_cazy){
   #    $show{cazy_roc}=1;
   #    `cp -f $path/../ROC/*.png $report/src/pictures/05.FunctionAnnotation/cazy_lda.roc.png`;
   #}
   #$show{cazy_roc} && ($cazy_roc_png = "$report/src/pictures/05.FunctionAnnotation/cazy_lda.roc.png") && (push @lda_roc_picts,$cazy_roc_png);
   }
}
 
#show LDA bar plot 
my $lda_n=@lda_picts;
if($lda_n){
    $show{fun_lda}=1;   
    my $lda_picts_name=basename($lda_picts[0]);
    $lda_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$lda_picts_name.'" alt="'.$lda_picts_name.'" title="'.$lda_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@lda_picts){
        my $name=basename($_);
        $lda_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $lda_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

#show LDA heatmap 
my $lda_hp_n=@lda_hp_picts;
if($lda_hp_n){
    $show{fun_hp}=1;
    my $hp_picts_name=basename($lda_hp_picts[0]);
    $lda_hp_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$hp_picts_name.'" alt="'.$hp_picts_name.'" title="'.$hp_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@lda_hp_picts){
        my $name=basename($_);
        $lda_hp_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $lda_hp_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

#show ROC plot
my $lda_roc_n=@lda_roc_picts;
if($lda_roc_n){
    $show{fun_roc}=1;
    my $roc_picts_name=basename($lda_roc_picts[0]);
    $lda_roc_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$roc_picts_name.'" alt="'.$roc_picts_name.'" title="'.$roc_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@lda_roc_picts){
        my $name=basename($_);
        $lda_roc_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $lda_roc_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";   
}
###for RandForest
###rf roc
my @fun_rf_roc_dir=("$resultdir/05.FunctionAnnotation/KEGG/rf_roc/","$resultdir/05.FunctionAnnotation/CAZy/rf_roc/","$resultdir/05.FunctionAnnotation/eggNOG/rf_roc/");
my $fun_rf_roc_pic;
my %fun_show_rf_roc;
for my $fun_rf_roc_dir (@fun_rf_roc_dir)
{
if(-s "$fun_rf_roc_dir")
{

	print "rest\t$fun_rf_roc_dir\n";

	for my $max_auc_train (`ls $fun_rf_roc_dir/*/*/*max*train.xls`)
	{
		chomp $max_auc_train;
		my @impplot;
		my @cv_auc_point;
		print "max\t$max_auc_train\n";
		if(-s "$max_auc_train")
		{
			chomp $max_auc_train;
		#print "max\t$max_auc_train\n";

			my($filename,$directories,$suffix)=fileparse($max_auc_train);
			print "directories\t$directories\n";
			if(-s "$directories/../trainset_group_max_roc.png")
			{
				$show{fun_show_rf_roc}=1;
				$fun_show_rf_roc{"3"}="fun_show_group_max_roc.png";
				system("cp -rf $directories/../trainset_group_max_roc.png $report/src/pictures/05.FunctionAnnotation/fun_show_group_max_roc.png");
			}
			if (-s "$directories/trainset_auc.png")
			{
				$show{fun_nvar_roc}=1;
				$fun_show_rf_roc{"2"}="fun_show_var_auc.png";
				system("cp -rf $directories/trainset_auc.png $report/src/pictures/05.FunctionAnnotation/fun_show_var_auc.png");
				
			}
			
			open MAX ,"< $max_auc_train";####找到*/group/max
			<MAX>;
			my $line =<MAX>;
			chomp $line;
			my @max=split(/\t/,$line);
			#my $max{$vs_dir}=$max[0];
			close MAX;

	
			for my $max_png (`ls $directories/$max[0]/*.png`)
			{
				chomp $max_png;
				push (@cv_auc_point,$max_png) if($max_png=~/cverrof\.png/);
				if($max_png=~/impplot.*\.png/)
				{
					push (@impplot,$max_png) 
				}
				if($max_png=~/trainset\.ROC\.png/)
				{
					$show{fun_dan_roc}=1;
					my $roc_png=basename($max_png);
					$fun_show_rf_roc{"1"}="fun_show_ROC.png";					
					system("cp -rf $max_png $report/src/pictures/05.FunctionAnnotation/fun_show_ROC.png");
					
				}
			}
			if (-s "$directories/trainset.point_auc.png")
			{
				push (@cv_auc_point,"$directories/trainset.point_auc.png");
			}
			
##########combine png 
			if(scalar @cv_auc_point == 2 )
			{
				$show{fun_cv_auc_point}=1;
				my $cv_auc_point=join(" ",@cv_auc_point);
				#print "cv @cv_auc_point\n";
				system("$combine $cv_auc_point -ftext 'a,b' >  $report/src/pictures/05.FunctionAnnotation/fun_show_ea.svg");
				system("$convert $report/src/pictures/05.FunctionAnnotation/fun_show_ea.svg $report/src/pictures/05.FunctionAnnotation/");
				#system("rm -rf  $report/src/pictures/05.FunctionAnnotation/fun_show_ea.svg");

			#	`$combine $kegg_dir/$i/cluster.$i.diff.png $kegg_dir/$i/PCA/PCA12_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg`;
			#	`$convert $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
			}
			if(scalar @impplot == 2)
			{
				$show{fun_imp}=1;
				my $impplot =join(" ",@impplot);
					print "im\t$impplot\n";
				system("$combine $impplot -ftext 'a,b' >  $report/src/pictures/05.FunctionAnnotation/fun_imp.svg");
				system("$convert $report/src/pictures/05.FunctionAnnotation/fun_imp.svg $report/src/pictures/05.FunctionAnnotation/");
				#system("rm -rf  $report/src/pictures/05.FunctionAnnotation/fun_imp.png.svg");				
			}
		
		last ;
		#tax_roc_pics
		}
	}
	
	if($show{fun_show_rf_roc})
	{
		$fun_rf_roc_pic.=' <div class="albumSlider">
		<div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$fun_show_rf_roc{"1"}. '" alt="' .$fun_show_rf_roc{"1"}. '" title="' .$fun_show_rf_roc{"1"}. '" /></div>
			<div class="slider">
				<div class="button movebackward" title="向上滚动"></div>
				<div class="imglistwrap">
				<ul class="imglist">';
		foreach my $num_key (sort keys %fun_show_rf_roc)
		{
			my $pic_name=$fun_show_rf_roc{$num_key};
			$fun_rf_roc_pic.=' <li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$pic_name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$pic_name.'" alt="'.$pic_name.'" title="'.$pic_name.'" /></a></li>';
		}
		
		$fun_rf_roc_pic.='</ul>
				</div>
				<div class="button moveforward" title="向下滚动"></div>
			</div>
		</div>';
	}
	
 }
}
##for metastat anlysis
my (@metastat_picts,@meta_ph_picts,$metastat_picts,$meta_ph_picts);
my($kegg_meta_picts,$kegg_ph_picts,$cazy_meta_picts,$cazy_ph_picts,$eggnog_meta_picts,$eggnog_ph_picts);
###KEGG
my $kegg_dir="$workdir/05.FunctionAnnotation/KEGG/KEGG_stat/Metastats/";
my @kegg_list=("ko","level3","level2","ec","module");
foreach my $i(@kegg_list){
    if(-s "$kegg_dir/$i/boxplot/top.12.png"){
	   $show{kegg_box} =1;
	  `$modify --png $kegg_dir/$i/boxplot/top.12.png --out $report/src/pictures/05.FunctionAnnotation/KEGG.top.12.png`;
	   # `cp -f $kegg_dir/$i/boxplot/top.12.png $report/src/pictures/05.FunctionAnnotation/KEGG.top.12.png`;
	   last;
	}
}
$show{kegg_box} && ($kegg_meta_picts="$report/src/pictures/05.FunctionAnnotation/KEGG.top.12.png") && (push @metastat_picts,$kegg_meta_picts);

foreach my $i(@kegg_list){
    if(-s "$kegg_dir/$i/cluster.$i.diff.png"){
	   $show{kegg_diff} =1;
	   `$combine $kegg_dir/$i/cluster.$i.diff.png $kegg_dir/$i/PCA/PCA12_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg`;
       `$convert $report/src/pictures/05.FunctionAnnotation/kegg_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
	   last;
	}
}
$show{kegg_diff} && ($kegg_ph_picts="$report/src/pictures/05.FunctionAnnotation/kegg_ph.png") && (push @meta_ph_picts,$kegg_ph_picts);
	
###eggNOG
my $egg_dir="$workdir/05.FunctionAnnotation/eggNOG/eggNOG_stat/Metastats/";
my @egg_list=("og","level2");
foreach my $i(@egg_list){
    if(-s "$egg_dir/$i/boxplot/top.12.png"){
	    $show{egg_box}=1;
		`$modify --png $egg_dir/$i/boxplot/top.12.png --out $report/src/pictures/05.FunctionAnnotation/eggNOG.top.12.png`;
		#	`cp -f $egg_dir/$i/boxplot/top.12.png $report/src/pictures/05.FunctionAnnotation/eggNOG.top.12.png`;
		last;
	}
}
$show{egg_box} && ($eggnog_meta_picts="$report/src/pictures/05.FunctionAnnotation/eggNOG.top.12.png") && (push @metastat_picts,$eggnog_meta_picts);

foreach my $i(@egg_list){
    if(-s "$egg_dir/$i/cluster.$i.diff.png"){
	    $show{egg_diff}=1;
		`$combine $egg_dir/$i/cluster.$i.diff.png $egg_dir/$i/PCA/PCA12_2.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/eggnog_ph.svg`;
        `$convert $report/src/pictures/05.FunctionAnnotation/eggnog_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
		last;
	}
}
$show{egg_diff} && ($eggnog_ph_picts="$report/src/pictures/05.FunctionAnnotation/eggnog_ph.png") && (push @meta_ph_picts,$eggnog_ph_picts);

###CAZY
my $cazy_dir="$workdir/05.FunctionAnnotation/CAZy/CAZy_stat/Metastats/";
#my @cazy_list=("level2","level1","EC");
if(-s "$cazy_dir/level2/boxplot/top.12.png"){
	    $show{cazy_box}=1;
		`$modify --png   $cazy_dir/level2/boxplot/top.12.png --out $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
		#`cp -f $cazy_dir/level2/boxplot/top.12.png $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
}elsif(-s "$cazy_dir/EC/boxplot/top.12.png"){
		 $show{cazy_box}=1;
		 `$modify --png   $cazy_dir/EC/boxplot/top.12.png --out $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
	#	`cp -f $cazy_dir/EC/boxplot/top.12.png $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
}elsif(-s "$cazy_dir/level1/boxplot/top.12.png"){
	    $show{cazy_box}=1;
		`$modify --png   $cazy_dir/level1/boxplot/top.12.png --out $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
		#	`cp -f $cazy_dir/level1/boxplot/top.12.png $report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png`;
}
$show{cazy_box} && ($cazy_meta_picts="$report/src/pictures/05.FunctionAnnotation/CAZy.top.12.png") && (push @metastat_picts,$cazy_meta_picts);

if(-s "$cazy_dir/level2/cluster.level2.diff.png"){
	$show{cazy_diff} =1;
    `$combine $cazy_dir/level2/cluster.level2.diff.png $cazy_dir/level2/PCA/PCA12_2.png -ftext 'a,b' >$report/src/pictures/05.FunctionAnnotation/cazy_ph.svg`; 
    `$convert $report/src/pictures/05.FunctionAnnotation/cazy_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
}elsif(-s"$cazy_dir/EC/cluster.ec.diff.png"){
$show{cazy_diff} =1;
`$combine $cazy_dir/EC/cluster.ec.diff.png $cazy_dir/EC/PCA/PCA12_2.png -ftext 'a,b' >$report/src/pictures/05.FunctionAnnotation/cazy_ph.svg`;
`$convert $report/src/pictures/05.FunctionAnnotation/cazy_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
}elsif(-s"$cazy_dir/level1/cluster.ec.diff.png"){
	$show{cazy_diff} =1;
	`$combine $cazy_dir/level1/cluster.ec.diff.png $cazy_dir/level1/PCA/PCA12_2.png -ftext 'a,b' >$report/src/pictures/05.FunctionAnnotation/cazy_ph.svg`;
	`$convert $report/src/pictures/05.FunctionAnnotation/cazy_ph.svg $report/src/pictures/05.FunctionAnnotation/`;
}

$show{cazy_diff} && ($cazy_ph_picts="$report/src/pictures/05.FunctionAnnotation/cazy_ph.png") && (push @meta_ph_picts,$cazy_ph_picts);
	
###show box plot
my $box=@metastat_picts;
if ($box) {
    $show{fun_box}=1;
    my $metastat_picts_name=basename($metastat_picts[0]);
    $metastat_picts='    <div class="albumSlider">'."\n".'       <div class="fullview"> <img src="src/pictures/05.FunctionAnnotation/'.$metastat_picts_name.'" alt="'.$metastat_picts_name.'" title="'.$metastat_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@metastat_picts){
        my $name=basename($_);
        $metastat_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $metastat_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

###show diff plot
my $diff=@meta_ph_picts;
if ($diff) {
    $show{fun_diff}=1;
    my $meta_ph_picts_name=basename($meta_ph_picts[0]);
    $meta_ph_picts='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$meta_ph_picts_name.'" alt="'.$meta_ph_picts_name.'" title="'.$meta_ph_picts_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
    foreach(@meta_ph_picts){
        my $name=basename($_);
        $meta_ph_picts.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
    }
    $meta_ph_picts.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
}

if (-s "$resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/kegg.unigenes.num.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/Unigenes.level1.bar.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/heatmap/cluster.ko.png" && -s "$resultdir/05.FunctionAnnotation/KEGG/PCA/ko/PCA12_2.png") {
    `$combine $resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/kegg.unigenes.num.png $resultdir/05.FunctionAnnotation/KEGG/KEGG_Anno/Unigenes.level1.bar.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/kegg.com.svg`;
        `$convert $report/src/pictures/05.FunctionAnnotation/kegg.com.svg $report/src/pictures/05.FunctionAnnotation/`;
        `$combine $resultdir/05.FunctionAnnotation/KEGG/heatmap/cluster.ko.png $resultdir/05.FunctionAnnotation/KEGG/PCA/ko/PCA12_2.png -ftext 'c,d' > $report/src/pictures/05.FunctionAnnotation/kegg.com2.svg`;
        `$convert $report/src/pictures/05.FunctionAnnotation/kegg.com2.svg $report/src/pictures/05.FunctionAnnotation/`;
}


## 06.ARDB
if(-s "$resultdir/05.FunctionAnnotation/ARDB/bar_plot/antibiotic.png" && -s "$resultdir/05.FunctionAnnotation/ARDB/bar_plot/per.antibiotic.png"){
    `$combine $resultdir/05.FunctionAnnotation/ARDB/bar_plot/antibiotic.png $resultdir/05.FunctionAnnotation/ARDB/bar_plot/per.antibiotic.png -ph 200 -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.svg`;
	`$convert $report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.svg $report/src/pictures/05.FunctionAnnotation/`;
}
(-s "$resultdir/05.FunctionAnnotation/ARDB/Overview/circos.overview.png") && `cp -rf $resultdir/05.FunctionAnnotation/ARDB/Overview/circos.overview.png $report/src/pictures/05.FunctionAnnotation/circos.png`;
(-s "$resultdir/05.FunctionAnnotation/ARDB/ARDB_Tax/ARG_mechanism/mechanism.taxonomy.png") && `cp -rf $resultdir/05.FunctionAnnotation/ARDB/ARDB_Tax/ARG_mechanism/mechanism.taxonomy.png $report/src/pictures/05.FunctionAnnotation/mechanism.png`;

if(-s "$resultdir/05.FunctionAnnotation/ARDB/ARDB_Tax/ARG_taxonomy/._taxonomy.png"){
my @arg_taxonomy=`ls $resultdir/05.FunctionAnnotation/ARDB/ARDB_Tax/ARG_taxonomy/*_taxonomy.png`;
chomp @arg_taxonomy;
my $arg_taxonomy_pics;
if(@arg_taxonomy){   
    if(scalar(@arg_taxonomy)==1){
        system "cp -rf $arg_taxonomy[0] $report/src/pictures/05.FunctionAnnotation/ardb2tax.png";
	    $arg_taxonomy_pics='    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/ardb2tax.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/ardb2tax.png" width="70%" height="70%"/></a>'."\n".
            '    </p>'."\n";
    } elsif(scalar(@arg_taxonomy) > 1){
        my @arg_taxonomy_pics;
        foreach(@arg_taxonomy){
	        system "cp -rf $_ $report/src/pictures/05.FunctionAnnotation/";
		    my $pic_name=basename($_);
	        push @arg_taxonomy_pics,"$report/src/pictures/05.FunctionAnnotation/$pic_name";
	    }	
        my $arg_taxonomy_name=basename($arg_taxonomy_pics[0]);
	    $arg_taxonomy_pics='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$arg_taxonomy_name.'" alt="'.$arg_taxonomy_name.'" title="'.$arg_taxonomy_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
        foreach(@arg_taxonomy_pics){
            my $name=basename($_);
            $arg_taxonomy_pics.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
        }
        $arg_taxonomy_pics.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
	}
}
}
if(-s "$resultdir/05.FunctionAnnotation/ARDB/heatmap/arg_heat/heatmap.png" && -s "$resultdir/05.FunctionAnnotation/ARDB/heatmap/arg_bw/heatmap.bw.png") {
    system "$combine $resultdir/05.FunctionAnnotation/ARDB/heatmap/arg_bw/heatmap.bw.png $resultdir/05.FunctionAnnotation/ARDB/heatmap/arg_heat/heatmap.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/arg_heatmap.svg
	$convert $report/src/pictures/05.FunctionAnnotation/arg_heatmap.svg $report/src/pictures/05.FunctionAnnotation/";
}
if(-s "$resultdir/05.FunctionAnnotation/ARDB/box_plot/Arg_box/group.argbox.png" && -s "$resultdir/05.FunctionAnnotation/ARDB/box_plot/Gene_box/group.genebox.png"){
    system "$combine $resultdir/05.FunctionAnnotation/ARDB/box_plot/Gene_box/group.genebox.png $resultdir/05.FunctionAnnotation/ARDB/box_plot/Arg_box/group.argbox.png -ph 250 -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/ardb_box.svg
	$convert $report/src/pictures/05.FunctionAnnotation/ardb_box.svg $report/src/pictures/05.FunctionAnnotation/";
}

## 06.CARD   add by zhangjing at 2017-04-24
if(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.ppm.png" && -s "$resultdir/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.RelativePercent.png"){
    `$combine $resultdir/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.ppm.png $resultdir/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.RelativePercent.png  -ph 200 -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/antibiotic_card.svg`;
    `$convert $report/src/pictures/05.FunctionAnnotation/antibiotic_card.svg $report/src/pictures/05.FunctionAnnotation/`;
}
(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/circos/circos.overview.png") && `cp -rf  $resultdir/05.FunctionAnnotation/CARD/stat_result/circos/circos.overview.png $report/src/pictures/05.FunctionAnnotation/circos.png`;
my @arg_taxonomy=`ls $resultdir/05.FunctionAnnotation/CARD/stat_result/twocircle/*_taxonomy.png`;
chomp @arg_taxonomy; 
my $arg_taxonomy_pics;
if(@arg_taxonomy){
    if(scalar(@arg_taxonomy)==1){
    system "cp -rf $arg_taxonomy[0] $report/src/pictures/05.FunctionAnnotation/card2tax.png";
    $arg_taxonomy_pics='    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/card2tax.png" target="_blank"><img  src="src/pictures/05.FunctionAnnotation/card2tax.png" width="70%" height="70%"/></a>'."\n".
    '    </p>'."\n";
    }elsif(scalar(@arg_taxonomy) > 1){
        my @arg_taxonomy_pics;
        foreach(@arg_taxonomy){
            system "cp -rf $_ $report/src/pictures/05.FunctionAnnotation/";
            my $pic_name=basename($_);
            push @arg_taxonomy_pics,"$report/src/pictures/05.FunctionAnnotation/$pic_name";
        }
        my $arg_taxonomy_name=basename($arg_taxonomy_pics[0]);
        $arg_taxonomy_pics='    <div class="albumSlider" style="width:880px;">'."\n".'       <div class="fullview2"> <img src="src/pictures/05.FunctionAnnotation/'.$arg_taxonomy_name.'" alt="'.$arg_taxonomy_name.'" title="'.$arg_taxonomy_name.'" /></div>'."\n".'        <div class="slider">'."\n".'            <div class="button movebackward" title="向上滚动"></div>'."\n".'            <div class="imglistwrap">'."\n".'                <ul class="imglist">';
        foreach(@arg_taxonomy_pics){
                    my $name=basename($_);
                                $arg_taxonomy_pics.='<li><a id="example2" href="src/pictures/05.FunctionAnnotation/'.$name.'" ><img src="src/pictures/05.FunctionAnnotation/'.$name.'" alt="'.$name.'"'.' title="'.$name.'" /></a></li>'."\n";
        }
        $arg_taxonomy_pics.='                </ul>'."\n".'            </div>'."\n".'            <div class="button moveforward" title="向下滚动"></div>'."\n".'        </div>'."\n".'    </div>'."\n";
    }
}
if(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/heat.png" && -s "$resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_bw/bw.png"){
    system "$combine $resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_bw/bw.png $resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/heat.png -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/aro_heatmap.svg
    $convert $report/src/pictures/05.FunctionAnnotation/aro_heatmap.svg $report/src/pictures/05.FunctionAnnotation/";
}elsif(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/heat.png"){
    system"cp -rf $resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/heat.png $report/src/pictures/05.FunctionAnnotation/aro_heatmap.png ";
    system"cp -rf $resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/heat.pdf $report/src/pictures/05.FunctionAnnotation/aro_heatmap.pdf ";
    }
if(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/box/genebox/group.genebox.png" && -s "$resultdir/05.FunctionAnnotation/CARD/stat_result/box/arobox/group.ARObox.png"){
    system "$combine $resultdir/05.FunctionAnnotation/CARD/stat_result/box/genebox/group.genebox.png $resultdir/05.FunctionAnnotation/CARD/stat_result/box/arobox/group.ARObox.png -ph 250 -ftext 'a,b' > $report/src/pictures/05.FunctionAnnotation/card_box.svg
    $convert $report/src/pictures/05.FunctionAnnotation/card_box.svg $report/src/pictures/05.FunctionAnnotation/";
    }
 if (-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/flower/venn_flower_display.png")
  {
      system "cp -rf $resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/flower/venn_flower_display.png $report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png" ;}
     elsif(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/flower_G/venn_flower_display.png")
 {system "cp -rf $resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/flower_G/venn_flower_display.png $report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png";}
    elsif(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/venn/venn_display.png")
 {system "cp -rf  $resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/venn/venn_display.png $report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png";}
    elsif(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/venn_G/venn_display.png")
 {system "cp -rf  $resultdir/05.FunctionAnnotation/CARD/stat_result/venn_flower/venn_G/venn_display.png $report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png";}
###card anosim show
 if (-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/Anosim/ARO")
{
	my $file =`ls $resultdir/05.FunctionAnnotation/CARD/stat_result/Anosim/ARO/*.png`;
	chomp $file;
	my $card_anosim_show=(split /\s+/,$file)[0];
	#print "$card_anosim_show\n";
	system"cp -rf $card_anosim_show $report/src/pictures/05.FunctionAnnotation/card_anosim_show.png";
}
###card metastat show
if (-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/Metastats/ARO/boxplot/")
{
	my $file = `ls $resultdir/05.FunctionAnnotation/CARD/stat_result/Metastats/ARO/boxplot/*.png`;
	chomp $file;
	my $card_metastat_show=(split /\s+/,$file)[0];
	system "cp -rf $card_metastat_show $report/src/pictures/05.FunctionAnnotation/card_metastat_show.png";
}
###LDA
	my $card_lda_dir = "$resultdir/05.FunctionAnnotation/CARD/stat_result/LDA/ARO/";
if (-s "$card_lda_dir")
{
	my @card_lda_png = `ls $resultdir/05.FunctionAnnotation/CARD/stat_result/LDA/ARO/*/LDA/*.png`;
	foreach my  $i (@card_lda_png)
	{
		chomp $i;
		my ($base,$path,$tmp_prefix) = fileparse($i);
		if (-s "$i" && -s "$path/../heatmap/cluster.png")
		{
			system "cp -rf $i $report/src/pictures/05.FunctionAnnotation/card_lda_bar.png";
			system "$conver  $path/../heatmap/cluster.png -trim -fuzz 10%  $report/src/pictures/05.FunctionAnnotation/card_lda_heatmap.png";
			last;
		}elsif("$i" eq "$card_lda_png[-1]")
		{
			system "cp -rf $i $report/src/pictures/05.FunctionAnnotation/card_lda_bar.png";
		}
			
	}
}




###end for get png, json and head
my $date = `date +"%Y"-"%m"-"%d"`;
open(OUT,">$report/report.detail.html");
########################report########################################
print OUT  << "XHTML"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" >
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<TITLE> 诺禾致源 Metagenome 分析结题报告 </TITLE>
<META NAME="Author" CONTENT="yanjun\@novogene.cn">
<META NAME="Version" CONTENT="201307v3">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" media="screen" href="src/css/ui.jqgrid.css" />
<link rel="stylesheet" type="text/css" media="screen" href="src/css/smoothness/jquery.ui.all.css" />
<script src="src/js/jquery-1.4.2.min.js" type="text/javascript"></script>
<script src="src/js/i18n/grid.locale-en.js" type="text/javascript"></script>
<script type="text/javascript" src="src/js/jquery.jqGrid.min.js"></script>  
<link rel="stylesheet" type="text/css" href="src/css/text.css">
<link rel="StyleSheet" href="src/js/tree/tree.css" type="text/css">
<link rel="stylesheet" type="text/css" href="src/js/fancybox/jquery.fancybox-1.3.4.css" media="screen" />
<link rel="stylesheet" href="src/css/style.css" />
<script src="src/js/scrollTop.js" type="text/javascript"></script>
<script src="src/js/common.js" type="text/javascript"></script>
<script src="src/js/jquery.albumSlider.min.js" type="text/javascript"></script>
<script type="text/javascript" src="src/js/tree/tree.js"></script>
<script type="text/javascript" src="src/js/fancybox/jquery.mousewheel-3.0.4.pack.js"></script>
<script type="text/javascript" src="src/js/fancybox/jquery.fancybox-1.3.4.pack.js"></script>

<script type="text/javascript">
    \$(document).ready(function() {
        /*
        *   Examples - images
        */

        \$("a#example1").fancybox();

        \$("a#example2").fancybox({
            'overlayShow'   : false,
            'transitionIn'  : 'elastic',
            'transitionOut' : 'elastic'
        });
        \$("a#example3").fancybox({
            'transitionIn'  : 'none',
            'transitionOut' : 'none'    
        });

        \$("a#example4").fancybox({
            'opacity'       : true,
            'overlayShow'   : false,
            'transitionIn'  : 'elastic',
            'transitionOut' : 'none'
        });

        \$("a#example5").fancybox();

        \$("a#example6").fancybox({
            'titlePosition'     : 'outside',
            'overlayColor'      : '#000',
            'overlayOpacity'    : 0.9
        });

        \$("a#example7").fancybox({
            'titlePosition' : 'inside'
        });

        \$("a#example8").fancybox({
            'titlePosition' : 'over'
        });

        \$("a[rel=example_group]").fancybox({
            'transitionIn'      : 'none',
            'transitionOut'     : 'none',
            'titlePosition'     : 'over',
            'titleFormat'       : function(title, currentArray, currentIndex, currentOpts) {
                return '<span id="fancybox-title-over">Image ' + (currentIndex + 1) + ' / ' + currentArray.length + (title.length ? ' &nbsp; ' + title : '') + '</span>';
            }
        });

        /*
        *   Examples - various
        */

        \$("#various1").fancybox({
            'titlePosition'     : 'inside',
            'transitionIn'      : 'none',
            'transitionOut'     : 'none'
        });

        \$("#various2").fancybox();

        \$("#various3").fancybox({
            'width'             : '75%',
            'height'            : '75%',
            'autoScale'         : false,
            'transitionIn'      : 'none',
            'transitionOut'     : 'none',
            'type'              : 'iframe'
        });

        \$("#various4").fancybox({
            'padding'           : 0,
            'autoScale'         : false,
            'transitionIn'      : 'none',
            'transitionOut'     : 'none'
        });
    });
</script>

<style media="print">
.noprint {DISPLAY: none;}
</style>

<div class="noprint">
<div style="display: block;" id="goTopBtn">
<a class="backtotop" title="回顶部"><img src="src/images/goTop.jpg" width="30" height="30" class="back-tip"/></a>
</div>
</div>

<script type="text/javascript"> 
function displaySubMenu(li) { 
var subMenu = li.getElementsByTagName("ul")[0]; 
subMenu.style.display = "block"; 
} 
function hideSubMenu(li) { 
var subMenu = li.getElementsByTagName("ul")[0]; 
subMenu.style.display = "none"; 
} 
</script> 

<script type="text/javascript">
\$(function(){
    //纵向，默认，移动间隔2
    \$('div.albumSlider').albumSlider();
    //横向设置
    \$('div.albumSlider-h').albumSlider({direction:'h',step:3});
});
</script>   

<script type="text/javascript"> <!--assembly-->
    jQuery().ready(function (){
        jQuery("#table_assembly").jqGrid({
                                            url:"src/json/assembly.json",
                                            datatype:"json",
XHTML
;
print OUT "$Assembly_head";
print OUT << "XHTML"
                                            loadonce:true,
                                            rowNum:10,
                                            rowList:[5,10,15,20,50,100,150,200,300,500,1000],
                                            shrinkToFit:true,
                                            autowidth:false,
                                            jsonReader:{
                                                    root:"src/json/assembly.json",
                                                    repeatitems:false,
                                            },
                                            sortable:false,
                                            pager:jQuery('#page_assembly'),
                                            viewrecords:true,
                                            caption:"组装结果 scaftigs 的统计",
                                            height:"100%",
                                            width:"100%",
            })
     })
</script>   

<script type="text/javascript"> <!--clean data-->
    jQuery().ready(function (){
        jQuery("#table_clean_Data").jqGrid({
                                            url:"src/json/clean_data.json",
                                            datatype:"json",
XHTML
;
print OUT "$CleanData_head";
print OUT << "XHTML"
                                            loadonce:true,
                                            rowNum:10,
                                            rowList:[5,10,15,20,50,100,150,200,300,500,1000],
                                            shrinkToFit:true,
                                            autowidth:false,
                                            jsonReader:{
                                                    root:"src/json/clean_data.json",
                                                    repeatitems:false,
                                            },
                                            sortable:false,
                                            pager:jQuery('#page_clean_Data'),
                                            viewrecords:true,
                                            caption:"数据预处理统计表",
                                            height:"100%",
                                            width:"100%",
            })
     })
</script>   

</head>
<body>

<!---------------------------------------- Menu bar ------------------------------------------>
<div class="noprint">
    <div class="menu">
        <ul class="main_menu">
            <li onmouseover="displaySubMenu(this)" onmouseout="hideSubMenu(this)"><a href="#1 概述">概述</a></li>
            <li><a href="#2 项目流程">项目流程</a>
                <ul id="menu_list">
                    <li><a href="#2.1 建库测序流程">建库测序流程</a></li>
                    <li><a href="#2.2 信息分析流程">信息分析流程</a></li>
                </ul>
            </li>
            <li onmouseover="displaySubMenu(this)" onmouseout="hideSubMenu(this)"><a href="#3 分析结果">分析结果</a>
                <ul id="menu_list">
                    <li><a href="#3.1 测序数据预处理">测序数据预处理</a></li>
                    <li><a href="#3.2 Metagenome 组装">Metagenome 组装</a></li>
                    
                    <li><a href="#3.3 基因预测及丰度分析">基因预测及丰度分析</a>
                    </li>
                    <li><a href="#3.4 物种注释">物种注释</a>
                    </li>
                    <li><a href="#3.5 常用功能数据库注释">常用功能数据库注释</a>
                    </li>
                    <li><a href="#3.6 抗性基因注释">抗性基因注释</a>
                    </li>
                </ul>
            </li>
            <li><a href="#4 参考文献">参考文献</a></li>
            <li onmouseover="displaySubMenu(this)" onmouseout="hideSubMenu(this)"><a href="#5 附录">附录</a>
                <ul id="menu_list">
                    <li><a href="./src/images/Sequencing_Methods.pdf" title="点击打开" target="_blank">方法描述/Methods</a></li>
                    <li><a href="./src/images/information_analysis.pdf" title="点击打开" target="_blank">信息分析方法描述(中文版)</a></li>
                    <li><a href="./src/images/information_analysis_en.pdf" title="点击打开" target="_blank">信息分析方法描述(英文版)</a></li>
                    <li><a href="./src/images/ReadMe.html" title="点击打开" target="_blank">交付文件说明</a></li>
                    <li><a href="./src/images/novo_format.pdf" title="点击打开" target="_blank">常见数据格式</a></li>
                    <li><a href="./src/images/MetaV5.0_FAQ.pdf" title="点击打开" target="_balnk">售后 FAQ</a></li>
					<li><a href="#5.4 相关软件及链接">软件使用说明</a></li>
                    <li><a href="#5.5 备注">备注</a></li>
                </ul>
            </li>
        </ul>
        <input type="button" class="close" title="显示/隐藏"></input>
    </div>
</div>
<!--menu over-->

<!---------------------------------------- 目录 ---------------------------------------------->
<div id="page">
    <p><a name="home"><img class="normal" src="src/images/logo.png" /></a><h1>诺禾致源 Metagenome 分析结题报告</h1></p>
    <p class="paragraph" align="left">项目编号：$id</p>
    <p class="paragraph" align="left">项目名称：$pro</p>
    <p class="paragraph" align="left">报告时间：$date</p>
    <p class="paragraph" align="left">报告编号：$report_id</p>
   
XHTML
;
my($catalog,$description,$literature)=&get_html;
print OUT "$catalog</div>\n$description";
my $print_literature=&get_literature(@{$literature});
print OUT <<"XHTML"
<!-------------------------------------------- 参考文献 ------------------------------------------->
<div id="page">
<p class="head"><a href="#home" title = "返回首页"><img class="logo" align="left" src="src/images/logo.png" /></a>
<a name="4 参考文献">北京诺禾致源科技股份有限公司</a>
<hr />
</p><br />
<h2>4 参考文献</h2>
<p class="ref">
    $print_literature
XHTML
;
print OUT << "XHTML"
</p>
</div>

<!-------------------------------------------- 附录 --------------------------------------------->
<p class="head"><a href="#home" title = "返回首页"><img class="logo" align="left" src="src/images/logo.png" /></a>
<a name="5 附录">北京诺禾致源科技股份有限公司</a>
<hr />
</p><br />
<h2>5 附录</h2>
<a name="5.1 方法描述/Methods"><h3>5.1　方法描述/Methods</h3></a>
<p class="paragraph">方法描述/Methods：<a href="./src/images/Sequencing_Methods.pdf" title="点击打开" target="_blank">PDF</a></p>
<p class="paragraph">信息分析方法描述(中文版)：<a href="./src/images/information_analysis.pdf" title="点击打开" target="_blank">PDF</a></p>
<p class="paragraph">信息分析方法描述(英文版)：<a href="./src/images/information_analysis_en.pdf" title="点击打开" target="_blank">PDF</a></p>
<a name="5.2 交付文件目录列表"><h3>5.2　交付文件目录列表</h3></a>
XHTML
;

print OUT << "XHTML"
<p class="paragraph">交付文件说明：<a href="./src/images/ReadMe.html" title="点击打开" target="_blank">HTML</a></p>
XHTML
; 

print OUT << "XHTML"
<a name="5.3 常见数据格式说明"><h3>5.3　常见数据格式说明</h3></a>
<p class="paragraph">常见数据格式说明：<a href="./src/images/novo_format.pdf" title="点击打开" target="_blank">PDF</a></p>
<a name="5.4 售后 FAQ"><h3>5.4  售后 FAQ</h3></a>
<p class="paragraph">FAQ：<a href="./src/images/MetaV5.0_FAQ.pdf" title="点击打开" target="_blank">PDF</a></p>
<a name="5.5 相关软件及链接"><h3>5.5　相关软件及链接</h3></a>
XHTML
;
if($opt{type}=~/megahit/) ###change by zhanghao 20171218
{print OUT << "XHTML"
<p class="paragraph">MEGAHIT(v1.0.4): <a href="https://github.com/voutcn/megahit" target="_blank" >https://github.com/voutcn/megahit </a></p>
XHTML
;
}
elsif($opt{type}=~/soapdenovo/)
{ print OUT << "XHTML"
    <p class="paragraph">SOAP denovo(Version 2.21)：<a href="http://soap.genomics.org.cn/soapdenovo.html" target="_blank" >http://soap.genomics.org.cn/soapdenovo.html</a></p>
XHTML
;
}
print OUT << "XHTML"
<p class="paragraph">Bowtie2( Version: 2.2.4 ): <a href="http://bowtie-bio.sourceforge.net/bowtie2/index.shtml" target="_blank" >http://bowtie-bio.sourceforge.net/bowtie2/index.shtml</a></p>
<p class="paragraph">MetaGeneMark（Version: 2.10）:<a href="http://exon.gatech.edu/GeneMark/metagenome/Prediction" target="_blank" >http://exon.gatech.edu/GeneMark/metagenome/Prediction</a></p>
<p class="paragraph">CD-HIT（Version: 4.5.8): <a href="http://www.bioinformatics.org/cd-hit/" target="_blank" >http://www.bioinformatics.org/cd-hit/</a></p>

<a name="5.5 备注"><h3>5.5　备注</h3></a>
<p class="paragraph">结果文件建议使用Excel或者EditPlus等专业文本编辑器打开。</p>
<p class="paragraph">推荐使用火狐浏览器进行网页版结题报告浏览，下载地址：<a href="http://www.firefox.com.cn/download/" target="_blank" >http://www.firefox.com.cn/download/</a></p>
<p class="paragraph">点击Novogene图标或者右下角按钮可以返回首页。</p>
<!----------------------------------------------- End -------------------------------------------->
</body>
</html>
XHTML
;
close OUT;

my $index_html="$report/report.html";
&get_index($report,$opt{stat},$index_html,"$resultdir/..");
(-s "$outdir/$report") ? `tar -hcvf $outdir/$report.tar.gz $report;` : `tar -hcvf report.tar.gz report`;

###add assbembly_data record by zhangjing 2017-06-08
my $assbembly_data_record="$Bin/assembly_data.pl";
`perl $assbembly_data_record --indir $outdir --Rinfo $opt{info}`;  

sub get_description{
    my($des,)=@_;
    my $get_description=join("</p>\n<p class=\"paragraph\">",(split/\n/,$des));
    $get_description = "<p class=\"paragraph\">$get_description</p>";
    return$get_description;
}

sub get_html{
    my $mulu='1 概述
    2 项目流程
    2.1 建库测序流程
    2.2 信息分析流程
    3 分析结果
    3.1 测序数据预处理
    3.2 Metagenome 组装
    3.3 基因预测及丰度分析
    3.3.1 基因预测及丰度分析基本步骤
    3.3.2 gene catalogue 基本信息统计
    ';
    my %return_hash=(
    '概述','1',
    '项目流程','2',
    '建库测序流程','2.1',
    '信息分析流程','2.2',
    '分析结果','3',
    '测序数据预处理','3.1',
    'Metagenome 组装','3.2',
    '基因预测及丰度分析','3.3',
    '基因预测及丰度分析基本步骤','3.3.1',
    'gene catalogue 基本信息统计','3.3.2',
    '物种注释','3.4',
    '物种注释基本步骤','3.4.1',
    '物种相对丰度概况','3.4.2',
    '常用功能数据库注释','3.5',
    '功能注释基本步骤','3.5.1',
    '注释基因数目统计','3.5.2',
    '功能相对丰度概况','3.5.3',
    '参考文献','4',
    '附录','5',
    '方法描述/Methods','5.1',
    '交付文件目录列表','5.2',
    '常见数据格式说明','5.3',	
    '售后 FAQ','5.4',
	'相关软件及链接','5.5',
    '备注','5.6',
    );
    my($a,$b,$c)=(3,3,2); 
#    if (!$opt{s2}){
    if((-s "$resultdir/03.GenePredict/GeneStat/core_pan/pan.gene.png" && -s "$resultdir/03.GenePredict/GeneStat/core_pan/core.gene.png") || -s  "$resultdir/03.GenePredict/GeneStat/core_pan/core.flower.png"){
        $mulu .= "$a.$b.".++$c." core-pan 基因分析\n";
        $return_hash{'core-pan 基因分析'}="$a.$b.$c";
    }
	if (!$opt{s2}){
    if (-s "$report/src/pictures/03.GeneComp/group.genebox.png" || -s "$report/src/pictures/03.GeneComp/venn_flower_display.png" ){
         $mulu .= "$a.$b.".++$c." 基因数目差异分析\n";
         $return_hash{'基因数目差异分析'}="$a.$b.$c";
    }
    #if( -s "$report/src/pictures/03.GeneComp/venn_flower_display.png"){
    #    $mulu .= "$a.$b.".++$c." 基因数目韦恩图（花瓣图）分析\n";
    #    $return_hash{'基因数目韦恩图（花瓣图）分析'}="$a.$b.$c";
    #}
    if (-s "$report/src/pictures/03.GeneComp/correlation.heatmap.png"){
        $mulu .= "$a.$b.".++$c." 基于基因数目的样品间相关性分析\n";
        $return_hash{'基于基因数目的样品间相关性分析'}="$a.$b.$c";
    };
    }
    $mulu .=
    '3.4 物种注释
    3.4.1 物种注释基本步骤
    3.4.2 物种相对丰度概况
    ';
    ($a,$b,$c)=(3,4,2); 
    if (!$opt{s2}){
        $mulu .= "$a.$b.".++$c." 注释基因数目及相对丰度聚类分析\n";
        $return_hash{'注释基因数目及相对丰度聚类分析'}="$a.$b.$c";
        $mulu .= "$a.$b.".++$c." 基于物种丰度的降维分析\n" ;
        $return_hash{'基于物种丰度的降维分析'}="$a.$b.$c";
        $mulu .= "$a.$b.".++$c." 基于物种丰度的Bray-Curtis 距离的降维分析\n" ;
        $return_hash{'基于物种丰度的Bray-Curtis 距离的降维分析'}="$a.$b.$c";  
    }
	if(-s "$report/src/pictures/04.Taxonomy/anosim.png"){
	    $mulu .= "$a.$b.".++$c." 基于物种丰度的Anosim分析\n" ;
        $return_hash{'基于物种丰度的Anosim分析'}="$a.$b.$c"; 
	}
	if (!$opt{s2}){
	    $mulu .= "$a.$b.".++$c." 基于物种丰度的样品聚类分析\n";
        $return_hash{'基于物种丰度的样品聚类分析'}="$a.$b.$c";
	}
    if ($opt{vs} && -s "$report/src/pictures/04.Taxonomy/top.12.png"){
        $mulu .= "$a.$b.".++$c." 组间差异物种的Metastat分析\n";
        $return_hash{'组间差异物种的Metastat分析'}="$a.$b.$c";
    }
	if ($opt{lefse} && -s "$report/src/pictures/04.Taxonomy/LDA.png"){
        $mulu .= "$a.$b.".++$c." 组间差异物种的LEfSe分析\n";
        $return_hash{'组间差异物种的LEfSe分析'}="$a.$b.$c";
    }
	if ($opt{rf} && -s "$report/src/pictures/04.Taxonomy/tax_show_group_max_roc.png"){
        $mulu .= "$a.$b.".++$c." 基于物种丰度的RandomForest分析\n";
        $return_hash{'基于物种丰度的RandomForest分析'}="$a.$b.$c";
    }
    $mulu .= 
    '3.5 常用功能数据库注释
    3.5.1 功能注释基本步骤
    3.5.2 注释基因数目分析
    3.5.3 功能相对丰度概况
    ';
    ($a,$b,$c)=(3,5,3); 
    if (!$opt{s2}){
        $mulu .= "$a.$b.".++$c." 功能相对丰度聚类分析\n" ;
        $return_hash{'功能相对丰度聚类分析'}="$a.$b.$c";
        $mulu .= "$a.$b.".++$c." 基于功能丰度的降维分析\n" ;
        $return_hash{'基于功能丰度的降维分析'}="$a.$b.$c";
        $mulu .= "$a.$b.".++$c." 基于功能丰度的Bray-Curtis 距离的降维分析\n" ;
        $return_hash{'基于功能丰度的Bray-Curtis 距离的降维分析'}="$a.$b.$c";
    }
	if(-s "$report/src/pictures/05.FunctionAnnotation/KEGG_anosim.png"){
	    $mulu .= "$a.$b.".++$c." 基于功能丰度的Anosim分析\n" ;
        $return_hash{'基于功能丰度的Anosim分析'}="$a.$b.$c";
	}
	if (!$opt{s2}){
	    $mulu .= "$a.$b.".++$c." 基于功能丰度的样品聚类分析\n" ;
        $return_hash{'基于功能丰度的样品聚类分析'}="$a.$b.$c";
	}
    if( $opt{ipath} && -s "$resultdir/05.FunctionAnnotation/KEGG/pathwaymaps.report/"){
        $mulu .= "$a.$b.".++$c." 代谢通路比较分析\n";
        $return_hash{'代谢通路比较分析'}="$a.$b.$c";
        `mkdir -p $report/src/pictures/05.FunctionAnnotation/pathwaymaps/`;
        `cp -f $resultdir/05.FunctionAnnotation/KEGG/pathwaymaps/KEGG_ReadMe.pdf  $report/src/pictures/05.FunctionAnnotation/pathwaymaps/`;
        `cp -rf $resultdir/05.FunctionAnnotation/KEGG/pathwaymaps.report/* $report/src/pictures/05.FunctionAnnotation/pathwaymaps/`;
    }    
    if($opt{vs} && $show{fun_box}){
        $mulu .= "$a.$b.".++$c." 组间功能差异的Metastat分析\n" ;
        $return_hash{'组间功能差异的Metastat分析'}="$a.$b.$c";
    }
	if($opt{lefse} && $show{fun_lda}){
        $mulu .= "$a.$b.".++$c." 组间功能差异的LEfSe分析\n" ;
        $return_hash{'组间功能差异的LEfSe分析'}="$a.$b.$c";
    }
	if($opt{rf} && $show{fun_show_rf_roc}){
        $mulu .= "$a.$b.".++$c." 基于功能丰度的RandomForest分析\n" ;
        $return_hash{'基于功能丰度的RandomForest分析'}="$a.$b.$c";
    }   
#if (!$opt{s2}){
	    $mulu .= 
        '3.6 抗性基因注释
        3.6.1 抗性基因注释基本步骤
        3.6.2 抗性基因丰度概况
        ';
		$return_hash{'抗性基因注释'}='3.6';
		$return_hash{'抗性基因注释基本步骤'}='3.6.1';
		$return_hash{'抗性基因丰度概况'}='3.6.2';
		($a,$b,$c)=(3,6,2);
		#if(-s "$report/src/pictures/05.FunctionAnnotation/circos.png"){
		#   $mulu .= "$a.$b.".++$c." 各样品中抗性基因类型分布比例概览\n";
		#	$return_hash{'各样品中抗性基因类型分布比例概览'}="$a.$b.$c";
		#}
		if(-s "$report/src/pictures/05.FunctionAnnotation/arg_heatmap.png"){
		    $mulu .= "$a.$b.".++$c." 抗性基因类型的分布及其丰度聚类分析\n";
            $return_hash{'抗性基因类型的分布及其丰度聚类分析'}="$a.$b.$c"; 
		}
        if(-s "$report/src/pictures/05.FunctionAnnotation/aro_heatmap.png"){
            $mulu .= "$a.$b.".++$c." 抗性基因类型的分布及其丰度聚类分析\n";
            $return_hash{'抗性基因类型的分布及其丰度聚类分析'}="$a.$b.$c";
        }
		if(-s "$report/src/pictures/05.FunctionAnnotation/card_anosim_show.png"){
			$mulu .= "$a.$b.".++$c." 基于抗性基因丰度的Anosim分析\n";
			$return_hash{'基于抗性基因丰度的Anosim分析'}="$a.$b.$c";	
		}
		if(-s "$report/src/pictures/05.FunctionAnnotation/ardb_box.png"){
		    $mulu .= "$a.$b.".++$c." 组间抗性基因数目差异分析\n";
			$return_hash{'组间抗性基因数目差异分析'}="$a.$b.$c";
		}
        if(-s "$report/src/pictures/05.FunctionAnnotation/card_box.png"){
            $mulu .= "$a.$b.".++$c." 组间抗性基因数目差异分析\n";
            $return_hash{'组间抗性基因数目差异分析'}="$a.$b.$c";
        }
		if(-s "$report/src/pictures/05.FunctionAnnotation/card_metastat_show.png"){
			$mulu .= "$a.$b.".++$c." 组间差异抗性基因的Metastat分析\n";
			$return_hash{'组间差异抗性基因的Metastat分析'}="$a.$b.$c";
		}
		if(-s "$report/src/pictures/05.FunctionAnnotation/card_lda_bar.png"){
			$mulu .= "$a.$b.".++$c." 组间差异抗性基因的Lefse分析\n";
			$return_hash{'组间差异抗性基因的Lefse分析'}="$a.$b.$c";
		}
		if($arg_taxonomy_pics || -s "$report/src/pictures/05.FunctionAnnotation/mechanism.png" ){
		    $mulu .= "$a.$b.".++$c." 抗性基因与物种归属关系\n";
			$return_hash{'抗性基因与物种归属关系'}="$a.$b.$c"; 
		}
		#if(-s "$report/src/pictures/05.FunctionAnnotation/mechanism.png"){
		#    $mulu .= "$a.$b.".++$c." 抗性机制分析\n";
	    #		$return_hash{'抗性机制分析'}="$a.$b.$c"; 
		#}
#	}
    $mulu .=
    '4 参考文献
    5 附录
    5.1 方法描述/Methods
    5.2 交付文件目录列表	
    5.3 常见数据格式说明	
    5.4 售后 FAQ
    5.5 相关软件及链接
    5.6 备注
    ';
    my $return='<p class="paragraph">
        <dl>'."\n";
    my@catalog=split/\n+/,$mulu;
    my $flag=0;
    my $flag2=0;
    foreach $catalog(@catalog){
        $catalog=~s/^\s+//;
        if ($catalog=~/^\d+ /) {
            $return .= "</dt>\n" if ($flag==1);
            $return .= "</dl></dt>\n"  if $flag2==1 && $flag==0;
            $return .= "<dt><a href=\"#$catalog\" target=\"_blank\"  >$catalog</a>\n";
            $flag=1;
        }elsif($catalog=~/^\d+\.\d+ /){
            $return .= "<dl class=\"alt\">\n" if $flag==1;
            $return .= "<dd><a href=\"#$catalog\" target=\"_blank\" >$catalog</a></dd>\n";
            $flag=0;
            $flag2=1;
        }elsif($catalog=~/^\d+\.\d+\.\d+ /){
            $return .= "<dl class=\"alt\">\n" if $flag==1;
            $return .= "<dd><a href=\"#$catalog\" target=\"_blank\" >&nbsp;&nbsp;&nbsp;&nbsp;$catalog</a></dd>\n";
            $flag=0;
            $flag2=1;
        }
    }
    $return .= "</dl></dt><br /><br /></p>\n" ;
    my $description=\%return_hash;
    my $core_pan;
    if (-s "$resultdir/03.GenePredict/GeneStat/core_pan/pan.gene.png" && -s "$resultdir/03.GenePredict/GeneStat/core_pan/core.gene.png"){
    `$combine -wn 2 $resultdir/03.GenePredict/GeneStat/core_pan/core.gene.png $resultdir/03.GenePredict/GeneStat/core_pan/pan.gene.png -ftext 'a,b' > $report/src/pictures/03.GeneComp/combine.gene.svg`;
    `$convert  $report/src/pictures/03.GeneComp/combine.gene.svg $report/src/pictures/03.GeneComp/`;
    $core_pan='<p class="paragraph">从基因在各样品中的丰度表出发，可以获得各样品的基因数目信息，通过随机抽取不同数目的样品，可以获得不同数目样品组合间的基因数目，由此我们构建和绘制了 Core 和 Pan 基因的稀释曲线，图片展示如下：</p>
    <p class="center">
    <a href="src/pictures/03.GeneComp/combine.gene.png" target="_blank" ><img  src="src/pictures/03.GeneComp/combine.gene.png" width="70%" height="70%"/></a>
    </p>
    <p class="name">图 3-3-3 core-pan 基因稀释曲线</p>
    <p class="premark">说明：a) Core基因稀释曲线；b) Pan基因稀释曲线。横坐标表示抽取的样品个数；纵坐标表示抽取的样品组合的基因数目。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">core-pan 基因稀释曲线图见：result/03.GenePredict/GeneStat/core_pan/*.{png,pdf}。</p>';
    }elsif(-s "$resultdir/03.GenePredict/GeneStat/core_pan/core.flower.png"){
    `cp -f $resultdir/03.GenePredict/GeneStat/core_pan/core.flower.png $report/src/pictures/03.GeneComp/`;
    $core_pan='<p class="paragreph">从基因在各样品中的丰度表出发，可以获得各样品的基因数目信息，由此绘制了基因数目花瓣图，展示结果如下：<p>
    <p class="center">
    <a href="src/pictures/03.GeneComp/core.flower.png" target="_blank" ><img  src="src/pictures/03.GeneComp/core.flower.png" width="30%" height="30%"/></a>
    </p>
    <p class="name">图 3-3-3 基因数目花瓣图及基因数目箱图</p>
    <p class="premark">说明：中间圆圈表示所有样品共有的基因数目；不同花瓣表示不同的样品，其中的数值表示样品的基因数目与共有基因数目的差值；括号中数值表示样品的含有基因数目和特有的基因数目；</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">基因数目韦恩图（花瓣图）分析：result/03.GenePredict/GeneStat/core_pan/*.{png,pdf}。</p>';
    }

    #get decription for html
    my $i=1;
    my $j=0;
    my (@liter,@part_ori);
    if ($opt{type} eq 'soapdenovo') {
        push @liter,(1..4,6,13,31,7,28,27,29,30,8,10,32,33,34,35,36,18,11,12,37,38,39,40,45,15,16);
        @part_ori=(28,13,31,13,31,28,10,13,31,8,35,28,10,32,33,34,34,33,35,28,35,32,31,33,36,32,13,31,35,27,35,27,35,37,13,31,35);
    }elsif($opt{type} eq 'IDBA_UD'){
        push @liter,(1..4,6,8,10,13,31,32,33,34,35,36,18,11,12,37,38,39,40,45,15,16);
        @part_ori=(10,8,13,31,35,28,10,32,33,34,34,33,35,28,35,32,31,33,36,32,13,31,35,27,35,27,35,37,13,31,35);
    }elsif($opt{type} eq 'megahit'){
        push @liter,(1..4,6,13,31,8,10,32,,33,34,35,36,18,28,11,12,37,38,39,40,45,15,16); ##8,28,10
        @part_ori=(13,31,13,31,10,13,31,8,35,10,32,33,34,34,33,35,28,35,32,31,33,36,32,13,31,35,27,35,27,35,37,13,31,35);
    }else{die "set type for soapdenovo or IDBA_UD!\n";}
    my @part=&get_part(\@part_ori,\@liter);
    my $mulu2description=
    '<!-------------------------------------------- 概述 --------------------------------------------->'.
    '<div id="page">
        <p class="head"><a href="#home" title = "返回首页"><img class="logo" align="left" src="src/images/logo.png" /></a>
        <a name="1 概述">北京诺禾致源科技股份有限公司</a>
        <hr />
        </p><br />
        <h2>1 概述</h2>'.
    '<p class="paragraph">微生物群体几乎存在于这个世界每一个生态群落之中，从个体体表到肠道，从高原空气到深海海底淤泥，从冰川冻湖到火山岩浆都无处不在，并扮演着不可或缺的角色。对微生物的研究从 Antoni van Leeuwenhoek 发明显微镜开始的数百年中，主要基于纯培养的研究方式。在数以万亿计的微生物种类中，仅 0.1%~1% 的物种可培养，极大地限制了对微生物多样性资源的研究和开发。</p>
    <p class="paragraph">Metagenomics(翻译成元基因组学，或者翻译成宏基因组学)，是由 Handelman<SUP>['.$i++.']</SUP> 最先提出的一种直接对微生物群体中包含的全部基因组信息进行研究的手段。之后， Kevin<SUP>['.$i++.']</SUP> 等对 Metagenomics 进行了定义，即“绕过对微生物个体进行分离培养，应用基因组学技术对自然环境中的微生物群落进行研究”的学科。它规避了对样品中的微生物进行分离培养，提供了一种对不可分离培养的微生物进行研究的途径，更真实的反应样本中微生物组成、互作情况，同时在分子水平对其代谢通路、基因功能进行研究<SUP>['.$i++.']</SUP>。</p>
    <p class="paragraph">近年来，随着测序技术和信息技术的快速发展，利用新一代测序技术(Next Generation Sequencing)研究 Metagenomics，能快速准确的得到大量生物数据和丰富的微生物研究信息，从而成为研究微生物多样性和群落特征的重要手段<SUP>['.$i++.','.$i++.']</SUP>。如致力于研究微生物与人类疾病健康关系的人体微生物组计划(HMP, Human Microbiome Project, <a href="http://www.hmpdacc.org/" target="_blank" >http://www.hmpdacc.org/</a> )，研究全球微生物组成和分布的全球微生物组计划(EMP, Earth Microbiome Project, <a href="http://www.earthmicrobiome.org/" target="_blank" >http://www.earthmicrobiome.org/</a> )都主要利用高通量测序技术进行研究。</p></br></br>'.

    '<!-------------------------------------------- 建库测序流程 --------------------------------------------->'.
    '<div id="page">
        <p class="head"><a href="#home" title = "返回首页"><img class="logo" align="left" src="src/images/logo.png" /></a>
        <a name="2 项目流程">北京诺禾致源科技股份有限公司</a>
        <hr />
        </p><br />
        <h2>2 项目流程</h2>'.
    '<a name="2.1 建库测序流程"></a><h3>2.1 建库测序流程</h3>'.
    '<p class="paragraph">从环境（如土壤、海洋、淡水、肠道等）中采集实验样本，将原始采样样本或已提取的 DNA 样本低温运输（ 0℃ 以下）送往我公司。我公司将对接收到的样品进行样品检测。</p>
    <p class="paragraph">检测合格的 DNA 样品，进行文库构建以及文库检测，检测合格的文库将采用 Illumina PE150 进行测序，测序得到的下机数据(Raw Data)将用于后期信息分析。为了从源头上保证测序数据的准确性、可靠性，诺禾致源对样品检测、建库、测序每一个生产步骤都严格把控，从根本上确保高质量数据的产出，具体的实验流程图如下：</p>
        <p class="center">
        <img  src="src/images/pipeline.png" width="70%" height="70%"/>
        </p>
        <p class="name">图 2.1 Metagenomics 实验流程图</p>
        <a name="2.1.1 DNA样品检测"></a><h4>2.1.1 DNA样品检测</h4>
        <p class="paragraph">诺禾致源对 DNA 样品的检测主要包括 2 种方法：</p>
        <p class="paragraph">&nbsp;&nbsp;&nbsp;&nbsp;(1) 琼脂糖凝胶电泳（AGE）分析 DNA 的纯度和完整性；</p>
        <p class="paragraph">&nbsp;&nbsp;&nbsp;&nbsp;(2) Qubit 对 DNA 浓度进行精确定量；</p>
        <a name="2.1.2 文库构建及库检"></a><h4>2.1.2 文库构建及库检</h4>
    <p class="paragraph">检测合格的 DNA 样品用 Covaris 超声波破碎仪随机打断成长度约为 350bp 的片段，经末端修复、加 A尾、加测序接头、纯化、PCR 扩增等步骤完成整个文库制备。</p>
    <p class="paragraph">文库构建完成后，先使用 Qubit2.0 进行初步定量，稀释文库至 2ng/ul，随后使用 Agilent 2100 对文库的 insert size 进行检测，insert size 符合预期后，使用 Q-PCR 方法对文库的有效浓度进行准确定量（文库有效浓度 ＞3nM），以保证文库质量。</p>
    <a name="2.1.3 上机测序"></a><h4>2.1.3 上机测序</h4>
    <p class="paragraph">库检合格后，把不同文库按照有效浓度及目标下机数据量的需求 pooling 后进行 Illumina PE150 测序。</p>'.

    '<!-------------------------------------------- 信息分析流程 --------------------------------------------->'.
    '<a name="2.2 信息分析流程"></a><h3>2.2 信息分析流程</h3>'.
    '<p class="tremark">a) 数据质控：测序得到的原始数据(Raw Data)会存在一定比例的低质量数据，为了保证后续信息分析结果的准确可靠，首先要对原始数据进行质控及宿主过滤，得到有效数据(Clean Data)；</br>
    b) Metagenome 组装：从各样品质控后的 Clean Data 出发，进行 Metagenome 组装，并将各样品未被利用上的 reads 放在一起进行混合组装，以期发现样品中的低丰度物种信息；</br>
    c) 基因预测：从单样品和混合组装后的 scaftigs 出发，采用 MetaGeneMark 进行基因预测，并将各样品和混合组装预测产生的基因放在一起，进行去冗余，构建 gene catalogue，从 gene catalogue 出发，综合各样品的 Clean Data，可获得 gene catalogue 在各样品中的丰度信息；</br>
    d) 物种注释：从 gene catalogue 出发，和 MicroNR 库进行比对，获得每个基因（Unigene）的物种注释信息，并结合基因丰度表，获得不同分类层级的物种丰度表；</br>
    e) 常用功能数据库注释：从 gene catalogue 出发，进行代谢通路(KEGG)，同源基因簇(eggNOG)，碳水化合物酶(CAZy)的功能注释和丰度分析；</br>	
    f) 基于物种丰度表和功能丰度表，可以进行丰度聚类分析，PCA和NMDS 降维分析，Anosim分析，样品聚类分析；当有分组信息时，可以进行Metastat和LEfSe多元统计分析以及代谢通路比较分析，挖掘样品之间的物种组成和功能组成差异；</br>
	g) 抗性基因注释：利用gene catalogue与抗生素抗性基因数据库CARD（The Comprehensive Antibiotic Resistance Database）进行注释，可以获得抗性基因丰度分布情况以及这些抗性基因的物种归属和抗性机制；</br>
	h) 另外，还可以基于标准分析结果，进行一系列高级信息分析（如 CCA/RDA 分析，肠型分析，拷贝数变异（CNV）分析，CAG/MLG分析，病原与宿主互作数据库(PHI)注释，分泌蛋白预测，III型分泌系统效应蛋白预测，细菌致病菌毒力因子(VFDB)注释，转移元件分析（MGE）等，更多详细信息请查看<a href="src/images/Advanced_Analysis.pdf" target="_blank" >诺禾致源宏基因组高级信息分析说明</a>）；同时，结合环境因子、病理指标或特殊表型进行深入关联研究，能够为进一步深入研究和利用样品的物种和功能提供理论依据。</p></br>
    <p class="paragraph"><font color="red">备注：</br> 
    &nbsp;&nbsp;&nbsp;&nbsp;(1) 当样品数目小于3个时，无法进行 PCA，NMDS，CCA/RDA，聚类分析，丰度聚类热图分析；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;(2) 当分组内的生物学重复数目小于3个时，诸如 Anosim，Metastat，LEfSe 等统计分析皆没有统计学意义，将不进行此类分析。</font></p></br>
    <p class="center">
        <img  src="src/images/pipeline_4.0.jpg" width="40%" height="25%"/>
        </p>
        <p class="name">图 2.2 Metagenomics 信息分析流程图</p>
        </br></br>'.

    '<!-------------------------------------------- 分析结果 --------------------------------------------->'.
    '<div id="page">
        <p class="head"><a href="#home" title = "返回首页"><img class="logo" align="left" src="src/images/logo.png" /></a>
        <a name="分析结果">北京诺禾致源科技股份有限公司</a>
        <hr />
        </p><br />
        <a name="3 分析结果"></a><h2>3 分析结果</h2>'.

    '<!-------------------------------------------- 数据预处理 --------------------------------------------->'.
    '<a name="3.1 测序数据预处理"></a><a href="src/images/01.CleanData--readme.pdf" title="点击查看交付目录说明文档"  data-toggle="tooltip" target="_blank" > <h3>3.1 测序数据预处理&nbsp;>></h3></a>'.
    '<p class="paragraph">采用 Illumina HiSeq 测序平台测序获得的原始数据(Raw Data)存在一定比例低质量数据，为了保证后续分析的结果准确可靠，需要对原始的测序数据进行预处理，获取用于后续分析的有效数据(Clean Data)。具体处理步骤如下：</p>
    <p class="tremark">1)&nbsp;去除所含低质量碱基（质量值≤38）超过一定比例（默认设为 40bp）的 reads； </br>
    2)&nbsp;去除 N 碱基达到一定比例的 reads（默认设为10bp）； </br>
    3)&nbsp;去除与 Adapter 之间 overlap 超过一定阈值（默认设为 15bp）的 reads；</br>
    4)&nbsp;如果样品存在宿主污染，需与宿主数据库进行比对，过滤掉可能来源于宿主<SUP>['.$i++.','.$i++.']</SUP>（默认采用 Bowtie2 软件，参数设置: --end-to-end, --sensitive, -I 200, -X 400）的 reads；</br></p>
    <p class="paragraph">上述的处理步骤均是对 Read 1 和 Read 2 进行操作。测序数据预处理统计结果见表 3-1，更多详细信息请点击 <a href="src/QC_raw_report/index.html" target="_blank" >QC_Report</a>。</p>
    <p class="name">表 3.1 数据预处理统计表</p>
        <div style="text-align:center;">
            <table id="table_clean_Data"></table>
            <div id="page_clean_Data"></div>
        </div></br>
        <p class="premark">说明：#Sample 表示样品名称；InsertSize(bp)表示使用 350bp 文库；RawData 表示下机原始数据；CleanData 表示过滤得到的有效数据；Clean_Q20，Clean_Q30 表示 CleanData 中测序错误率小于0.01(质量值大于 20)和 0.001(质量值大于 30)的碱基数目的百分比；Clean_GC(%) 表示 CleanData 中碱基的 GC 含量；Effective(%) 表示有效数据( CleanData )与原始数据( RawData )的百分比。</p></br>
        <p class="paragraph">结果目录:</p>
        <p class="paragraph">质控后的FASTQ序列见：result/01.CleanData/Sample_Name/ *_350.fq1(2).gz；</p>
        <p class="paragraph">当存在宿主基因组，去完宿主后的序列见：result/01.CleanData/Sample_Name/ *_350 .nohost.fq1(2).gz；</p>
        <p class="paragraph">各样品QC结果详细信息见：result/01.CleanData/ total.QCstat.info.xls；</p>
        <p class="paragraph">去除宿主后的QC结果的详细信息见：result/01.CleanData/total.*.NonHostQCstat.info.xls；</p>
        <p class="paragraph">QC报告见：result/01.CleanData/QC_raw_report/。</p>';
    
	#For Assembly
	$mulu2description.=
    '<!-------------------------------------------- 组装 --------------------------------------------->'.
    '<a name="3.2 Metagenome 组装"></a><a href="src/images/02.Assembly--readme.pdf" target="_blank"  title="点击查看交付目录说明文档"  data-toggle="tooltip"><h3>3.2 Metagenome 组装&nbsp;>></h3></a>'.
    '<p class="tremark">1）经过预处理后得到 Clean Data，使用 SOAP denovo<SUP>['.$i++.']</SUP> 组装软件进行组装分析( Assembly Analysis )；</br>
    2）对于单个样品，组装时选取 K-mer=55进行组装，得到该样品的组装结果；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;组装参数<SUP>['.$i++.','.$i++.','.$i++.','.$i++.']</SUP>：-d 1, -M 3, -R, -u, -F </br>
    3）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs<SUP>['.$part[$j++].','.$i++.','.$i++.']</SUP> (i.e., continuous sequences within scaffolds)；</br>
    4）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;比对参数<SUP>['.$part[$j++].','.$part[$j++].']</SUP> ：--end-to-end, --sensitive, -I 200, -X 400</br>
    5）将各样品未被利用上的 reads 放在一起，选取 K-mer=55进行混合组装<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$i++.']</SUP>，其他组装参数与单样品组装参数相同；</br>
    6）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；</br>
    7）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp<SUP>['.$part[$j++].','.$part[$j++].','.$i++.','.$i++.','.$i++.']</SUP> 以下的片段，并进行统计分析和后续基因预测；</br></p>
    <p class="name">表 3.2 各样品组装结果 Scaftigs 基本信息统计（>=500bp）</p>
        <div style="text-align:center;">
            <table id="table_assembly"></table>
            <div id="page_assembly"></div>
        </div>
        </br>
        <p class="premark">说明：SampleID 表示样品名称（其中，NOVO_MIX 表示混合组装结果）；Total Len.（bp）表示组装得 Scaftigs 的总长；Num. 表示组装得到的 Scaftigs 总条数；Average Len.(bp) 表示 Scaftigs 的平均长度；N50，N90 表示将 Scaftigs 按照长度进行排序，然后由长到短加和，当加和值达到 Scaftigs 总长的 50%，90%时的 Scaftigs 的长度值；Max Len. 表示组装得到的最长 Scaftigs 的长度值。</p></br>
       
        <p class="paragraph">结果目录：</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaffold信息见：result/02.Assembly/total.scafSeq.stat.info.xls；</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaftigs信息见：result/02.Assembly/total.scaftigs.stat.info.xls；</p>
        <p class="paragraph">各样品对应的组装结果（NOVO_MIX为unmapped reads混合组装的结果）见：result/02.Assembly/Sample(NOVO_MIX)；</p>
        <p class="paragraph">Reads Mapping 结果见：result/02.Assembly/ReadsMapping。</p>
    <p class="paragraph">从组装结果出发，统计每个样品中 Scaftigs 长度的分布，并绘制成图，展示结果如下图所示：</p>'.$assembly_picts.'
    <p class="name">图 3.2 各样品的 Scaftigs 长度分布统计（>=500bp）</p>
    <p class="premark">说明：第一纵轴（Frequence(#)）表示 Scaftigs 数目；第二纵轴（Percentage（%））表示 Scaftigs 数目的百分比；横轴表示 Scaftigs 长度。</p></br>

    <p class="paragraph">结果目录：</p>
    <p class="paragraph">各样品中 Scaftigs 长度的分布图见：result/02.Assembly/Sample(NOVO_MIX)/*.{svg,png}；'if ($opt{type} eq 'soapdenovo');
$mulu2description.=
    '<!-------------------------------------------- 组装 --------------------------------------------->'.
    '<a name="3.2 Metagenome 组装"></a><h3>3.2 Metagenome 组装</h3>'.
    '<p class="tremark">1）经过预处理后得到 Clean Data，使用 IDBA_UD 组装软件进行组装分析( Assembly Analysis )；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;组装参数：--pre_correction </br>
    2）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs<SUP>['.$i++.','.$i++.']</SUP> (i.e., continuous sequences within scaffolds)；</br>
    3）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;比对参数 ：--end-to-end, --sensitive, -I 200, -X 400</br>
    4）将各样品未被利用上的 reads 放在一起，进行混合组装<SUP>['.$i++.','.$i++.','.$i++.']</SUP>，组装参数与单样品组装参数相同；</br>
    5）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；</br>
    6）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp<SUP>['.$part[$j++].','.$i++.','.$i++.','.$i++.']</SUP> 以下的片段，并进行统计分析和后续基因预测；</br></p>
    <p class="name">表 3.2 各样品组装结果 Scaftigs 基本信息统计（>=500bp）</p>
        <div style="text-align:center;">
            <table id="table_assembly"></table>
            <div id="page_assembly"></div>
        </div>
        </br>
        <p class="premark">说明：SampleID 表示样品名称（其中，NOVO_MIX 表示混合组装结果）；Total Len.（bp）表示组装得 Scaftigs 的总长；Num. 表示组装得到的 Scaftigs 总条数；Average Len.(bp) 表示 Scaftigs 的平均长度；N50，N90 表示将 Scaftigs 按照长度进行排序，然后由长到短加和，当加和值达到 Scaftigs 总长的 50%，90%时的 Scaftigs 的长度值；Max Len. 表示组装得到的最长 Scaftigs 的长度值。</p></br>
        <p class="paragraph">结果目录：</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaffold信息见：result/02.Assembly/total.scafSeq.stat.info.xls；</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaftigs信息见：result/02.Assembly/total.scaftigs.stat.info.xls；</p>
        <p class="paragraph">各样品对应的组装结果（NOVO_MIX为unmapped reads混合组装的结果）见：result/02.Assembly/Sample(NOVO_MIX)；</p>
        <p class="paragraph">Reads Mapping 结果见：result/02.Assembly/ReadsMapping。</p>

    <p class="paragraph">从组装结果出发，统计每个样品中 Scaftigs 长度的分布，并绘制成图，展示结果如下图所示：</p>'.$assembly_picts.'
    <p class="name">图 3.2 各样品的 Scaftigs 长度分布统计（>=500bp）</p>
    <p class="premark">说明：第一纵轴（Frequence(#)）表示 Scaftigs 数目；第二纵轴（Percentage（%））表示 Scaftigs 数目的百分比；横轴表示 Scaftigs 长度。</p></br>
    
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">各样品中 Scaftigs 长度的分布图见：result/02.Assembly/Sample(NOVO_MIX)/*.{svg,png}。' if ($opt{type} eq 'IDBA_UD');
$mulu2description.=
    '<!-------------------------------------------- 组装 --------------------------------------------->'.
    '<a name="3.2 Metagenome 组装"></a><a href="src/images/02.Assembly--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"><h3>3.2 Metagenome 组装&nbsp;>></h3></a>'.
    '<p class="tremark">1）经过预处理后得到 Clean Data，使用 MEGAHIT 组装软件进行组装分析( Assembly Analysis )；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;组装参数：--presets meta-large </br>
    2）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs<SUP>['.$i++.','.$i++.']</SUP> (i.e., continuous sequences within scaffolds)；</br>
    3）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;比对参数<SUP>['.$part[$j++].','.$part[$j++].']</SUP>  ：--end-to-end, --sensitive, -I 200, -X 400</br>
    4）将各样品未被利用上的 reads 放在一起，进行混合组装<SUP>['.$part[$j++].','.$part[$j++].','.$i++.']</SUP>，组装参数与单样品组装参数相同；</br>
    5）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；</br>
    6）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp<SUP>['.$part[$j++].','.$i++.','.$i++.','.$i++.']</SUP> 以下的片段，并进行统计分析和后续基因预测；</br></p>
    <p class="name">表 3.2 各样品组装结果 Scaftigs 基本信息统计（>=500bp）</p>
        <div style="text-align:center;">
            <table id="table_assembly"></table>
            <div id="page_assembly"></div>
        </div>
        </br>
        <p class="premark">说明：SampleID 表示样品名称（其中，NOVO_MIX 表示混合组装结果）；Total Len.（bp）表示组装得 Scaftigs 的总长；Num. 表示组装得到的 Scaftigs 总条数；Average Len.(bp) 表示 Scaftigs 的平均长度；N50，N90 表示将 Scaftigs 按照长度进行排序，然后由长到短加和，当加和值达到 Scaftigs 总长的 50%，90%时的 Scaftigs 的长度值；Max Len. 表示组装得到的最长 Scaftigs 的长度值。</p></br>

        <p class="paragraph">结果目录：</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaffold信息见：result/02.Assembly/total.scafSeq.stat.info.xls；</p>
        <p class="paragraph">按照长度500进行过滤后，所有样品的Scaftigs信息见：result/02.Assembly/total.scaftigs.stat.info.xls；</p>
        <p class="paragraph">各样品对应的组装结果（NOVO_MIX为unmapped reads混合组装的结果）见：result/02.Assembly/Sample(NOVO_MIX)；</p>
        <p class="paragraph">Reads Mapping 结果见：result/02.Assembly/ReadsMapping/。</p>
    <p class="paragraph">从组装结果出发，统计每个样品中 Scaftigs 长度的分布，并绘制成图，展示结果如下图所示：</p>'.$assembly_picts.'
    <p class="name">图 3.2 各样品的 Scaftigs 长度分布统计（>=500bp）</p>
    <p class="premark">说明：第一纵轴（Frequence(#)）表示 Scaftigs 数目；第二纵轴（Percentage（%））表示 Scaftigs 数目的百分比；横轴表示 Scaftigs 长度。</p></br>
    
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">各样品中 Scaftigs 长度的分布图见：result/02.Assembly/Sample(NOVO_MIX)/*.{svg,png}；' if ($opt{type} eq 'megahit');
	
	#For GenePredict
    $mulu2description .=
    '<!-------------------------------------------- 基因预测 --------------------------------------------->'.
    '<a name="3.3 基因预测及丰度分析"></a><a href="src/images/03.GenePredict--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3>3.3 基因预测及丰度分析&nbsp;>></h3> </a>'.
    '<a name="3.3.1 基因预测及丰度分析基本步骤"></a><h4>3.3.1 基因预测及丰度分析基本步骤</h4>'.
    '<p class="tremark">1）从各样品及混合组装的 Scaftigs（>=500bp）出发，采用 <a href="http://topaz.gatech.edu/GeneMark/" target="_blank" >MetaGeneMark</a><SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$part[$j++].','.$i++.','.$i++.']</SUP>  进行 ORF (Open Reading Frame) 预测，并从预测结果出发，过滤掉长度小于 100nt<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$part[$j++].','.$part[$j++].']</SUP> 的信息；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;预测参数：采用默认参数进行</br> ' if ($opt{type} eq 'soapdenovo');
    $mulu2description .=
    '<!-------------------------------------------- 基因预测 --------------------------------------------->'.
    '<a name="3.3 基因预测及丰度分析"></a><a href="src/images/03.GenePredict--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3>3.3 基因预测及丰度分析&nbsp;>></h3> </a>'.
    '<a name="3.3.1 基因预测及丰度分析基本步骤"></a><h4>3.3.1 基因预测及丰度分析基本步骤</h4>'.
    '<p class="tremark">1）从各样品及混合组装的 Scaftigs（>=500bp）出发，采用 <a href="http://topaz.gatech.edu/GeneMark/" target="_blank" >MetaGeneMark</a><SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$part[$j++].','.$i++.','.$i++.']</SUP>  进行 ORF (Open Reading Frame) 预测，并从预测结果出发，过滤掉长度小于 100nt<SUP>['.$i++.','.$part[$j++].','.$part[$j++].','.$part[$j++].','.$part[$j++].']</SUP> 的信息；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;预测参数：采用默认参数进行</br> ' if ($opt{type} eq 'megahit');   ###add by zhanghao 20180103,wenxian 
    $mulu2description.=
    '2）对各样品及混合组装的 ORF 预测结果，采用 <a href="http://www.bioinformatics.org/cd-hit/" target="_blank" >CD-HIT</a><SUP>['.$i++.','.$i++.']</SUP> 软件进行去冗余，以获得非冗余的初始 gene catalogue（此处，操作上，将非冗余的连续基因编码的核酸序列称之为 genes<SUP>['.$part[$j++].']</SUP>），默认以 identity 95%, coverage 90% 进行聚类，并选取最长的序列为代表性序列；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;采用参数<SUP>['.$part[$j++].','.$part[$j++].']</SUP>：-c 0.95, -G 0, -aS 0.9, -g 1, -d 0</br>
    3）采用 <a href="http://bowtie-bio.sourceforge.net/bowtie2/index.shtml" target="_blank" >Bowtie2</a>，将各样品的 Clean Data 比对至初始 gene catalogue，计算得到基因在各样品中比对上的 reads 数目；</br>
    &nbsp;&nbsp;&nbsp;&nbsp;比对参数<SUP>['.$part[$j++].','.$part[$j++].']</SUP>：--end-to-end, --sensitive, -I 200, -X 400</br>
    4）过滤掉在各个样品中支持 reads 数目<=2<SUP>['.$part[$j++].','.$i++.']</SUP> 的基因，获得最终用于后续分析的 gene catalogue（Unigenes）；</br>
    5）从比对上的 reads 数目及基因长度出发，计算得到各基因在各样品中的丰度信息，计算公式<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$i++.','.$i++.','.$i++.']</SUP>如下所示：</br>
    <p class="center">
    <img  src="src/images/gene_abun.png" width="15%" height="5%"/>
    </p>
    <p class="premark">说明：r 为比对上基因的 reads 数目，L 为基因的长度</p></br>
    <p class="tremark">6）基于 gene catalogue 中各基因在各样品中的丰度信息，进行基本信息统计，core-pan 基因分析，样品间相关性分析，及基因数目韦恩图分析。</p></br>'.

    '<a name="3.3.2 gene catalogue 基本信息统计"></a><h4>3.3.2 gene catalogue 基本信息统计</h4>'.
    '<p class="name">表 3.3.2 gene catalogue 基本信息统计表</p>
        <div id="tb">'.$total_gene_table.'</div></br>
    <p class="premark">说明：ORFs NO. 表示 gene catalogue 中基因的数目；integrity:start 表示只含有起始密码子的基因数目及百分比；integrity:end 表示只含有终止密码子的基因数目及百分比；integrity:none 表示没有起始密码子也没有终止密码子的基因数目及百分比；integrity:all 表示完整基因（既有起始密码子也有终止密码子）数目的百分比；Total Len.(Mbp) 表示 gene catalogue 中基因的总长，单位是百万；Average Len. 表示 gene catalogue 中基因的平均长度；GC Percent 表示预测的 gene catalogue 中基因的整体 GC 含量值。</p>
    <p class="center">
        <a href="src/pictures/03.GeneComp/Unigenes.CDS.cdhit.fa.len.png" target="_blank" ><img  src="src/pictures/03.GeneComp/Unigenes.CDS.cdhit.fa.len.png" width="40%" height="40%"/></a>
        </p> 
    <p class="name">图 3.3.2 gene catalogue 长度分布统计</p>
    <p class="premark">说明：第一纵轴 Frequence(#) 表示 gene catalogue 中基因的数目；第二纵轴 Percentage(%) 表示 gene catalogue 中基因数目的百分比；横轴表示 gene catalogue 中基因的长度。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">gene catalogue 长度分布统计见：result/03.GenePredict/GenePredict/Sample(NOVO_MIX)/*.{svg,png,xls}；</p>';
    if (${$description}{'core-pan 基因分析'}) {
        $mulu2description .= '<a name="3.3.3 core-pan 基因分析"></a><h4>3.3.3 core-pan 基因分析</h4>'.$core_pan;
    }

    if( ${$description}{'基因数目差异分析'}){
        $mulu2description .= '<a name="'.${$description}{'基因数目差异分析'}.' 基因数目差异分析"></a><h4>'.${$description}{'基因数目差异分析'}.' 基因数目差异分析</h4>'.
        '<p class="paragraph">为了考察组与组间的基因数目差异情况，绘制了组间基因数目差异箱图，展示结果如下：</p>
         <p class="center">
            <a href="src/pictures/03.GeneComp/group.genebox.png" target="_blank" ><img  src="src/pictures/03.GeneComp/group.genebox.png" width="40%" height="40%"/></a>
            </p> 
        <p class="name">图 '.${$description}{'基因数目差异分析'}.'.1 组间基因数目差异箱图</p>
        <p class="premark">说明：横坐标为各个分组信息；纵坐标为基因数目。</p>';
        if (-s "$report/src/pictures/03.GeneComp/venn_flower_display.png"){
        	$mulu2description.=
    		'<p class="paragraph">为了考察指定样品（组）间的基因数目分布情况，分析不同样品（组）之间的基因共有、特有信息，绘制了韦恩图(Venn Graph)或花瓣图，展示结果如下：</p>
    		<p class="center">
        	<a href="src/pictures/03.GeneComp/venn_flower_display.png" target="_blank" ><img  src="src/pictures/03.GeneComp/venn_flower_display.png" width="40%" height="40%"/></a>
        	</p> 
    		<p class="name">图 '.${$description}{'基因数目差异分析'}.'.2 基因数目韦恩图（花瓣图）分析</p>
    		<p class="premark">说明：当样本（组）数小于5时，展示韦恩图，当样本（组）数超过5个时，展示花瓣图；图中，每个圈代表一个样品；圈和圈重叠部分的数字代表样品之间共有的基因个数；没有重叠部分的数字代表样品的特有基因个数。</p>';
            }
            $mulu2description.=
            '<p class="paragraph">结果目录：</p>
            <p class="paragraph">组间基因数目差异箱图见：result/03.GenePredict/GeneStat/genebox/*.{png,pdf}；</p>';
            $mulu2description.='<p class="paragraph">基因数目韦恩图（花瓣图）分析：result/03.GenePredict/GeneStat/venn_flower/*.{png,pdf}。</p>' if (-s "$report/src/pictures/03.GeneComp/venn_flower_display.png");
    }
    

    if(${$description}{'基于基因数目的样品间相关性分析'}){
        $mulu2description.='<a name="'.${$description}{'基于基因数目的样品间相关性分析'}.' 基于基因数目的样品间相关性分析"></a><h4>'.${$description}{'基于基因数目的样品间相关性分析'}.' 基于基因数目的样品间相关性分析</h4>'.
    '<p class="paragraph">生物学重复是任何生物学实验所必须的，高通量测序技术也不例外。样品间基因丰度相关性是检验实验可靠性和样本选择是否合理性的重要指标。相关系数越接近1，表明样品之间基因丰度模式的相似度越高。</p>
    <p class="center">
        <a href="src/pictures/03.GeneComp/correlation.heatmap.png" target="_blank" ><img  src="src/pictures/03.GeneComp/correlation.heatmap.png" width="40%" height="40%"/></a>
        </p> 
    <p class="name">图 '.${$description}{'基于基因数目的样品间相关性分析'}.' 样品间相关系数热图</p>
    <p class="premark">说明：图中，不同颜色代表 spearman 相关系数的高低；相关系数与颜色间的关系见右侧图例说明；颜色越深代表样品间相关系数的绝对值越大；椭圆向左偏表明相关系数为正，右偏为负；椭圆越扁说明相关系数的绝对值越大。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">样品间相关系数热图见：result/03.GenePredict/GeneStat/correlation/*.{png,pdf}；</p>';
    }
    
	#For TaxAnnotation
    $mulu2description .= 
    '<!-------------------------------------------- 物种注释 --------------------------------------------->'.
    '<a name="3.4 物种注释"></a><a href="src/images/04.TaxAnnotation--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3> 3.4 物种注释&nbsp;>></h3></a>'.
    '<a name="3.4.1 物种注释基本步骤"></a><h4>3.4.1 物种注释基本步骤</h4>'.
    '<p class="tremark">1）使用genes 与各功能数据库进行比对·DIAMOND软件<SUP>['.$i++.']</SUP>将 Unigenes 与从 <a href="http://www.ncbi.nlm.nih.gov/" target="_blank" >NCBI</a> 的 NR(Version: 2018.01) 数据库中抽提出的细菌(Bacteria)、真菌(Fungi)、古菌(Archaea)和病毒(Viruses)序列进行比对（blastp，evalue ≤ 1e-5）；</br>
    2）比对结果过滤：对于每一条序列的 比对结果，选取 evalue <= 最小 evalue*10<SUP>['.$part[$j++].']</SUP> 的比对结果进行后续分析；</br>
    3）过滤后，由于每一条序列可能会有多个比对结果，得到多个不同的物种分类信息，为了保证其生物意义，采取 <a href="http://en.wikipedia.org/wiki/Lowest_common_ancestor" target="_blank" >LCA</a> 算法(应用于 MEGAN<SUP>['.$i++.']</SUP> 软件的系统分类)，将出现第一个分支前的分类级别，作为该序列的物种注释信息；</br>
    4）从 LCA 注释结果及基因丰度表出发，获得各个样品在各个分类层级（界门纲目科属种）上的丰度信息，对于某个物种在某个样品中的丰度，等于注释为该物种的基因丰度的加和<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].']</SUP>；</br>
    5）从 LCA 注释结果及基因丰度表出发，获得各个样品在各个分类层级（界门纲目科属种）上的基因数目表，对于某个物种在某个样品中的基因数目，等于在注释为该物种的基因中，丰度不为 0 的基因数目；</br>
    6）从各个分类层级（界门纲目科属种）上的丰度表出发，进行 Krona 分析，相对丰度概况展示，丰度聚类热图展示，PCA 和 NMDS 降维分析，Anosim组间（内）差异分析，组间差异物种的Metastat和LEfSe多元统计分析。</br></p>'.
    
	#Show krona
    '<a name="3.4.2 物种相对丰度概况"></a><h4>3.4.2 物种相对丰度概况</h4>'.
    '<p class="paragraph">为了综合而直观的展示各样品中，不同分类层级的物种相对丰度，我们采用 Krona<SUP>['.$i++.']</SUP> 对物种注释结果进行可视化展示，Krona 示例图如下所示，详细结果<a href="src/pictures/04.Taxonomy/taxonomy.krona.html" target="_blank"  >请点击</a>。</P>
    <p class="center">
            <img  src="src/images/metagenome.krona.png" width="70%" height="70%"/>
            </p><br>
    <p class="name">图 3.4.2.1 使用 Krona 对物种注释结果进行展示（示例图）</P>
    <p class="premark">说明：图中，圆圈从内到外依次代表不同的分类级别（界门纲目科属种）；扇形的大小代表不同物种的相对比例；更多详细的信息请参考<a href="http://sourceforge.net/p/krona/wiki/Browsing%20Krona%20chartss/" target="_blank" > KRONA 展示结果详解</a>。</P>'.
    
	#Show top10
    #'<a name="3.4.3 物种相对丰度概况"></a><h4>3.4.3 物种相对丰度概况</h4>'.
    '<p class="paragraph">从不同分类层级的相对丰度表出发，选取出在各样品（组）中的最大相对丰度排名前 10 的物种，并将其余的物种设置为 Others，绘制出各样品对应的物种注释结果在不同分类层级上的相对丰度柱形图。</p>
    <p class="center">
        <a href="src/pictures/04.Taxonomy/top.pg.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/top.pg.png" width="70%" height="70%"/></a>
        </p>
    <p class="name">图 3.4.2.2 门水平和属水平的物种相对丰度柱形图（样品）</p>
    <p class="premark">说明：a）门水平相对丰度柱形图；b）属水平相对丰度柱形图。横轴表示样品名称；纵轴表示注释到某类型的物种的相对比例；各颜色区块对应的物种类别见右侧图例。</p>';
    if(-s "$report/src/pictures/04.Taxonomy/top.pg.g.png")
    {$mulu2description.= '<p class="center">
    <p class="center">    
    <a href="src/pictures/04.Taxonomy/top.pg.g.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/top.pg.g.png" width="70%" height="70%"/></a>
    </p>
    <p class="name">图 3.4.2.3 门水平和属水平的物种相对丰度柱形图（组）</p>
    <p class="premark">说明：a）门水平相对丰度柱形图；b）属水平相对丰度柱形图。横轴表示样品名称；纵轴表示注释到某类型的物种的相对比例；各颜色区块对应的物种类别见右侧图例。</p>'
    }
    $mulu2description.='<p class="paragraph">结果目录：</p>
    <p class="paragraph">Krona展示结果见：result/04.TaxAnnotation/Krona/taxonomy.krona.html；</p>
    <p class="paragraph">top10物种相对丰度柱形图见：result/04.TaxAnnotation/top，包括门纲目科属（Phylum、 Class、 Order、 Family、 Genus）5个分类级别的结果。</p>';
    $mulu2description.='<p class="paragraph">组top10物种相对丰度柱形图见：result/04.TaxAnnotation/top_group，包括门纲目科属（Phylum、 Class、 Order、 Family、 Genus）5个分类级别的结果。</p>' if (-s "$report/src/pictures/04.Taxonomy/top.pg.g.png");
	#Show heatmap
    if(${$description}{'注释基因数目及相对丰度聚类分析'}){
        $mulu2description .=
    '<a name="'.${$description}{'注释基因数目及相对丰度聚类分析'}.' 注释基因数目及相对丰度聚类分析"></a><h4>'.${$description}{'注释基因数目及相对丰度聚类分析'}.' 注释基因数目及相对丰度聚类分析</h4>'.
    '<p class="paragraph">从不同分类层级的相对丰度表出发，选取丰度排名前 35 的属及它们在每个样品中的丰度信息绘制热图，并从物种层面进行聚类，便于结果展示和信息发现，从而找出样品中聚集较多的物种，结果展示见下图：</p>
     <p class="center">
        <a href="src/pictures/04.Taxonomy/heatmap.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/heatmap.png" width="60%" height="60%"/></a>
        </p>
    <p class="name">图 '.${$description}{'注释基因数目及相对丰度聚类分析'}.' 属水平基因数目及丰度聚类热图</p>
    <p class="premark">说明：a) Unigenes 注释数目统计热图：横轴为样品名称；纵轴为物种信息；不同颜色代表 Unigenes 数目的高低；b) 属水平相对丰度聚类热图：横向为样品信息；纵向为物种信息；图中左侧的聚类树为物种聚类树；中间热图对应的值为每一行物种相对丰度经过标准化处理后得到的 Z 值，即一个样品在某个分类上的 Z 值为样品在该分类上的相对丰度和所有样品在该分类的平均相对丰度的差除以所有样品在该分类上的标准差所得到的值。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">Unigenes 注释数目统计热图见：result/04.TaxAnnotation/GeneNums.BetweenSamples.heatmap，包括门纲目科属（Phylum、 Class、 Order、 Family、 Genus）5个分类级别的结果；</p>
    <p class="paragraph">相对丰度聚类热图见：result/04.TaxAnnotation/heatmap，包括门纲目科属（Phylum、 Class、 Order、 Family、 Genus）5个分类级别的结果。</p>';
    }
    
	#Show PCA & NMDS
    if(${$description}{'基于物种丰度的降维分析'}){
        push @liter,(26,46);
        $mulu2description .=
    '<a name="'.${$description}{'基于物种丰度的降维分析'}.' 基于物种丰度的降维分析"></a><h4>'.${$description}{'基于物种丰度的降维分析'}.' 基于物种丰度的降维分析</h4>'.
    '<p class="paragraph">目前适用于生态学研究的降维分析主要是主成分分析 (PCA，Principal Component Analysis)和无度量多维标定法（NMDS，Non-Metric Multi-Dimensional Scaling）分析。其中，PCA是基于线型模型的一种降维分析，它应用方差分解的方法对多维数据进行降维，从而提取出数据中最主要的元素和结构<SUP>['.$i++.']</SUP>；PCA 能够提取出最大程度反映样品间差异的两个坐标轴，从而将多维数据的差异反映在二维坐标图上，进而揭示复杂数据背景下的简单规律。而NMDS是非线性模型，其目的是为了克服线性模型的缺点，更好地反映生态学数据的非线性结构<SUP>['.$i++.']</SUP>，应用NMDS分析，根据样本中包含的物种信息，以点的形式反映在多维空间上，而不同样本间的差异程度则是通过点与点间的距离体现，能够反映样本的组间或组内差异等。
    基于不同分类层级的物种丰度表，我们进行了 PCA 和 NMDS分析，如果样品的物种组成越相似，则它们在 PCA 和 NMDS 图中的距离则越接近。</p>
    <p class="center">
        <a href="src/pictures/04.Taxonomy/PCA_NMDS.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/PCA_NMDS.png" width="60%" height="60%"/></a>
        </p>
    <p class="name">图 '.${$description}{'基于物种丰度的降维分析'}.' 基于门水平的物种 PCA 和 NMDS 结果展示</p>
    <p class="premark">说明：a）门水平PCA分析，横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示；b）门水平NMDS分析，图中的每个点表示一个样品，点与点之间的距离表示差异程度，同一个组的样品使用同一种颜色表示；Stress小于0.2时，表明NMDS分析具有一定的可靠性。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">标注样品名的PCA图见：result/04.TaxAnnotation/PCA/*/PCA12.{png,pdf}；</p>
    <p class="paragraph">未标注样品名的PCA图见：result/04.TaxAnnotation/PCA/*/PCA12_2.{png,pdf}；</p>
    <p class="paragraph">未标示样品名称的带聚类圈的PCA图见：result/04.TaxAnnotation/PCA/*/PCA12_with_cluster_2.{png,pdf}；</p>
    <p class="paragraph">标示样品名称的带聚类圈的PCA图见：result/04.TaxAnnotation/PCA/*/PCA12_with_cluster.{png,pdf}；</p>
    <p class="paragraph">各个主成分分析结果见：result/04.TaxAnnotation/PCA/*/pca.csv；</p>
    <p class="paragraph">标注样品名的NMDS图见：result/04.TaxAnnotation/NMDS/*/ NMDS12.{png,pdf}；</p>
    <p class="paragraph">未标注样品名的NMDS图见：result/04.TaxAnnotation/NMDS/*/ NMDS12_2.{png,pdf}；</p>
    <p class="paragraph">未标示样品名称的带聚类圈的NMDS图见：result/04.TaxAnnotation/NMDS/*/NMDS_withcluster_2.{png,pdf}；</p>
    <p class="paragraph">标示样品名称的带聚类圈的NMDS图见：result/04.TaxAnnotation/NMDS/*/NMDS_withcluster.{png,pdf}；</p>
    <p class="paragraph">各样品在两个主成分轴上的位置坐标见：result/04.TaxAnnotation/NMDS/*/NMDS_scores.txt。</p>';
    }

  #Show PCoA
   if(${$description}{'基于物种丰度的Bray-Curtis 距离的降维分析'}){
       $mulu2description .=
    '<a name="'.${$description}{'基于物种丰度的Bray-Curtis 距离的降维分析'}.' 基于物种丰度的Bray-Curtis 距离的降维分析"></a><h4>'.${$description}{'基于物种丰度的Bray-Curtis 距离的降维分析'}.' 基于物种丰度的Bray-Curtis 距离的降维分析</h4>'.
    '<p class="paragraph">主坐标分析（PCoA，Principal Co-ordinates Analysis），是通过一系列的特征值和特征向量排序从多维数据中提取出最主要的元素和结构。我们基于<a href="http://en.wikipedia.org/wiki/Bray%E2%80%93Curtis_dissimilarity" target="_blank" >Bray-Curtis 距离</a>来进行PCoA分析，并选取贡献率最大的主坐标组合进行作图展示。如果样品距离越接近，表示物种组成结构越相似，因此群落结构相似度高的样品倾向于聚集在一起，群落差异很大的样品则会远远分开。
    基于不同分类层级的物种丰度表得到Bray-Curtis 距离矩阵，我们进行了 PCoA分析。基于门水平的PCoA分析结果展示如下：</p>
     <p class="center">
     <a href="src/pictures/04.Taxonomy/PCoA.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/PCoA.png" width="40%" height="40%"/></a>
     </p>
     <p class="name">图 '.${$description}{'基于物种丰度的Bray-Curtis 距离的降维分析'}.' 基于门水平的物种 PCoA 结果展示</p>
     <p class="premark">说明：横坐标表示一个主成分，纵坐标表示另一个主成分，百分比表示主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示。</p>
     <p class="paragraph">结果目录：</p>
     <p class="paragraph">标注样品名的PCoA图见：result/04.TaxAnnotation/PCoA/*/PCoA12.{png,pdf}；</p>
     <p class="paragraph">未标注样品名的PCoA图见：result/04.TaxAnnotation/PCoA/*/PCoA12_2.{png,pdf}；</p>
	 <p class="paragraph">标示样品名称的带聚类圈的PCoA图见：result/04.TaxAnnotation/PCoA/*/PCoA12_withcluster.{png,pdf}；</p>
	 <p class="paragraph">未标示样品名称的带聚类圈的PCoA图见：result/04.TaxAnnotation/PCoA/*/PCoA12_withcluster_2.{png,pdf}；</p>
     <p class="paragraph">各个主成分分析结果见：result/04.TaxAnnotation/PCoA/*/PCoA.csv。</p>';
   }
    
	#Show Anosim
	if(${$description}{'基于物种丰度的Anosim分析'}){
        $mulu2description .=
    '<a name="'.${$description}{'基于物种丰度的Anosim分析'}.' 基于物种丰度的Anosim分析"></a><h4>'.${$description}{'基于物种丰度的Anosim分析'}.' 基于物种丰度的Anosim分析</h4>'.
    '<p class="paragraph">Anosim分析是一种非参数检验，用来检验组间的差异是否显著大于组内差异，从而判断分组是否有意义，详细计算过程可查看<a href="http://cc.oulu.fi/~jarioksa/softhelp/vegan/html/anosim.html" title="Anosim" target="_blank">Anosim</a>。基于物种门水平的Anosim分析结果如下：</p>
    <p class="center">
	<a href="src/pictures/04.Taxonomy/Anosim.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/Anosim.png" width="40%" height="40%"/></a>
    </p>
    <p class="name">图 '.${$description}{'基于物种丰度的Anosim分析'}.' 基于门水平的Anosim分析</p>
    <p class="premark">说明：横向为分组信息，纵向为距离信息。Between为两组合并信息，between中位线高于另外两组中位线为分组信息较好。R-value介于（-1，1）之间，R-value大于0，说明组间差异显著。R-value小于0，说明组内差异大于组间差异，统计分析的可信度用 P-value 表示，P< 0.05 表示统计具有显著性。</p> 
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">Anosim分析结果见：result/04.TaxAnnotation/Anosim。</p>';  
	}
	
	#Show cluster tree
    if(${$description}{'基于物种丰度的样品聚类分析'}){
        $mulu2description .=
    '<a name="'.${$description}{'基于物种丰度的样品聚类分析'}.' 基于物种丰度的样品聚类分析"></a><h4>'.${$description}{'基于物种丰度的样品聚类分析'}.' 基于物种丰度的样品聚类分析</h4>'.
    '<p class="paragraph">为了研究不同样品的相似性，还可以通过对样品进行聚类分析，构建样品的聚类树。<a href="http://en.wikipedia.org/wiki/Bray%E2%80%93Curtis_dissimilarity">Bray-Curtis 距离</a>是系统聚类法中使用最普遍的一个距离指标，它主要用来刻画样品间的相近程度，它的大小是进行样品分类的主要依据。
    <p class="paragraph">从基因在各样品中的丰度表出发，以 Bray-Curtis 距离矩阵进行样品间聚类分析，并将聚类结果与各样品在门水平上的物种相对丰度整合进行展示。
    <p class="center">
        <a href="src/pictures/04.Taxonomy/Bar.tree.p10.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/Bar.tree.p10.png" width="50%" height="50%"/></a>
        </p>
    <p class="name">图 '.${$description}{'基于物种丰度的样品聚类分析'}.' 基于 Bray-Curtis 距离的聚类树
    说明：图中，左侧是 Bray-Curtis 距离聚类树结构；右侧的是各样品在门水平上的物种相对丰度分布图。
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">基于 Bray-Curtis 距离的聚类树见：result/04.TaxAnnotation/Cluster_Tree。</p>';
    }
    
	#Show Metastat
    if(${$description}{'组间差异物种的Metastat分析'} ){
        push @liter,41;
        if($show{tax_box}){
		$mulu2description .=
    '<a name="'.${$description}{'组间差异物种的Metastat分析'}.' 组间差异物种的Metastat分析"></a><h4>'.${$description}{'组间差异物种的Metastat分析'}.' 组间差异物种的Metastat分析</h4>'.
    '<p class="paragraph">为了研究组间具有显著性差异的物种，从不同层级的物种丰度表出发，利用 Metastats<SUP>['.$i++.']</SUP> 方法对组间的物种丰度数据进行假设检验得到 p 值，通过对 p 值的校正，得到 q 值；最后根据 q 值筛选具有显著性差异的物种，并绘制差异物种在组间的丰度分布箱图。</p>
    <p class="center">
        <a href="src/pictures/04.Taxonomy/top.12.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/top.12.png" width="60%" height="60%"/></a>
        </p>
    <p class="name">图 '.${$description}{'组间差异物种的Metastat分析'}.'.1 显著差异物种的箱图展示</p>
    <p class="premark">说明：图中，横轴为样品分组；纵向为对应物种的相对丰度。横线代表具有显著性差异的两个分组，没有则表示此物种在两个分组间不存在差异。“＊”表示两组间差异显著（q value < 0.05），“＊＊”表示两组间差异极显著（q value < 0.01）。</p>';
	    }
	    if($show{tax_diff}){
		$mulu2description .=
    '<p class="paragraph">根据组间具有差异的物种进行主成分 PCA 分析和丰度聚类热图分析，展示结果如下:</p>
     <p class="center">
        <a href="src/pictures/04.Taxonomy/tax.ph.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/tax.ph.png" width="60%" height="60%"/></a>
        </p>
    <p class="name">图 '.${$description}{'组间差异物种的Metastat分析'}.'.2 基于显著性差异物种的 PCA 分析和丰度聚类热图</p>
    <p class="premark">说明：a) 为显著性差异物种的丰度聚类热图：横向为样品信息；纵向为物种注释信息；图中左侧的聚类树为物种聚类树；中间热图对应的值为每一行物种相对丰度经过标准化处理后得到的 Z 值；b) 为显著性差异物种的 PCA 图：横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示。</p>';
	    }
    $mulu2description .='<p class="paragraph">结果目录：</p>
    <p class="paragraph">各分类层级（phylum、class、order、family、genus、species）的MetaStat分析结果见：result/04.TaxAnnotation/MetaStats；</p>
    <p class="paragraph">以门水平为例，MetaStat分析结果见：result/04.TaxAnnotation/MetaStats/phylum/ *.test.xls；</p>
    <p class="paragraph">从MetaStat分析结果中，筛选出的 P value<=0.05的信息见：result/04.TaxAnnotation/MetaStats/phylum/ *.psig.xls；</p>
    <p class="paragraph">从MetaStat分析结果中，筛选出的 Q value<=0.05的信息见：result/04.TaxAnnotation/MetaStats/phylum/ *.qsig.xls。</p>';
    }
	
	#Show LEfSe
	if(${$description}{'组间差异物种的LEfSe分析'}){
        if($show{tax_lda}){
		push @liter,52;
		    $mulu2description.=
    '<a name="'.${$description}{'组间差异物种的LEfSe分析'}.' 组间差异物种的LEfSe分析"></a><h4>'.${$description}{'组间差异物种的LEfSe分析'}.' 组间差异物种的LEfSe分析</h4>'.
    '<p class="paragraph">为了筛选组间具有显著差异的物种Biomarker，首先通过秩和检验的方法检测不同分组间的差异物种并通过LDA（线性判别分析）实现降维并评估差异物种的影响大小，即得到LDA score <SUP>['.$i++.']</SUP>；组间差异物种的LEfSe分析结果包括三部分，分别是LDA值分布柱状图，进化分支图（系统发育分布）和组间具有统计学差异的Biomarker在不同组中丰度比较图。差异物种的LDA值分布图和进化分支图如下：</p>'.$tax_lda_pics.'
    <p class="name">图 '.${$description}{'组间差异物种的LEfSe分析'}.'.1 差异物种的LDA值分布图和进化分支图</p>
    <p class="premark">说明：左图为差异物种的LDA值分布图，LDA值分布柱状图中展示了LDA Score大于设定值（默认设置为4）的物种，即组间具有统计学差异的Biomarker，柱状图的长度代表差异物种的影响大小（即为 LDA Score）。右图为差异物种的进化分支图，由内至外辐射的圆圈代表了由门至属（或种）的分类级别。在不同分类级别上的每一个小圆圈代表该水平下的一个分类，小圆圈直径大小与相对丰度大小呈正比。着色原则：无显著差异的物种统一着色为黄色，差异物种Biomarker跟随组进行着色，红色节点表示在红色组别中起到重要作用的微生物类群，绿色节点表示在绿色组别中起到重要作用的微生物类群。图中英文字母表示的物种名称在右侧图例中进行展示。</p>';
            if($show{tax_lda_hp}){
		        $mulu2description.='<p class="paragraph">基于上述LEfSe筛选出的组间具有差异的物种丰度，选择特定分类层级（默认为genus）的差异物种绘制聚类热图以反映这些差异物种在各样品中分布情况。基于差异物种的聚类热图展示结果如下:</p>'.$lda_cluster_pics.'
    <p class="name">图 '.${$description}{'组间差异物种的LEfSe分析'}.'.2 基于差异物种的聚类热图</p>
    <p class="premark">说明：图中横向为样品信息，纵向为物种信息，左侧的聚类树为物种聚类树，中间热图对应的值为每一行物种相对丰度经过标准化处理后得到的Z值。</p>';
            }	
	        if($show{tax_hp_roc} ){
		        $mulu2description.=
    '<p class="paragraph">为了检验通过LEfSe筛选出来的组间差异Biomarker的分类预测能力，绘制受试者工作特征曲线 （receiver operating characteristic curve，简称ROC曲线），又称为感受性曲线（sensitivity curve）。ROC曲线常用来评价一个二值分类器的好坏，也是基于统计学上判断分组信息优劣的指标。AUC（Area Under Curve）被定义为ROC曲线下的面积。通常情况下，它的值在1.0和0.5之间。在AUC>0.5的情况下，AUC越接近于1，说明分类预测效果越好；基于差异物种的ROC曲线展示结果如下:</p>'.$tax_roc_pics.'
    <p class="name">图 '.${$description}{'组间差异物种的LEfSe分析'}.'.3 基于差异物种的 ROC 曲线</p>
    <p class="premark">说明：图中横坐标为假阳性率，纵坐标为真阳性率，曲线的面积越接近于1表明分类器的效果越好。CI（Confidence interval）：95%的置信区间。</p>';
	        }		    
    $mulu2description.='<p class="paragraph">结果目录：</p>
     <p class="paragraph">LEfSe分析结果见: result/04.TaxAnnotation/LDA。</p>';
        }
    }
	#Show RandForest ROC
	if(${$description}{'基于物种丰度的RandomForest分析'})
	{
        if($show{tax_show_rf_roc})
		{
		    $mulu2description.='<a name="'.${$description}{'基于物种丰度的RandomForest分析'}. '"></a><h4>' .${$description}{'基于物种丰度的RandomForest分析'}.'基于物种丰度的RandomForest分析</h4>'.'<p class="paragraph">随机森林是一种基于分类树算法的经典机器学习模型，由LeoBreiman（2001）提出，它通过自助法（bootstrap）重采样技术，从原始训练样本集N中有放回地重复随机抽取k个样本生成新的训练样本集合，然后根据自助样本集生成k个分类树组成随机森林，新数据的分类结果按分类树投票多少形成的分数而定。</p>
	<p class="paragraph">对于建立好的模型,可以通过交叉验证(Cross-validation)或者受试者工作特征曲线（receiver operating characteristic curve，ROC）的方法对模型的性能进行评估。</p>
	<p class="paragraph">在生态学的研究中，随机森林算法主要应用于对两组数据的分类的Biomarker筛选。判断的Biomarker的指标有MeanDecreaseAccuracy和MeanDecreaseGin。</p>
<p class="paragraph">MeanDecreaseAccuracy表示随机森林预测准确性的降低程度。该值越大表示该变量的重要性越大</p>
<p class="paragraph">MeanDecreaseGini通过基尼（Gini）指数计算每个变量对分类树每个节点上观测值的异质性的影响，该值越大表示该变量的重要性越大。</p>
<p class="paragraph" >基于物种丰度的随机森林的分析，对不同分类水平，按梯度选取不同数量的物种，构建随机森林模型。通过MeanDecreaseAccuracy和MeanDecreaseGin筛选出重要的物种，之后对每个模型做交叉验证（默认10-fold）并绘制ROC曲线.</p>';

		}
	if($show{tax_cv_auc_point})
	{
		$mulu2description.='<p class="paragraph"></p>
	<p class ="center"> <a href="src/pictures/04.Taxonomy/tax_show_ea.png" target="_blank"><img src="src/pictures/04.Taxonomy/tax_show_ea.png" width="50%" height="50%"/> </a></p>
	<p class="name">图 '.${$description}{'基于物种丰度的RandomForest分析'}.'.1 10-fold交叉验证和ROC曲线对不同物种数目随机森林模型的评估曲线</p>
	<p class="premark">a)Error rate of 10-fold cross Validation，横坐标：物种数目,纵坐标：不同物种数目做10-fold cross_validation的Error rate；b)AUC of Sub_Random Forest，横坐标：物种数目，纵坐标：不同物种数目ROC曲线的AUC值</p>
	<p class="paragraph">结果目录：</p>
	<p class="paragraph">不同物种数目10-fold验证结果见：result/04.TaxAnnotation/rf_roc/*/*/*/cverrof.png</p>
	<p class="paragraph">不同物种数目ROC曲线结果见：result/04.TaxAnnotation/rf_roc/*/*/trainset.point_auc.png</p>';
	}
	if($show{tax_imp})
	{
	$mulu2description.='<p class="center"><a href="src/pictures/04.Taxonomy/tax_imp.png" target="_blank" ><img src="src/pictures/04.Taxonomy/tax_imp.png " width="50%" height="50%"></a></p>
	<p class="name">图 '.${$description}{'基于物种丰度的RandomForest分析'}.'.2 重要性物种</p>
	<p class="paragraph">结果目录：</p>
	<p class="paragraph">基于MeanDecreaseAccuracy重要性物种结果见：result/04.TaxAnnotation/rf_roc/*/*/*/impplot_MeanDecreaseAccuracy*.png</p>
	<p class="paragraph">基于MeanDecreaseAccuracy重要性物种结果见：result/04.TaxAnnotation/rf_roc/*/*/*/impplot_MeanDecreaseGin*.png</p>';
	}
	if($show{tax_show_rf_roc})
	{
		$mulu2description.='<p class="paragraph">为了展示不同分组及不同物种数目下建立的随机森林的模型性能的比较，绘制了如下ROC曲线，展示结果如下图所示：</p>'.$tax_rf_roc_pic.'
<p class="name">图 '.${$description}{'基于物种丰度的RandomForest分析'}.'.3 随机森林模型ROC曲线的比较</p>
<p class="premark">从上至下，依次是，AUC值最大的物种数的构建的随机森林的单个ROC曲线、不同物种数的随机森林模型的ROC曲线、各个分组中AUC值最大的ROC曲线.</p>
<p class="paragraph">结果目录：</p>
<p class="paragraph">单个ROC曲线见：result/04.TaxAnnotation/rf_roc/*/*/*/trainset.ROC.png</p>
<p class="paragraph">不同物种数的随机森林模型的ROC曲线见：result/04.TaxAnnotation/rf_roc/*/*/trainset_auc.png</p>
<p class="paragraph">各个分组中AUC值最大的ROC曲线见：result/04.TaxAnnotation/rf_roc/*/trainset_group_max_roc.png</p>
';
	}
    
	}

	#For FunctionAnnotation
    push @liter,(21,42,43,23,44);
    $mulu2description .=
    '<!-------------------------------------------- 功能注释 --------------------------------------------->'.
    '<a name="3.5 常用功能数据库注释"></a><a href="src/images/05.FunctionAnnotation--readme.pdf"  target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3>3.5 常用功能数据库注释&nbsp;>></h3> </a>'.
    '<p class="paragraph">目前常用的功能数据库主要有：</p>
    <p class="paragraph">&nbsp;&nbsp;&nbsp;&nbsp;Kyoto Encyclopedia of Genes and Genomes (KEGG)<SUP>['.$i++.','.$i++.']</SUP>; Version: 2018.01；</p>
    <p class="paragraph">&nbsp;&nbsp;&nbsp;&nbsp;Evolutionary genealogy of genes: Non-supervised Orthologous Groups (eggNOG)<SUP>['.$i++.']</SUP>; Version: 4.5；</p>
    <p class="paragraph">&nbsp;&nbsp;&nbsp;&nbsp;Carbohydrate-Active enzymes Database (CAZy)<SUP>['.$i++.']</SUP>; Version: 2015.08；</p>
    <p class="paragraph">KEGG 数据库于 1995 年由 Kanehisa Laboratories 推出 0.1 版，目前发展为一个综合性数据库，其中最核心的为 KEGG PATHWAY 和 KEGG ORTHOLOGY 数据库。在 KEGG ORTHOLOGY 数据库中，将行使相同功能的基因聚在一起，称为 Ortholog Groups (KO entries)，每个 KO 包含多个基因信息，并在一至多个 pathway 中发挥作用。而在 KEGG PATHWAY 数据库中，将生物代谢通路划分为 6 类，分别为：细胞过程（Cellular Processes）、环境信息处理（Environmental Information Processing）、遗传信息处理（Genetic Information Processing）、人类疾病（Human Diseases）、新陈代谢（Metabolism）、生物体系统（Organismal Systems），其中每类又被系统分类为二、三、四层。第二层目前包括有 66 种子 pathway；第三层即为其代谢通路图；第四层为每个代谢通路图的具体注释信息。</p>
    <p class="paragraph">eggNOG 数据库是利用 Smith-Waterman 比对算法对构建的基因直系同源簇 (Orthologous Groups) 进行功能注释，eggNOG V4.1 涵盖了 2,031 个物种的基因，构建了约 19 万个 Orthologous Groups。</p>
    <p class="paragraph">CAZy 数据库是研究碳水化合物酶的专业级数据库，主要涵盖 6 大功能类：糖苷水解酶（Glycoside Hydrolases ，GHs），糖基转移酶（Glycosyl Transferases，GTs），多糖裂合酶（Polysaccharide Lyases，PLs），碳水化合物酯酶（Carbohydrate Esterases，CEs），辅助氧化还原酶(Auxiliary Activities , AAs)和碳水化合物结合模块（Carbohydrate-Binding Modules， CBMs）。</p>'.

    '<a name="3.5.1 功能注释基本步骤"></a><h4>3.5.1 功能注释基本步骤</h4>'.
    '<p class="paragraph">1）使用DIAMOND软件将 Unigenes 与各功能数据库进行比对（blastp，evalue ≤ 1e-5）<SUP>['.$part[$j++].','.$part[$j++].']</SUP>；</p>
    <p class="paragraph">2）比对结果过滤：对于每一条序列的 比对结果，选取 score 最高的比对结果（one HSP > 60 bits）进行后续分析<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].','.$i++.']</SUP>；</p>
    <p class="paragraph">3）从比对结果出发，统计不同功能层级的相对丰度（各功能层级的相对丰度等于注释为该功能层级的基因的相对丰度之和<SUP>['.$part[$j++].','.$part[$j++].','.$part[$j++].']</SUP>），其中，KEGG 数据库划分为 6 个层级，eggNOG 数据库划分为 3 个层级，CAZy 数据库划分为 3 个层级，各数据库的详细划分层级如下所示：</p>
    <div id="tb">
    <table>
    <tbody>
    <tr><th>数据库名称</th><th>划分层级</th><th>该层级的描述</th></tr>
    <tr><td>KEGG</td><td>level1</td><td>KEGG 代谢通路第一层级 6 大代谢通路；</td></tr>
    <tr><td>KEGG</td><td>level2</td><td>KEGG 代谢通路第二层级 66 种子 pathway；</td></tr>
    <tr><td>KEGG</td><td>level3</td><td>KEGG pathway id（例：map00010）；</td></tr>
    <tr><td>KEGG</td><td>KO</td><td>KEGG ortholog group (例：K00010)；</td></tr>
    <tr><td>KEGG</td><td>ec</td><td> KEGG EC Number（例：EC 3.4.1.1）；</td></tr>
    <tr><td>KEGG</td><td>module</td><td> KEGG Module Number（例：M00165）；</td></tr>
    <tr><td>eggNOG</td><td>level1</td><td>24 大功能类；</td></tr>
    <tr><td>eggNOG</td><td>level2</td><td>ortholog group description；</td></tr>
    <tr><td>eggNOG</td><td>og</td><td>ortholog group ID(例：ENOG410YU5S)；</td></tr>
    <tr><td>CAZy</td><td>level1</td><td>6 大功能类；</td></tr>
    <tr><td>CAZy</td><td>level2</td><td>CAZy family（例：GT51）；</td></tr>
    <tr><td>CAZy</td><td>level3</td><td>EC number（例：murein polymerase (EC 2.4.1.129)）；</td></tr>
    </tbody>
    </table>
    </div>
    </br>
    <p class="paragraph">4）从功能注释结果及基因丰度表出发，获得各个样品在各个分类层级上的基因数目表，对于某个功能在某个样品中的基因数目，等于在注释为该功能的基因中，丰度不为 0 的基因数目；</p>
    <p class="paragraph">5）从各个分类层级上的丰度表出发，进行注释基因数目统计，相对丰度概况展示，丰度聚类热图展示，PCA和NMDS降维分析，基于功能丰度的Anosim组间（内）差异分析，代谢通路比较分析，组间功能差异的Metastat和LEfSe分析。</p>';

	#Show gene number
    if(${$description}{'注释基因数目统计'}){
        $mulu2description .=
    '<a name="'.${$description}{'注释基因数目统计'}.' 注释基因数目统计"></a><h4>'.${$description}{'注释基因数目统计'}.' 注释基因数目统计</h4>'.
    '<p class="paragraph">从 Unigenes 注释结果出发，绘制各个数据库的注释基因数目统计图，展示结果如下图所示：</p>'.$num_picts.'
    <p class="name">图 '.${$description}{'注释基因数目统计'}.'.1 各数据库注释基因数目统计图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的 Unigenes 注释数目统计图。条形图上的数字代表注释上的 Unigenes 数目；其余一个坐标轴是各数据库中 level1 各功能类的代码，代码的解释见对应的图例说明。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">各数据库注释基因数目统计图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/*_Anno/*.unigenes.num.{pdf,png}；</p>
    <p class="paragraph">以KEGG为例，统计图见：result/05.FunctionAnnotation/KEGG/KEGG_Anno/kegg.unigenes.num.{pdf,png}。</p>';
    $mulu2description .= '<p class="paragraph">从不同层级的注释基因数目表出发，绘制各个数据库不同层级的注释基因数目统计热图，展示结果如下图所示：</p>'.$genenum_heatmap_picts.'
    <p class="name">图 '.${$description}{'注释基因数目统计'}.'.2 level1 基因数目统计热图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy level1 的 Unigenes 注释数目统计热图。横轴为样品名称；纵轴为不同层级的描述；不同颜色代表 Unigenes 数目的高低。</p>' if $genenum_heatmap_picts;
    }

	#Show top10
    $mulu2description .=
    '<a name="3.5.3 功能相对丰度概况"></a><h4>3.5.3 功能相对丰度概况</h4>'.
    '<p class="paragraph">根据各个数据库的注释结果，绘制了样品（组）在各个数据库中对应层级上的相对丰度统计图。 以各样品在各个数据库中level1 层级上的相对丰度统计图为例展示。其余层级为相对丰度前10的注释结果。</p>'.$rel_picts.'
    <p class="name">图 3.5.3 功能注释在 level1 上的相对丰度柱形图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示。纵轴表示注释到某功能类的相对比例；横轴表示样品名称；各颜色区块对应的功能类别见右侧图例。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">功能注释在 level1 上的相对丰度柱形图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/*_Anno/Unigenes.level1.bar.{svg,png}。</p>
	<p class="paragraph">功能注释在各数据库中各层级相对丰度前10的相对丰度柱形图(样品)见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/top/figure/*.top10.{svg.png}；</p>
    <p class="paragraph">功能注释在各数据库中各层级相对丰度前10的相对丰度柱形图(组)见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/top_group/figure/*.top10.{svg.png}。</p>';

	#Show heatmap
    if(${$description}{'功能相对丰度聚类分析'}){
        $mulu2description.=
    '<a name="'.${$description}{'功能相对丰度聚类分析'}.' 功能相对丰度聚类分析"></a><h4>'.${$description}{'功能相对丰度聚类分析'}.' 功能相对丰度聚类分析</h4>'.
    '<p class="paragraph">根据所有样品在各个数据库中的功能注释及丰度信息，选取丰度排名前 35 的功能及它们在每个样品中的丰度信息绘制热图，并从功能差异层面进行聚类。</p>'.$cluster_picts.'
    <p class="name">图 '.${$description}{'功能相对丰度聚类分析'}.' 功能丰度聚类热图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示。横向为样品信息；纵向为功能注释信息；图中左侧的聚类树为功能聚类树；中间热图对应的值为每一行功能相对丰度经过标准化处理后得到的 Z 值。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">功能丰度聚类热图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/heatmap/*.{pdf,png}。</p>';
    }

	#Show PCA & NMDS
    if(${$description}{'基于功能丰度的降维分析'}){
        $mulu2description.=
    '<a name="'.${$description}{'基于功能丰度的降维分析'}.' 基于功能丰度的降维分析"></a><h4>'.${$description}{'基于功能丰度的降维分析'}.' 基于功能丰度的降维分析</h4>'.
    '<p class="paragraph">基于不同数据库在各个分类层级的功能丰度进行 PCA 和 NMDS 降维分析，如果样品的功能组成越相似，则它们在降维图中的距离越接近。基于KEGG的KO、eggNOG的OG和CAZY 的 Level2 层级的功能丰度进行PCA 和 NMDS 分析的结果展示如下：</p>'."\n".$pca_picts.'
    <p class="name">图 '.${$description}{'基于功能丰度的降维分析'}.' 基于功能丰度的 PCA 和 NMDS 分析结果展示</p>
    <p class="premark">说明：图中从上至下依次为 KEGG, eggNOG, CAZy 的结果展示；a）PCA结果展示，横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示。b）NMDS结果展示，图中的每个点表示一个样品，点与点之间的距离表示差异程度，同一个组的样品使用同一种颜色表示；Stress小于0.2时，表明NMDS分析具有一定的可靠性。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">标注样品名的PCA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCA/*/PCA12.{png,pdf}；</p>
    <p class="paragraph">未标注样品名的PCA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCA/*/PCA12_2.{png,pdf}；</p>
    <p class="paragraph">未标示样品名称的带聚类圈的PCA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCA/*/PCA12_with_cluster_2.{png,pdf}；</p>
    <p class="paragraph">标示样品名称的带聚类圈的PCA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCA/*/PCA12_with_cluster.{png,pdf}；</p>
    <p class="paragraph">各个主成分分析结果见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCA/*/pca.csv；</p>
    <p class="paragraph">标注样品名的NMDS图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/NMDS/*/NMDS12.{png,pdf}；</p>
    <p class="paragraph">未标注样品名的NMDS图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/NMDS/*/ NMDS12_2.{png,pdf}；</p>
	<p class="paragraph">未标示样品名称的带聚类圈的NMDS图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/NMDS/*/NMDS_withcluster_2.{png,pdf}；</p>
    <p class="paragraph">标示样品名称的带聚类圈的NMDS图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/NMDS/*/NMDS_withcluster.{png,pdf}；</p>
    <p class="paragraph">各样品在两个主成分轴上的位置坐标见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/NMDS/*/NMDS_scores.txt。</p>';
    }

	#Show PCoA
    if(${$description}{'基于功能丰度的Bray-Curtis 距离的降维分析'}){
        $mulu2description.=
    '<a name="'.${$description}{'基于功能丰度的Bray-Curtis 距离的降维分析'}.' 基于功能丰度的Bray-Curtis 距离的降维分析"></a><h4>'.${$description}{'基于功能丰度的Bray-Curtis 距离的降维分析'}.' 基于功能丰度的Bray-Curtis 距离的降维分析</h4>'.
    '<p class="paragraph">基于不同数据库在各个分类层级的功能丰度计算Bray-Curtis 距离，然后进行 PCoA 分析，如果样品的功能组成越相似，则它们在降维图中的距离越接近。基于KEGG、eggNOG和CAZY 的 Level1 层级的功能丰度进行PCoA 分析的结果展示如下：</p>'."\n".$pcoa_picts.'
    <p class="name">图 '.${$description}{'基于功能丰度的Bray-Curtis 距离的降维分析'}.' 基于功能丰度的Bray-Curtis 距离的PCoA分析结果展示</p>
    <p class="premark">说明：图中从上至下依次为 KEGG, eggNOG, CAZy 的结果展示；PCoA结果展示，横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">标注样品名的PCoA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCoA/*/PCoA12.{png,pdf}；</p>
    <p class="paragraph">未标注样品名的PCoA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCoA/*/PCoA12_2.{png,pdf}；</p>
	<p class="paragraph">标示样品名称的带聚类圈的PCoA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCoA/*/PCoA12_withcluster.{png,pdf}；</p>
    <p class="paragraph">未标示样品名称的带聚类圈的PCoA图见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCoA/*/PCoA12_withcluster_2.{png,pdf}；</p>
    <p class="paragraph">各个主成分分析结果见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/PCoA/*/PCoA.csv。</p>';
    }

	#Show Anosim
	if(${$description}{'基于功能丰度的Anosim分析'}){
	    $mulu2description.=
    '<a name="'.${$description}{'基于功能丰度的Anosim分析'}.' 基于功能丰度的Anosim分析"></a><h4>'.${$description}{'基于功能丰度的Anosim分析'}.' 基于功能丰度的Anosim分析</h4>'.
    '<p class="paragraph">基于KEGG的KO、eggNOG的Level1和CAZY 的 Level2 层级的功能丰度进行Anosim 分析，用于检验基于功能丰度的组间差异是否显著大于组内差异。结果展示如下：</p>'.$anosim_picts.'
    <p class="name">图 '.${$description}{'基于功能丰度的Anosim分析'}.' 基于功能丰度的 Anosim 分析</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示，横向为分组信息，纵向为距离信息。Between为两组合并信息，between中位线高于另外两组中位线为分组信息较好。R-value介于（-1，1）之间，R-value大于0，说明组间差异显著。R-value小于0，说明组内差异大于组间差异，统计分析的可信度用 P-value 表示，P< 0.05 表示统计具有显著性。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">Anosim分析结果见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/Anosim。</p>';	
	}
	
	#Show cluster tree 
    if(${$description}{'基于功能丰度的样品聚类分析'}){
        $mulu2description.=
    '<a name="'.${$description}{'基于功能丰度的样品聚类分析'}.' 基于功能丰度的样品聚类分析"></a><h4>'.${$description}{'基于功能丰度的样品聚类分析'}.' 基于功能丰度的样品聚类分析</h4>'.
    '<p class="paragraph">为了研究不同样品的相似性，还可以通过对样品进行聚类分析，构建样品的聚类树。<a href="http://en.wikipedia.org/wiki/Bray%E2%80%93Curtis_dissimilarity" target="_blank" >Bray-Curtis 距离</a>是系统聚类法中使用最普遍的一个距离指标，它主要用来刻画样品间的相近程度，它的大小是进行样品分类的主要依据。</p>
    <p class="paragraph">从各个数据库的功能丰度表出发，以 Bray-Curtis 距离矩阵进行样品间聚类分析，并将聚类结果与各样品在各数据库第一层级上的功能相对丰度整合展示。 </p>'.$circ_picts.'    
    <p class="name">图 '.${$description}{'基于功能丰度的样品聚类分析'}.' 基于Bray-Curtis距离的聚类树</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示。图左侧是 Bray-Curtis 距离聚类树结构；右侧为各层是各样品在第一层级上的功能相对丰度分布。</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">基于Bray-Curtis距离的聚类树见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/*_Anno/Unigenes.level1.bar.tree.{svg,png}。</p>';    
    }

	#Show pathwaymaps
    if(${$description}{'代谢通路比较分析'}){
        $mulu2description.=
    '<a name="'.${$description}{'代谢通路比较分析'}.' 代谢通路比较分析"></a><a href = "src\pictures\05.FunctionAnnotation\pathwaymaps\KEGG_ReadMe.pdf" target="_blank" title = "点击查看KEGG数据库使用手册" data-toggle="tooltip" ><h3>'.${$description}{'代谢通路比较分析'}.' 代谢通路比较分析 &nbsp;>> </h3></a>'.
    '<p class="paragraph">为了研究不同分组（不同样品）在代谢通路图中的差异，绘制了代谢通路网页版结果展示，整体网页版报告分为两部分：</p>
    <p class="paragraph">第一部分为 KEGG 9 大 pathway overview 图，图中，展示了两个分组（或两个样品）共有及特有的代谢通路信息，在代谢通路图中，节点代表各种化合物，边代表一系列的酶类反应，红色代表两个分组（或两个样品）共有的酶类反应，蓝色代表分组 A（或样品 A）独有的酶类反应，绿色代表分组 B（或样品 B）独有的酶类反应；</p>
    <p class="paragraph">第二部分为注释到的 pathway 代谢通路图，在代谢通路图中，节点代表各种化合物, 方框代表酶类信息（默认边框为黑色，背景为白色），不同颜色的方框代表注释为该酶类的不同 Unigenes 数目，黄色背景的酶类代表在分组间具有显著差异的酶类（若没有进行显著差异分析，则没有此部分信息），鼠标移动至该酶类，可显示差异酶类在不同分组间的丰度分布箱图。</p>
    <p class="paragraph"><a href="src/pictures/05.FunctionAnnotation/pathwaymaps/pathway.html" target="_blank" target="_blank">展示结果请点击。</a></p></br></br>'.
    '<p class="center">
            <img  src="src/images/mpath.png" width="60%" height="60%"/>
            </p>'.
    '<p class="name">图 '.${$description}{'代谢通路比较分析'}.' 多样品代谢通路比较分析示例图</p>
    <p class="paragraph">结果目录：</p>
    <p class="paragraph">多样品代谢通路比较分析结果见：result/05.FunctionAnnotation/KEGG/pathwaymaps。</p>';
    }
	
    #Show Metastat
    if(${$description}{'组间功能差异的Metastat分析'}){
        if($show{fun_box}){
		    $mulu2description.=
    '<a name="'.${$description}{'组间功能差异的Metastat分析'}.' 组间功能差异的Metastat分析"></a><h4>'.${$description}{'组间功能差异的Metastat分析'}.' 组间功能差异的Metastat分析</h4>'.
    '<p class="paragraph">为了研究组间具有显著性差异的功能，从不同层级的功能相对丰度表出发，利用 Metastats 方法对组间的功能丰度数据进行假设检验得到 p 值，通过对 p 值的校正，得到 q 值；最后根据 q 值筛选具有显著性差异的功能，并绘制差异功能在组间的丰度分布箱图。</p>'.$metastat_picts.'
    <p class="name">图 '.${$description}{'组间功能差异的Metastat分析'}.'.1 显著性差异功能箱图展示</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示，图中横轴为样品分组，纵向为对应功能的相对丰度。横线代表具有显著性差异的两个分组，没有则表示此功能在两个分组间不存在差异。“＊”表示两组间差异显著（q value < 0.05），“＊＊”表示两组间差异极显著（q value < 0.01）。</p>';
	    }
	    if($show{fun_diff}){
		    $mulu2description.=
    '<p class="paragraph">根据组间具有差异的功能进行PCA分析并绘制丰度聚类热图，展示结果如下:</p>'.$meta_ph_picts.'
    <p class="name">图 '.${$description}{'组间功能差异的Metastat分析'}.'.2 基于显著性差异功能的 PCA 分析和丰度聚类热图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示。a) 为显著性差异功能的丰度聚类热图：横向为样品信息；纵向为功能注释信息；图中左侧的聚类树为功能聚类树；中间热图对应的值为每一行功能相对丰度经过标准化处理后得到的 Z 值；b) 为显著性差异功能的 PCA 图：横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示。</p>';
	    }
        $mulu2description.='<p class="paragraph">结果目录：</p>
        <p class="paragraph">MetaStat分析结果见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/MetaStats。</p>';
    }

    #Show LEfSe
	if(${$description}{'组间功能差异的LEfSe分析'}){
        if($show{fun_lda} && $show{fun_hp}){
		    $mulu2description.=
    '<a name="'.${$description}{'组间功能差异的LEfSe分析'}.' 组间功能差异的LEfSe分析"></a><h4>'.${$description}{'组间功能差异的LEfSe分析'}.' 组间功能差异的LEfSe分析</h4>'.
    '<p class="paragraph">为了筛选组间具有显著差异的功能Biomarker，首先通过秩和检验的方法检测不同分组间的差异功能并通过LDA（线性判别分析）实现降维并评估差异功能的影响大小，即得到LDA score。差异功能的LDA值分布图如下：</p>'."\n".$lda_picts.'
    <p class="name">图 '.${$description}{'组间功能差异的LEfSe分析'}.'.1 差异功能的LDA值分布图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示:LDA值分布柱状图中展示了LDA Score大于设定值（默认设置为3）的功能，即组间具有统计学差异的Biomarker，柱状图的长度代表差异功能的影响大小（即为 LDA Score）。</p>';
	    }
		if($show{fun_hp}){
		    $mulu2description.=
    '<p class="paragraph">基于上述LDA筛选的组间具有差异的功能丰度绘制差异功能的聚类热图以反映这些差异功能在各样品中分布情况。差异功能丰度聚类热图如下：</p>'."\n".$lda_hp_picts.'
    <p class="name">图 '.${$description}{'组间功能差异的LEfSe分析'}.'.2 差异功能的丰度聚类热图</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示:横向为样品信息；纵向为功能注释信息；图中左侧的聚类树为功能聚类树；中间热图对应的值为每一行功能相对丰度经过标准化处理后得到的 Z 值。</p>';		
		}
	    if($show{fun_roc}){
		    $mulu2description.=
    '<p class="paragraph">为了检验通过LDA筛选出来的组间差异Biomarker的分类预测能力，绘制受试者工作特征曲线 （receiver operating characteristic curve，简称ROC曲线），又称为感受性曲线（sensitivity curve）。ROC曲线常用来评价一个二值分类器的好坏，也是基于统计学上判断分组信息优劣的指标。AUC（Area Under Curve）被定义为ROC曲线下的面积。通常情况下，它的值在1.0和0.5之间。在AUC>0.5的情况下，AUC越接近于1，说明分类预测效果越好；基于差异功能的ROC曲线展示结果如下:</p>'.$lda_roc_picts.'
    <p class="name">图 '.${$description}{'组间功能差异的LEfSe分析'}.'.2 基于差异功能的 ROC 曲线</p>
    <p class="premark">说明：从上至下依次为 KEGG, eggNOG, CAZy 的结果展示，图中横坐标为假阳性率，纵坐标为真阳性率，曲线的面积越接近于1表明分类器的效果越好。CI（Confidence interval）：95%的置信区间。</p>';
	    }
        $mulu2description.='<p class="paragraph">结果目录：</p>
        <p class="paragraph">组间功能差异的LEfSe分析结果见：result/05.FunctionAnnotation/KEGG{eggNOG,CAZy}/LDA。</p>';
    }
#Show RandForest ROC
	if(${$description}{'基于功能丰度的RandomForest分析'})
	{
        if($show{fun_show_rf_roc})
		{
		    $mulu2description.='<a name="'.${$description}{'基于功能丰度的RandomForest分析'}. '"></a><h4>' .${$description}{'基于功能丰度的RandomForest分析'}.'基于功能丰度的RandomForest分析</h4>'.'<p class="paragraph">随机森林是一种基于分类树算法的经典机器学习模型，由LeoBreiman（2001）提出，它通过自助法（bootstrap）重采样技术，从原始训练样本集N中有放回地重复随机抽取k个样本生成新的训练样本集合，然后根据自助样本集生成k个分类树组成随机森林，新数据的分类结果按分类树投票多少形成的分数而定。对于建立好的模型,可以通过交叉验证(Cross-validation)或者受试者工作特征曲线（receiver operating characteristic curve，ROC）的方法对模型的性能进行评估。</p>
	<p class="paragraph">在生态学的研究中，随机森林算法主要应用于对两组数据的分类的Biomarker筛选。判断的Biomarker的指标有MeanDecreaseAccuracy和MeanDecreaseGin。MeanDecreaseAccuracy表示随机森林预测准确性的降低程度。该值越大表示该变量的重要性越大。MeanDecreaseGini通过基尼（Gini）指数计算每个变量对分类树每个节点上观测值的异质性的影响，该值越大表示该变量的重要性越大。</p>
<p class="paragraph" >基于功能丰度的随机森林的分析，对不同分类水平，按梯度选取不同数量的物种，构建随机森林模型。通过MeanDecreaseAccuracy和MeanDecreaseGin筛选出重要的功能，之后对每个模型做交叉验证（默认10-fold）并绘制ROC曲线.</p>';

		}
	if($show{fun_cv_auc_point})
	{
		$mulu2description.='<p class="paragraph"></p>
	<p class ="center"> <a href="src/pictures/05.FunctionAnnotation/fun_show_ea.png" target="_blank"><img src="src/pictures/05.FunctionAnnotation/fun_show_ea.png" width="50%" height="50%"/> </a></p>
	<p class="name">图 '.${$description}{'基于功能丰度的RandomForest分析'}.'.1 10-fold交叉验证和ROC曲线对不同功能数目随机森林模型的评估曲线</p>
	<p class="premark">a)Error rate of 10-fold cross Validation，横坐标：功能数目,纵坐标：不同功能数目做10-fold cross_validation的Error rate；b)AUC of Sub_Random Forest，横坐标：功能数目，纵坐标：不同功能数目ROC曲线的AUC值</p>
	<p class="paragraph">结果目录：</p>
	<p class="paragraph">不同功能数目10-fold验证结果见：result/05.FunctionAnnotation/rf_roc/*/*/*/cverrof.png</p>
	<p class="paragraph">不同功能数目ROC曲线结果见：result/05.FunctionAnnotation/rf_roc/*/*/trainset.point_auc.png.png</p>';
	}
	if($show{fun_imp})
	{
	$mulu2description.='<p class="center"><a href="src/pictures/05.FunctionAnnotation/fun_imp.png" target="_blank" ><img src="src/pictures/05.FunctionAnnotation/fun_imp.png " width="50%" height="50%"></a></p>
	<p class="name">图 '.${$description}{'基于功能丰度的RandomForest分析'}.'.2 重要性功能</p>
	<p class="paragraph">结果目录：</p>
	<p class="paragraph">基于MeanDecreaseAccuracy重要性功能结果见：result/05.FunctionAnnotation/rf_roc/*/*/*/impplot_MeanDecreaseAccuracy*.png</p>
	<p class="paragraph">基于MeanDecreaseAccuracy重要性功能结果见：result/05.FunctionAnnotation/rf_roc/*/*/*/impplot_MeanDecreaseGin*.png</p>';
	}
	if($show{fun_show_rf_roc})
	{
		$mulu2description.='<p class="paragraph">为了展示不同分组及不同功能数目下建立的随机森林的模型性能的比较，绘制了如下ROC曲线，展示结果如下图所示：</p>'.$fun_rf_roc_pic.'
<p class="name">图 '.${$description}{'基于功能丰度的RandomForest分析'}.'.3 随机森林模型ROC曲线的比较</p>
<p class="premark">从上至下，依次是，AUC值最大的功能数的构建的随机森林的单个ROC曲线、不同功能数的随机森林模型的ROC曲线、各个分组中AUC值最大的ROC曲线.</p>
<p class="paragraph">结果目录：</p>
<p class="paragraph">单个ROC曲线见：result/05.FunctionAnnotation/rf_roc/*/*/*/trainset.ROC.png</p>
<p class="paragraph">不同功能数的随机森林模型的ROC曲线见：result/05.FunctionAnnotation/rf_roc/*/*/trainset_auc.png</p>
<p class="paragraph">各个分组中AUC值最大的ROC曲线见：result/05.FunctionAnnotation/rf_roc/*/trainset_group_max_roc.png</p>
';
	}
    
	}

	#For ARDB
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.png"){
    `rm -r $report/src/images/06.CARDAnnotation--readme.pdf`;
	if(${$description}{'抗性基因注释'}){
	push @liter,(47,50,51,48,49);
    $mulu2description .=
    '<!----------------------------------------- 抗性基因注释 ------------------------------------------>'.
	'<a name="'.${$description}{'抗性基因注释'}.' 抗性基因注释"></a><a href="src/images/06.ARDBAnnotation--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3>'.${$description}{'抗性基因注释'}.' 抗性基因注释&nbsp;>></h3> </a>'.
    '<p class="paragraph">不管是人肠道微生物还是其他环境微生物中，抗性基因是普遍存在的。抗生素的滥用导致人体和环境中微生物群落发生不可逆的变化，对人体健康和生态环境造成风险，因此抗性基因的相关研究受到了研究者的广泛关注<SUP>['.$i++.']</SUP>。目前，抗生素抗性基因的研究主要利用<a href="http://ardb.cbcb.umd.edu/"  target="_blank" >ARDB</a>（Antibiotic Resistance Genes Database） 数据库<SUP>['.$i++.']</SUP>。通过该数据库的注释，可以找到抗生素抗性基因（Antibiotic Resistance Genes ，ARG）<SUP>['.$i++.']</SUP>及其抗性类型（Antibiotic Resistance Type）以及这些基因所耐受的抗生素种类（ Antibiotic）等信息。</p>';
	    if(${$description}{'抗性基因注释基本步骤'}){
		    $mulu2description .=
			'<a name="'.${$description}{'抗性基因注释基本步骤'}.' 抗性基因注释基本步骤"></a><h4>'.${$description}{'抗性基因注释基本步骤'}.' 抗性基因注释基本步骤</h4>'.
			'<p class="tremark">1）使用DIAMOND软件将 Unigenes 与ARDB数据库进行比对（blastp，evalue ≤ 1e-5）<SUP>['.$i++.','.$i++.']</SUP>；</br>'.			'2）比对结果过滤：对于每一条序列的比对结果，选取identity值大于数据库要求的保证该抗性基因注释结果可靠的最低identity值；</br>'.
			'3）从比对结果出发，统计不同抗性基因的相对丰度</br>'.
			'4）从抗性基因丰度出发，进行丰度柱形图展示，丰度聚类热图展示，组间抗性基因数目差异分析、抗性基因在各样品中丰度分布情况展示，抗性基因物种归属分析及抗性基因的抗性机制分析。</br></p>';
		}
		if(${$description}{'抗性基因丰度概况'}){
		    $mulu2description .=
		    '<a name="'.${$description}{'抗性基因丰度概况'}.' 抗性基因丰度概况"></a><h4>'.${$description}{'抗性基因丰度概况'}.' 抗性基因丰度概况</h4>'.
			'<p class="paragraph">从抗性基因的相对丰度表出发，计算各个样品中抗生素抗性基因的含量和百分比，结果展示如下：</p>'.
			'    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/antibiotic_ardb.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/antibiotic_ardb.png" width="80%" height="80%"/></a>'."\n".
            '    </p>'."\n".
            '    <p class="name">图 '.${$description}{'抗性基因丰度概况'}.'.1 不同抗生素抗性基因在各样品中的丰度柱形图</p>
			<p class="premark">说明：在图例中把抗性基因能耐受两种以上抗生素进行了首字母缩写的形式展现。a）表示抗性基因在各个样品中所有基因的相对丰度，单位 ppm，是将原始相对丰度数据放大 10<SUP>6</SUP>倍的结果；b）表示抗性基因在各个样品中所有抗性基因中的相对丰度。</p>';
		#}
		#if(${$description}{'各样品中抗性基因类型分布比例概览'}){
		    if(-s "$report/src/pictures/05.FunctionAnnotation/circos.png"){
		        $mulu2description .=
		#'<a name="'.${$description}{'各样品中抗性基因类型分布比例概览'}.' 各样品中抗性基因类型分布比例概览"></a><h4>'.${$description}{'各样品中抗性基因类型分布比例概览'}.' 各样品中抗性基因类型分布比例概览</h4>'.
			'<p class="paragraph">为了方便从整体上观察各样品中抗性基因丰度占比，更加直观的展示各抗性基因丰度的整体分布情况，绘制Overview圈图，展示如下：</p>'.
			'    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/circos.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/circos.png" width="45%" height="45%"/></a>'."\n".
            '    </p>'."\n".
            '    <p class="name">图 '.${$description}{'抗性基因丰度概况'}.'.2 抗性基因Overview圈图</p>
			<p class="premark">说明：圈图分为两个部分，右侧为样品信息，左侧为 ARG 耐受的抗生素信息。内圈不同颜色表示不同的样品和 Antibiotic， 刻度为相对丰度， 单位为 ppm， 左侧为样品中抗性基因的相对丰度之和， 右侧为各 Antibiotic 中抗性基因的相对丰度之和； 外圈左侧为各样品中抗性基因其所属的 Antibiotic 的相对百分含量，外圈右侧为各 Antibiotic 中抗性基因其所在的样品的相对百分含量。</p>
            <p class="paragraph">结果目录：</p>
            <p class="paragraph">抗性基因在各个样品中所有基因的相对丰度：result/05.FunctionAnnotation/ARDB/bar_plot/antibiotic.{svg,png}；</p>
            <p class="paragraph">抗性基因在各个样品中所有抗性基因中的相对丰度：result/05.FunctionAnnotation/ARDB/bar_plot/per.antibiotic.{svg.png}；</p>
            <p class="paragraph">抗性基因Overview圈图：result/05.FunctionAnnotation/ARDB/Overview/circos.overview.{svg,png}</a>。</p>';                
		   }
		}
		if(${$description}{'抗性基因类型的分布及其丰度聚类分析'}){
		    $mulu2description .=
		    '<a name="'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析"></a><h4>'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析</h4>'.
			'<p class="paragraph">为了反映各抗性基因类型（ARG） 在各样品中的分布情况，绘制ARG分布的黑白热图；同时，根据 ARG 在各样品中的丰度信息，选取排名前 30 的 ARG绘制丰度聚类热图，结果展示如下：</p>'.
			'    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/arg_heatmap.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/arg_heatmap.png" width="60%" height=60%"/></a>'."\n".
            '    </p>'."\n".
            '    <p class="name">图 '.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' ARG分布及丰度聚类热图</p>
			<p class="premark">说明：a）为ARG分布情况热图，横轴为样品名称，右侧纵轴为抗性基因类型 ARG 名称，左侧纵轴色块为 ARG 所耐受的抗生素；黑色表示样品中含有该 ARG，白色表示样品中没有该 ARG；b）为ARG丰度聚类热图，右侧纵轴为抗性基因类型 ARG 名称，左侧纵轴的聚类树为 ARG聚类树，连接聚类树的色块表示 ARG 所耐受的抗生素，中间热图对应的值为每一行 ARG 相对丰度经过标准化处理后得到的 Z 值。</p>
            <p class="paragraph">结果目录：</p>
            <p class="paragraph">ARG分布情况热图：result/05.FunctionAnnotation/ARDB/heatmap/arg_bw/heatmap.bw.{pdf,png}；</p>
            <p class="paragraph">ARG丰度聚类热图：result/05.FunctionAnnotation/ARDB/heatmap/arg_heat/heatmap.{pdf,png}。</p>';
		}
		if(${$description}{'组间抗性基因数目差异分析'}){
		    $mulu2description .=
		    '<a name="'.${$description}{'组间抗性基因数目差异分析'}.' 组间抗性基因数目差异分析"></a><h4>'.${$description}{'组间抗性基因数目差异分析'}.' 组间抗性基因数目差异分析</h4>'.
			'<p class="paragraph">为了考察样品组间的抗性基因数目与抗性基因类型（ARG）数目差异情况，绘制了组间抗性基因数目和ARG数目差异箱图，展示结果如下</p>'.
			'    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/ardb_box.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/ardb_box.png" width="60%" height="60%"/></a>'."\n".
            '    </p>'."\n".
            '    <p class="name">图 '.${$description}{'组间抗性基因数目差异分析'}.' 抗性基因及ARG数目差异箱图</p>
			<p class="premark">说明：a）表示各组间抗性基因数目差异，b）为各组间ARG数目差异。</p>
            <p class="paragraph">结果目录：</p>
            <p class="paragraph">各组间抗性基因数目差异：result/05.FunctionAnnotation/ARDB/box_plot/Gene_box/group.genebox.{pdf,png}；</p>
            <p class="paragraph">各组间ARG数目差异：result/05.FunctionAnnotation/ARDB/box_plot/Arg_box/group.argbox.{pdf,png}。</p>';
		}
        if(${$description}{'抗性基因与物种归属关系'}){
		    $mulu2description .=
		    '<a name="'.${$description}{'抗性基因与物种归属关系'}.' 抗性基因与物种归属关系"></a><h4>'.${$description}{'抗性基因与物种归属关系'}.' 抗性基因与物种归属关系</h4>'.
			'<p class="paragraph">根据组内所有样品的基因物种注释结果，可以获取组内样品各个抗性基因对应的物种信息，通过比较抗性基因所属的物种信息可以直观的反映哪些物种中存在较多的抗性基因。物种归属结果展示如下：</p>'.
			$arg_taxonomy_pics.
            '    <p class="name">图 '.${$description}{'抗性基因与物种归属关系'}.'.1 抗性基因物种归属分析圈图</p>
			<p class="premark">说明：内圈为 ARG 的物种分布情况，外圈为组内所有样品基因的物种分布情况。</p>';
		#}
		#if(${$description}{'抗性机制分析'}){
		    if (-s "$report/src/pictures/05.FunctionAnnotation/mechanism.png"){
		        $mulu2description .=
		#    '<a name="'.${$description}{'抗性机制分析'}.' 抗性机制分析"></a><h4>'.${$description}{'抗性机制分析'}.' 抗性机制分析</h4>'.
			'<p class="paragraph">另外，ARDB 数据库中对一些重要的抗性基因的作用机制进行了详细的介绍， 这些机制与微生物的新陈代谢活动密切相关，根据这些抗性基因的作用机制与物种的关系，绘制如下抗性机制分布图：</p>'.
			'    <p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/mechanism.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/mechanism.png" width="50%" height="50%"/></a>'."\n".
            '    </p>'."\n".
            '    <p class="name">图 '.${$description}{'抗性基因与物种归属关系'}.'.2 抗性机制与物种关系分布图</p>
			<p class="premark">说明：圈图分为两个部分，右侧为物种信息，左侧为ARG的抗性机制。右侧为物种信息，左侧为抗性基因的抗性机制；内圈不同颜色表示不同物种和抗性的抗性机制，刻度为基因数目；左侧为物种中含有该类抗性机制的抗性基因数目之和，右侧为不同抗性机制中该物种含有的抗性基因数目之和；外圈左侧为各物种中抗性基因占其所属抗性机制抗性基因的相对比例，外圈右侧为各抗性机制中抗性基因占其所属物种中抗性基因的相对比例。</p>
            <p class="paragraph">结果目录：</p>
            <p class="paragraph">抗性基因物种归属分析圈图：result/05.FunctionAnnotation/ARDB/ARDB_Tax/ARG_taxonomy/*..{svg,png}；</p>
            <p class="paragraph">抗性机制与物种关系分布图：result/05.FunctionAnnotation/ARDB /ARG_mechanism/mechanism.taxonomy.{svg,png}。</p>';
			}
		}			
	}	
 }

#For CARD
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_card.png"){
    `rm -r $report/src/images/06.ARDBAnnotation--readme.pdf`;
    if(${$description}{'抗性基因注释'}){
        push @liter,(47,53,54);
        $mulu2description .=
        '<!----------------------------------------- 抗性基因注释 ------------------------------------------>'.
        '<a name="'.${$description}{'抗性基因注释'}.' 抗性基因注释"></a><a href="src/images/06.CARDAnnotation--readme.pdf" target="_blank" title="点击查看交付目录说明文档"  data-toggle="tooltip"> <h3>'.${$description}{'抗性基因注释'}.' 抗性基因注释&nbsp;>></h3> </a>'.
        '<p class="paragraph">不管是人肠道微生物还是其他环境微生物中，抗性基因是普遍存在的。抗生素的滥用导致人体和环境中微生物群落发生不可逆的变化，对人体健康和生态环境造成风险，因此抗性基因的相关研究受到了研究者的广泛关注<SUP>['.$i++.']</SUP>。<a href="https://card.mcmaster.ca/" target="_blank" >CARD</a>是近年来新出现的抗性基因数据库，它具有信息全面，对用户友好，更新维护及时等优势。该数据库的核心构成是Antibiotic Resistance Ontology（ARO），它整合了序列、抗生素抗性、作用机制、ARO之间的关联等信息，并在线提供ARO与PDB、NCBI等数据库的接口<SUP>['.$i++.']</SUP>。</p>';
    if(${$description}{'抗性基因注释基本步骤'}){
        $mulu2description .=
        '<a name="'.${$description}{'抗性基因注释基本步骤'}.' 抗性基因注释基本步骤"></a><h4>'.${$description}{'抗性基因注释基本步骤'}.' 抗性基因注释基本步骤</h4>'.
        '<p class="tremark">1）使用CARD数据库提供的Resistance Gene Identifier (RGI)软件将 Unigenes 与CARD数据库进行比对（RGI内置blastp，默认evalue ≤ 1e-30<SUP>['.$i++.']</SUP>）；</br>'. 
        '2）根据RGI的比对结果，结合Unigenes的丰度信息，统计出各ARO的相对丰度；</br>'.
        '3）从ARO的丰度出发，进行丰度柱形图展示，丰度聚类热图展示，丰度分布圈图展示，组间ARO差异分析，抗性基因（注释到ARO的unigenes）物种归属分析等（对部分名称较长的ARO，用其前三个单词与下划线缩写的形式展示）。</br></p>';
        }
    if(${$description}{'抗性基因丰度概况'}){
        $mulu2description .=
        '<a name="'.${$description}{'抗性基因丰度概况'}.' 抗性基因丰度概况"></a><h4>'.${$description}{'抗性基因丰度概况'}.' 抗性基因丰度概况</h4>'.
        '<p class="paragraph">从抗性基因的相对丰度表出发，计算各个样品中ARO的含量和百分比，筛选出最大丰度排名前20的ARO结果展示如下：</p>'.
        '<p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/antibiotic_card.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/antibiotic_card.png" width="80%" height="80%"/></a>'."\n".
        '</p>'."\n".
        '<p class="name">图 '.${$description}{'抗性基因丰度概况'}.'.1 不同ARO在各样品中的丰度柱形图</p>
        <p class="premark">a）表示ARO在各个样品中所有基因的相对丰度，单位 ppm，是将原始相对丰度数据放大10<SUP>6</SUP>倍的结果；b）表示top20 ARO在所有 ARO中的相对丰度，others为非top 20 ARO相对丰度总和。</p>';
        if(-s "$report/src/pictures/05.FunctionAnnotation/circos.png"){
            $mulu2description .=
            '<p class="paragraph">为了更直观地从整体上观察各样品中ARO的丰度占比，更加直观的展示各ARO丰度的整体分布情况，选出最大丰度top10的ARO绘制Overview圈图，展示如下：</p>'.
            '<p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/circos.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/circos.png" width="45%" height="45%"/></a>'."\n".
            '</p>'."\n".
            '<p class="name">图 '.${$description}{'抗性基因丰度概况'}.'.2 抗性基因Overview圈图</p>
            <p class="premark">说明：圈图分为两个部分，右侧为样品信息，左侧为 ARO信息。内圈不同颜色表示不同的样品和 ARO，刻度为相对丰度，单位为 ppm，左侧为某ARO各个样本中的相对丰度之和，右侧为各ARO在某样本中的相对丰度之和；外圈左侧为某ARO中各个样品的相对百分含量，外圈右侧为某样品中各ARO的相对百分含量。</p>';
            }
            $mulu2description .=
            '<p class="paragraph">结果目录：</p>
            <p class="paragraph">top20 的 ARO 在各样品的相对丰度：result/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.ppm.{png,svg}；</p>
            <p class="paragraph">top20 的 ARO 在各样品的相对百分含量：result/05.FunctionAnnotation/CARD/stat_result/bar/stat.ARO.RelativePercent.{png,svg}；</p>
            <p class="paragraph">top10 的 ARO 在各样品中相对丰度：result/05.FunctionAnnotation/CARD/stat_result/circos/。</p>' if(-s "$report/src/pictures/05.FunctionAnnotation/circos.png");
        }
if(${$description}{'基于抗性基因丰度的Anosim分析'}){
	$mulu2description.='
	<a name = "'.${$description}{'基于抗性基因丰度的Anosim分析'}.' 基于抗性基因丰度的Anosim分析"></a><h4>3.6.4 基于抗性基因丰度的Anosim分析</h4>
<p class="paragraph">基于抗性基因的丰度进行Anosim 分析，用于检验组间差异是否显著大于组内差异。结果展示如下：</p>

<p class="center"><a href="src/pictures/05.FunctionAnnotation/card_anosim_show.png" target="_blank"><img src="src/pictures/05.FunctionAnnotation/card_anosim_show.png" width="50%" height="50%"/></a></p>
<p class="name">图 '.${$description}{'基于抗性基因丰度的Anosim分析'}.'基于抗性基因丰度的Anosim分析</p>
<p class="premark">说明：横向为分组信息，纵向为距离信息。Between为两组合并信息，between中位线高于另外两组中位线为分组信息较好。R-value介于（-1，1）之间，R-value大于0，说明组间差异显著。R-value小于0，说明组内差异大于组间差异，统计分析的可信度用 P-value 表示，P< 0.05 表示统计具有显著性。</p>
<p class="paragraph">结果目录:</p>
<p class="paragraph">Anosim分析结果：result/05.FunctionAnnotation/CARD/stat_result/Anosim/ARO</p>'
}
		
		
if(${$description}{'抗性基因类型的分布及其丰度聚类分析'}){
    if(-s "$resultdir/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_bw/bw.png"){
            $mulu2description .=
        '<a name="'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析"></a><h4>'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析</h4>'.
            '<p class="paragraph">为了反映各抗性基因类型（ARO） 在各样品中的分布情况，绘制ARO分布的黑白热图；同时，根据 ARO 在各样品中的丰度信息，选取排名前 30 的 ARO绘制丰度聚类热图，结果展示如下：</p>'.
            '<p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/aro_heatmap.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/aro_heatmap.png" width="60%" height="60%"/></a>'."\n".
            '</p>'."\n".
            '<p class="name">图 '.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' ARO分布及丰度聚类热图</p>
            <p class="premark">说明：a）为ARO分布情况热图，横轴为样品名称，右侧纵轴为抗性基因类型 ARO 名称，黑色表示样品中含有该 ARO，白色表示样品中没有该 ARO；b）为ARO丰度聚类热图，右侧纵轴为ARO 名称，左侧纵轴的聚类树为 ARO聚类树，中间热图对应的值为每一行 ARO 相对丰度经过标准化处理后得到的 Z 值。</p>
            <p class="paragraph">结果目录：</p>
            <p class="paragraph">ARO丰度聚类热图：result/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/；</p>
            <p class="paragraph">ARO分布情况：result/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_bw/。</p>';
    }else{
           $mulu2description .=
    '<a name="'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析"></a><h4>'.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' 抗性基因类型的分布及其丰度聚类分析</h4>'.
          '<p class="paragraph">为了反映各抗性基因类型（ARO） 在各样品中的分布情况，根据 ARO 在各样品中的丰度信息，选取排名前 30 的 ARO绘制丰度聚类热图，结果展示如下：</p>'.
          '<p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/aro_heatmap.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/aro_heatmap.png" width="50%" height="50%"/></a>'."\n".
          '</p>'."\n".
          '<p class="name">图 '.${$description}{'抗性基因类型的分布及其丰度聚类分析'}.' ARO分布及丰度聚类热图</p>
          <p class="premark">说明：右侧纵轴为ARO 名称，左侧纵轴的聚类树为 ARO聚类树，中间热图对应的值为每一行 ARO 相对丰度经过标准化处理后得到的 Z 值。</p>
          <p class="paragraph">结果目录：</p>
          <p class="paragraph">ARO丰度聚类热图：result/05.FunctionAnnotation/CARD/stat_result/heatmap/aro_heat/。</p>';
        }
    }

	
    if(${$description}{'组间抗性基因数目差异分析'}){
        $mulu2description .=
        '<a name="'.${$description}{'组间抗性基因数目差异分析'}.' 组间抗性基因数目差异分析"></a><h4>'.${$description}{'组间抗性基因数目差异分析'}.' 组间抗性基因数目差异分析</h4>'.
        '<p class="paragraph">为了考察样品组间的抗性基因数目与ARO数目差异情况，绘制了组间抗性基因数目和ARO数目差异箱图，展示结果如下:</p>'.
        '<p class="center">'."\n".'<a href="src/pictures/05.FunctionAnnotation/card_box.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/card_box.png" width="60%" height="60%"/></a>'."\n".
        '</p>'."\n".
        '<p class="name">图 '.${$description}{'组间抗性基因数目差异分析'}.'.1 抗性基因及ARO数目差异箱图</p>
        <p class="premark">说明：a）表示各组间抗性基因数目差异，b）为各组间ARO数目差异。</p>';
		 if(-s "$report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png")
			{
			$mulu2description.=
			'<p class="paragraph">为了考察指定样品（组）间的抗性基因数目分布情况，分析不同样品（组）之间的基因共有、特有信息，绘制了韦恩图(或花瓣图)，展示结果如下:</p>
			<p class="center" ><a href="src/pictures/05.FunctionAnnotation/card_venn_flower_display.png" target="_blank" ><img src="src/pictures/05.FunctionAnnotation/card_venn_flower_display.png" width="45%" height="45%" /></a></p>
			<p class="name">图 '.${$description}{'组间抗性基因数目差异分析'}.'.2 各样品（组间）抗性基因箱韦恩图（花瓣图）分析</p>
			<p class="premark">说明：当样本（组）数小于5时，展示韦恩图，当样本（组）数超过5个时，展示花瓣图；图中，每个圈代表一个样品；圈和圈重叠部分的数字代表样品之间共有的抗性基因个数；没有重叠部分的数字代表样品的特有抗性基因个数。</p>';      
			}
        $mulu2description.=
		'<p class="paragraph">结果目录：</p>
        <p class="paragraph">各组间抗性基因数目差异：result/05.FunctionAnnotation/CARD/stat_result/box/genebox/；</p>
        <p class="paragraph">各组间ARO数目差异：result/05.FunctionAnnotation/CARD/stat_result/box/arobox/；</p>';
		$mulu2description.= '<p class="paragraph">各样本（组）间抗性基因韦恩图(花瓣图)：result/05.FunctionAnnotation/CARD/stat_result/venn_flower；</p>' if(-s "$report/src/pictures/05.FunctionAnnotation/card_venn_flower_display.png");	
        }
	if(${$description}{'组间差异抗性基因的Metastat分析'})
	{
		$mulu2description.='<a name="'.${$description}{'组间差异抗性基因的Metastat分析'}.' 组间差异抗性基因的Metastat分析"></a>
<h4>3.6.6 组间差异抗性基因的Metastat分析</h4>
<p class="paragraph">为了研究组间具有显著性差异的抗性基因，利用 Metastats 方法对组间的抗性基因丰度数据进行假设检验得到 p 值，通过对 p 值的校正，得到 q 值；最后根据 q 值筛选具有显著性差异的抗性基因，并绘制差异抗性基因在组间的丰度分布箱图。</p>	
<p class="center"><a href= "src/pictures/05.FunctionAnnotation/CAZy.top.12.png" target="_blank"><img src="src/pictures/05.FunctionAnnotation/CAZy.top.12.png" width="50%" height="50%"></a></p>
<p class="name">图 '.${$description}{'组间差异抗性基因的Metastat分析'}.' 显著性差异抗性基因箱图展示</p>
<p class="premark">说明：图中横轴为样品分组，纵向为抗性基因的相对丰度。横线代表具有显著性差异的两个分组，没有则表示此抗性基因在两个分组间不存在差异。“＊”表示两组间差异显著（q value < 0.05），“＊＊”表示两组间差异极显著（q value < 0.01）。</p>
<p class="paragraph">结果目录</p>
<p class="paragraph">MetaStat分析结果：result/05.FunctionAnnotation/CARD/stat_result/Metastats/ARO</p>'
	}
	if(${$description}{'组间差异抗性基因的Lefse分析'})
	{
		if (-s "$report/src/pictures/05.FunctionAnnotation/card_lda_bar.png")
		{
			$mulu2description.='
			<a name="'.${$description}{'组间差异抗性基因的Lefse分析'}.' 组间差异抗性基因的Lefse分析"></a><h4>3.6.7 组间差异抗性基因的Lefse分析</h4>
			<p class="paragraph">为了筛选组间具有显著差异的抗性基因Biomarker，首先通过秩和检验的方法检测不同分组间的抗性基因，并通过LDA（线性判别分析）实现降维并评估差异抗性基因的影响大小，即得到LDA score。差异功能的LDA值分布图如下：</p>
<p class="center"><a href= "src/pictures/05.FunctionAnnotation/card_lda_bar.png" target="_blank"><img src="src/pictures/05.FunctionAnnotation/card_lda_bar.png" width="50%" height="50%"></a></p>
<p class="name">图 '.${$description}{'组间差异抗性基因的Lefse分析'}.'.1 差异抗性基因的LDA值分布图</p>
<p class="premark">说明：LDA值分布柱状图中展示了LDA Score大于设定值（默认设置为2）的抗性基因，即组间具有统计学差异的Biomarker，柱状图的长度代表差异抗性基因的影响大小（即为 LDA Score）。</p>'
		}
		if(-s "$report/src/pictures/05.FunctionAnnotation/card_lda_heatmap.png" )
		{
			$mulu2description.='<p class="paragraph">基于上述LDA筛选的组间具有差异的抗性基因相对丰度，绘制差异抗性基因的聚类热图以反映这些差异功能在各样品中分布情况。差异抗性基因丰度聚类热图如下：</p>
<p class="paragraph"></p>
<p class="center"><a href="src/pictures/05.FunctionAnnotation/card_lda_heatmap.png" target="_blank"><img src="src/pictures/05.FunctionAnnotation/card_lda_heatmap.png" width="50%" height="50%"></a></p>
<p class="name">图 '.${$description}{'组间差异抗性基因的Lefse分析'}.'.2 差异抗性基因的的丰度聚类热图</p>
<p class="premark">说明：横向为样品信息；纵向为抗性基因注释信息；图中左侧的聚类树；中间热图对应的值为每一行抗性基因相对丰度经过标准化处理后得到的 Z 值。</p>'
		
		}
	$mulu2description.='<p class="paragraph">结果目录：</p>		
<p class="paragraph">LEfSe分析结果：result/05.FunctionAnnotation/CARD/stat_result/LDA/ARO</p>'
		
		
	}
	
		
    if(${$description}{'抗性基因与物种归属关系'}){
        $mulu2description .=
        '<a name="'.${$description}{'抗性基因与物种归属关系'}.' 抗性基因与物种归属关系"></a><h4>'.${$description}{'抗性基因与物种归属关系'}.' 抗性基因与物种归属关系</h4>'.
        '<p class="paragraph">根据组内所有样品的物种注释结果，可以获取组内样品各个抗性基因对应的物种信息，通过比较抗性基因所属的物种信息可以直观的反映哪些物种中存在较多的抗性基因。物种归属结果展示如下：</p>'.
        $arg_taxonomy_pics.
        '<p class="name">图 '.${$description}{'抗性基因与物种归属关系'}.'.1 抗性基因物种归属分析圈图</p>
        <p class="premark">说明：内圈为 ARO 的物种分布情况，外圈为组内所有样品基因的物种分布情况。</p>
        <p class="paragraph">结果目录：</p>
        <p class="paragraph">抗性基因物种归属分析圈图：result/05.FunctionAnnotation/CARD/stat_result/twocircle/。</p>';
        }
    }
 }
    return($return,$mulu2description,\@liter);
}


sub get_literature{
        my @literature= @_;
        my $get_literature;
        my %literature=(
            '1','Handelsman, J., Rondon, M. R., Brady, S. F., Clardy, J., & Goodman, R. M. (1998). Molecular biological access to the chemistry of unknown soil microbes: a new frontier for natural products. Chemistry & biology, 5(10), R245-R249.',
            '2','Chen, K., & Pachter, L. (2005). Bioinformatics for whole-genome shotgun sequencing of microbial communities. PLoS computational biology, 1(2), e24.',
            '3','Tringe, S. G., & Rubin, E. M. (2005). Metagenomics: DNA sequencing of environmental samples. Nature reviews genetics, 6(11), 805-814.',
            '4','Tringe, S. G., Von Mering, C., Kobayashi, A., Salamov, A. A., Chen, K., Chang, H. W., ... & Rubin, E. M. (2005). Comparative metagenomics of microbial communities. Science, 308(5721), 554-557.',
            '6','Raes, J., Foerstner, K. U., & Bork, P. (2007). Get the most out of your metagenome: computational analysis of environmental sequence data. Current opinion in microbiology, 10(5), 490-498.',
            '7','Luo et al.: SOAPdenovo2: an empirically improved memory-efficient short-read de novo assembler. GigaScience 2012 1:18.',
            '8','Mende D R, Waller A S, Sunagawa S, et al. Assessment of metagenomic assembly using simulated next generation sequencing data[J]. PloS one, 2012, 7(2): e31386.',
            '10','Nielsen H B, Almeida M, Juncker A S, et al. Identification and assembly of genomes and genetic elements in complex metagenomic samples without using reference genomes[J]. Nature biotechnology, 2014, 32(8): 822-828.',
            '11','Li W, Godzik A: Cd-hit: a fast program for clustering and comparing large sets of protein or nucleotide sequences. Bioinformatics 2006, 22(13):1658-1659.',
            '12','Fu L, Niu B, Zhu Z, Wu S, Li W: CD-HIT: accelerated for clustering the next-generation sequencing data. Bioinformatics 2012, 28(23):3150-3152.',
            '13','Karlsson FH, Tremaroli V, Nookaew I, Bergstrom G, Behre CJ, Fagerberg B, Nielsen J, Backhed F: Gut metagenome in European women with normal, impaired and diabetic glucose control. Nature 2013, 498(7452):99-103.',
            '15','Huson, Daniel H., et al. "Integrative analysis of environmental sequences using MEGAN4." Genome research 21.9 (2011): 1552-1560.',
            '16','Ondov B D, Bergman N H, Phillippy A M. Interactive metagenomic visualization in a Web browser[J]. BMC bioinformatics, 2011, 12(1): 385.',
            '17','Yok NG, Rosen GL: Combining gene prediction methods to improve metagenomic gene annotation. BMC Bioinformatics 2011, 12:20.',
            '18','Zhu, Wenhan, Alexandre Lomsadze, and Mark Borodovsky. "Ab initio gene identification in metagenomic sequences." Nucleic acids research 38.12 (2010): e132-e132',
            '19','Arumugayym M, Raes J, Pelletier E, et al. Enterotypes of the human gut microbiome[J]. nature, 2011, 473(7346): 174-180.',
            '20','Kanehisa M, Goto S, Kawashima S, Okuno Y, Hattori M (2004). The KEGG resource for deciphering the genome. Nucleic Acids Res 32 (Database issue): D277–80.',
            '21','Kanehisa M, Goto S, Hattori M, Aoki-Kinoshita KF, Itoh M, Kawashima S, et al. (2006). From genomics to chemical genomics: new developments in KEGG. Nucleic Acids Res 34(Database issue): D354–7.',
            '22','Powell S, Forslund K, Szklarczyk D, et al (2014). eggNOG v4.0: nested orthology inference across 3686 organisms. Nucleic Acids Res 42 (Database issue): D231–239.',
            '23','Cantarel BL, Coutinho PM, Rancurel C, Bernard T, Lombard V, Henrissat B (2009) .The Carbohydrate-Active EnZymes database (CAZy): an expert resource for Glycogenomics. Nucleic Acids Res 37:D233-238.',
            '24','Letunic I, Yamada T, Kanehisa M, et al. iPath: interactive exploration of biochemical pathways and networks[J]. Trends in biochemical sciences, 2008, 33(3): 101-103.',
            '25','Yamada T, Letunic I, Okuda S, et al. iPath2. 0: interactive pathway explorer[J]. Nucleic acids research, 2011, 39(suppl 2): W412-W415.',
            '26','Avershina, Ekaterina, Trine Frisli, and Knut Rudi. De novo Semi-alignment of 16S rRNA Gene Sequences for Deep Phylogenetic Characterization of Next Generation Sequencing Data. Microbes and Environments 28.2 (2013): 211-216.',
            '27','Feng Q, Liang S, Jia H, et al. Gut microbiome development along the colorectal adenoma–carcinoma sequence[J]. Nature communications, 2015, 6.',
            '28','Qin N, Yang F, Li A, et al. Alterations of the human gut microbiome in liver cirrhosis[J]. Nature, 2014.',
            '29','Scher J U, Sczesnak A, Longman R S, et al. Expansion of intestinal Prevotella copri correlates with enhanced susceptibility to arthritis[J]. Elife, 2013, 2: e01202.',
            '30','Brum J R, Ignacio-Espinoza J C, Roux S, et al. Patterns and ecological drivers of ocean viral communities[J]. Science, 2015, 348(6237): 1261498.',           
            '31','Karlsson F H, Fåk F, Nookaew I, et al. Symptomatic atherosclerosis is associated with an altered gut metagenome[J]. Nature communications, 2012, 3: 1245.',
            '32','Qin J, Li R, Raes J, et al. A human gut microbial gene catalogue established by metagenomic sequencing[J]. nature, 2010, 464(7285): 59-65.',
            '33','Zeller G, Tap J, Voigt A Y, et al. Potential of fecal microbiota for early‐stage detection of colorectal cancer[J]. Molecular systems biology, 2014, 10(11): 766.',
            '34','Sunagawa S, Coelho L P, Chaffron S, et al. Structure and function of the global ocean microbiome[J]. Science, 2015, 348(6237): 1261359.',
            '35','Li J, Jia H, Cai X, et al. An integrated catalog of reference genes in the human gut microbiome[J]. Nature biotechnology, 2014, 32(8): 834-841.',
            '36','Oh J, Byrd A L, Deming C, et al. Biogeography and individuality shape function in the human skin metagenome[J]. Nature, 2014, 514(7520): 59-64.',
            '37','Qin J, Li Y, Cai Z, et al. A metagenome-wide association study of gut microbiota in type 2 diabetes[J]. Nature, 2012, 490(7418): 55-60.',
            '38','Villar E, Farrant G K, Follows M, et al. Environmental characteristics of Agulhas rings affect interocean plankton transport[J]. Science, 2015, 348(6237): 1261447.',
            '39','Cotillard A, Kennedy S P, Kong L C, et al. Dietary intervention impact on gut microbial gene richness[J]. Nature, 2013, 500(7464): 585-588.',
            '40','Le Chatelier E, Nielsen T, Qin J, et al. Richness of human gut microbiome correlates with metabolic markers[J]. Nature, 2013, 500(7464): 541-546.',
            '41','White J R, Nagarajan N, Pop M. Statistical methods for detecting differentially abundant features in clinical metagenomic samples[J]. PLoS Comput Biol, 2009, 5(4): e1000352.',
            '42','Kanehisa, M., Goto, S., Sato, Y., Kawashima, M., Furumichi, M., and Tanabe, M.; Data, information, knowledge and principle: back to metabolism in KEGG. Nucleic Acids Res. 42, D199–D205 (2014).',
            '43','Powell S, Forslund K, Szklarczyk D, et al. eggNOG v4. 0: nested orthology inference across 3686 organisms[J]. Nucleic acids research, 2013: gkt1253.',
            '44','Bäckhed F, Roswall J, Peng Y, et al. Dynamics and Stabilization of the Human Gut Microbiome during the First Year of Life[J]. Cell host & microbe, 2015, 17(5): 690-703.',
            '45','Buchfink B, Xie C, Huson DH. Fast and sensitive protein alignment using DIAMOND. Nat Methods 2015;12:59-60.',
			'46','Rivas M N, Burton O T, Wise P, et al. A microbiota signature associated with experimental food allergy promotes allergic sensitization and anaphylaxis[J]. Journal of Allergy & Clinical Immunology, 2013, 131(1):201-212.',
			'47','Martínez J L, Coque T M, Baquero F. What is a resistance gene? Ranking risk in resistomes[J]. Nature Reviews Microbiology, 2014, 13(2):116-23.',
			'48','Yang Y, Li B, Ju F, et al. Exploring Variation of Antibiotic Resistance Genes in Activated Sludge over a Four-Year Period through a Metagenomic Approach[J]. Environmental Science & Technology, 2013, 47(18):10197-10205.',
			'49','Fang H, Wang H, Cai L, et al. Prevalence of antibiotic resistance genes and bacterial pathogens in long-term manured greenhouse soils as revealed by metagenomic survey.[J]. Environmental Science & Technology, 2015, 49(2).',
			'50','Liu B, Pop M. ARDB—Antibiotic Resistance Genes Database[J]. Nucleic Acids Research, 2009, 37(Database issue):D443-7.',
			'51','Forsberg K J, Patel S, Gibson M K, et al. Bacterial phylogeny structures soil resistomes across habitats.[J]. Nature, 2014, 509(7502):612-616.',
			'52','Segata N, Izard J, Waldron L, et al. Metagenomic biomarker discovery and explanation[J]. Genome Biology, 2011, 12(6):1-18.',
            '53','Jia B, Raphenya A R, Alcock B, et al. CARD 2017: expansion and model-centric curation of the comprehensive antibiotic resistance database[J]. Nucleic Acids Research, 2017, 45(D1):D566.',
            '54','Mcarthur A G, Waglechner N, Nizam F, et al. The Comprehensive Antibiotic Resistance Database[J]. Antimicrobial Agents & Chemotherapy, 2013, 57(7):3348.',
			
        );
        my $num;
        foreach my $m (@literature){
                $num++;
                $get_literature .= "[$num]  $literature{$m}<br />\n";
        }
        return $get_literature;
}

sub get_part{
    my($part,$liter)=@_;
    my $l=1;
    my %liter;
    foreach my $li (@{$liter}){
        $liter{$li}=$l;
        $l++;
    }
    my@part;
    foreach my $pa (@{$part}){
        push @part,$liter{$pa};
    }
    return @part;
}

sub digitize() {
    for (@_){
    $_ =~ s/(?<=^\d)(?=(\d\d\d)+$)    #处理不含小数点的情况^M
            |
            (?<=^\d\d)(?=(\d\d\d)+$)  #处理不含小数点的情况^M
            |
            (?<=\d)(?=(\d\d\d)+\.)    #处理整数部分^M
            |
            (?<=\.\d\d\d)(?!$)        #处理小数点后面第一次千分位^M
            |
            (?<=\G\d\d\d)(?!\.|$)     #处理小数点后第一个千分位以后的内容，或者不含小数点的情况^M
            /,/gx;
#    return $_;
    }
}

sub get_table_descri{
    my($table_array,$table_hash,$head,$description,$brief,$brief_catalog)=@_;
    my $return="
      <table>
        <tr>
          <td>
            <a name=\"$brief\"></a>
            <a href=\"report.detail.html#$brief_catalog\" target=\"_blank\"> <h2>$brief</h2></a>
            <div style='width:500px;'>";
    $return .= "<p class=\"pra\">$head</p>";
    my $mid  = &get_description($description);
    $return .= $mid;
    $return .= "\n</td>
          <td rowspan='3' style='padding-left:25px;'></td>
          <td rowspan='3'>
            <h3>结果统计</h3>
            <div class='metagenome_info' style='width: 320px;'>
              <ul style='margin: 0; padding: 0;'>";
    $return .= &get_table($table_array,$table_hash);
    $return .= "  
              </ul>
            </div>
          </td>  
        </tr>
      </table>";
    return$return;
}

sub get_description{
    my($des,)=@_;
    my $get_description=join("</p>\n<p class=\"pra\">",(split/\n/,$des));
    $get_description = "<p class=\"pra\">$get_description</p>";
    return$get_description;
}

sub get_table{
    my($table_array,$table_hash)=@_;
    my $get_table;
    foreach my $i (0..$#{$table_array}){
        if ($i%2 == 0 ) {
            $get_table .= " <li class='even'>";
        }else{$get_table .= "<li class='odd'>";}
        my $mid=${$table_array}[$i];
        $mid=~s/scaftigs$//;
        $get_table .= "
        <label style='text-align: left;white-space:nowrap;'>$mid:</label>
        <span style='width: 200px'>${$table_hash}{${$table_array}[$i]}</span>
        </li>
        ";
    }
    return $get_table;
}

sub get_index {
    my($report,$stat_info,$index_file,$dir)=@_;
    ##get stat info
    my %qc_stat;
    my %ass_stat;
    my %mix_stat;
    my %gene_stat;
    my %tax_stat;
    my %fun_stat;
	my %ardb_stat;

    my @qc_stat;
    my @ass_stat;
    my @mix_stat;
    my @gene_stat;
    my @tax_stat;
    my @fun_stat;
	my @ardb_stat;

    open IN,"$stat_info";
    $/="\n///";
    ####qc
    my $qc_block = <IN>;
    chomp $qc_block;
    my @qc_tmp=split /\n/,$qc_block;
    shift@qc_tmp;
    foreach my $qc_tmp (@qc_tmp){
        my @array_qc= split /\t/ ,$qc_tmp;
        $qc_stat{$array_qc[0]}=$array_qc[1];
        push @qc_stat,$array_qc[0];
    } 
    ###ass
    my $ass_block =<IN>;
    chomp $ass_block;
    my @ass_tmp=split /\n/,$ass_block;
    shift@ass_tmp;
    my $ass=0;
    foreach my $ass_tmp (@ass_tmp){
        my @array_ass=split /\t/,$ass_tmp;
        $array_ass[0].="scaftigs" if $ass > 6;
        $ass_stat{$array_ass[0]}=$array_ass[1];
        push @ass_stat,$array_ass[0];
        $ass++;
    }

    ###gene
    my $gene_block =<IN>;
    chomp $gene_block;
    my @gene_tmp=split /\n/,$gene_block;
    shift@gene_tmp;
    foreach my $gene_tmp (@gene_tmp){
        my @array_gene=split /\t/,$gene_tmp;
        if ($array_gene[0] eq 'Complete ORFs' && $array_gene[1]=~/(.*)\((.*\%)\)/) {
            my $num=$1;
            my $precent=$2;
            $gene_stat{'Complete ORFs number'}=$num;
            $gene_stat{'Complete ORFs precent'}=$precent;
            push @gene_stat,'Complete ORFs number';
            push @gene_stat,'Complete ORFs precent';
        }else{
            $gene_stat{$array_gene[0]}=$array_gene[1];
            push @gene_stat,$array_gene[0];
        }
    }
    ###tax
    my $tax_block =<IN>;
    chomp $tax_block;
    my @tax_tmp=split /\n/,$tax_block;
    shift@tax_tmp;
    my @diff_tax_detail;
    foreach my $tax_tmp (@tax_tmp){
        my @array_tax=split /\t/,$tax_tmp;
        if ($array_tax[0] eq 'Assigned Phyla(top 5)' || $array_tax[0] eq 'Sign_diff Phyla(top 5)') {
            my @taxes=@array_tax[1..$#array_tax];
            my @join_taxes;
            if ($#taxes <= 2) {
                @join_taxes=@taxes;
            }else{
                @join_taxes = @taxes[0..2];
            }
            $tax_stat{$array_tax[0]}=join(", ",@join_taxes);
            if ($taxes[0] && $taxes[1] &&  $array_tax[0] eq 'Sign_diff Phyla(top 5)') {
                $taxes[0]=~s/;/_/g;
                $taxes[1]=~s/;/_/g;
                push @diff_tax_detail,$taxes[0];
                push @diff_tax_detail,$taxes[1];
            }
        }else{
            $tax_stat{$array_tax[0]}=$array_tax[1];
            push @tax_stat,$array_tax[0];
        }
    }
    if (-s "$dir/04.TaxAnnotation/MicroNR/MicroNR_stat/MetaStats/genus/boxplot/combine_box/combined.png") {
        `cp  $dir/04.TaxAnnotation/MicroNR/MicroNR_stat/MetaStats/genus/boxplot/combine_box/combined.png $report/src/pictures/04.Taxonomy/meta.com.png`;
    }
    if (-s "$report/src/pictures/04.Taxonomy/LDA.png" && -s "$report/src/pictures/04.Taxonomy/LDA.tree.png"){
	    `/usr/bin/convert -density 300 +append $report/src/pictures/04.Taxonomy/LDA.png $report/src/pictures/04.Taxonomy/LDA.tree.png $report/src/pictures/04.Taxonomy/LEfSe.png`;
	}
    ###fun
    my $fun_block =<IN>;
    chomp $fun_block;
    my @fun_tmp=split /\n/,$fun_block;
    shift@fun_tmp;
    foreach my $fun_tmp (@fun_tmp){
        my @array_fun=split /\t/,$fun_tmp;
        if($array_fun[0] eq 'Annotated on KO'){
          if ($array_fun[1]=~/(.*)\/(.*)/) {
            $fun_stat{'Annotated on KO'}=$1;
            $fun_stat{'Annotated on KO number'}=$2;
            push @fun_stat,'Annotated on KO';
            push @fun_stat,'Annotated on KO number';
          }
        }else{
          $fun_stat{$array_fun[0]}=$array_fun[1];
          push @fun_stat,$array_fun[0];
        }
    }
	###ARDB
	my $ardb_block=<IN>;
	chomp $ardb_block;
	my @ardb_tmp=split /\n/,$ardb_block;
	shift @ardb_tmp;
	foreach my $ardb_tmp(@ardb_tmp){
	    my @array_ardb=split /\t/,$ardb_tmp;
		$ardb_stat{$array_ardb[0]}=$array_ardb[1];
		push @ardb_stat,$array_ardb[0]	
	}		
    $/="\n";
    close IN ;

    #00.totalstat 
my $total_stat;
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.png"){
    $total_stat="本研究采用 Illumina HiSeq 测序平台测序，共获得 $qc_stat{'Total Raw Data'} 的原始数据(Raw Data)（平均数据量为 $qc_stat{'Average Raw Data'}），经过质控得到 $qc_stat{'Total Clean Data'} 的有效数据(Clean Data)（平均数据量为 $qc_stat{'Average Clean Data'}），经过单样品组装及混合组装后，共得到 $ass_stat{'Total length (nt)scaftigs'} 的 Scaftigs。对各样品及混合组装的结果，采用 MetaGeneMark 软件进行基因预测，共得到 $gene_stat{'Total ORFs'} 个开放阅读框（ORFs）（平均为 $gene_stat{'Average ORFs'}），经过去冗余后，共获得 $gene_stat{'Gene catalogue'} 个ORFs，总长为 $gene_stat{'Total length (Mbp)'} Mbp，其中完整基因的个数为 $gene_stat{'Complete ORFs number'}，所占比例为 $gene_stat{'Complete ORFs precent'}。非冗余基因集与 MicroNR 库进行 blastp 比对，运用 LCA 算法进行物种注释，注释到属和门的比例分别为 $tax_stat{'Annotated on Genus level'} , $tax_stat{'Annotated on Phylum level'}。使用 DIAMOND 软件对非冗余基因集进行常用功能数据库注释（e-value ≤10−5），有 $fun_stat{'Annotated on CAZy'} 个 ORFs 比对到 CAZy 数据库，$fun_stat{'Annotated on KEGG'} 个 ORFs 比对到 KEGG 数据库，$fun_stat{'Annotated on eggNOG'} 个 ORFs 比对到 eggNOG 数据库。非冗余基因集与抗性基因数据库（ARDB）进行注释（e-value ≤10−5），有$ardb_stat{'Annotated on ARDB'} 个 ORFs 比对到 ARDB 数据库。";
}
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_card.png"){
     $total_stat="本研究采用 Illumina HiSeq 测序平台测序，共获得 $qc_stat{'Total Raw Data'} 的原始数据(Raw Data)（平均数据量为 $qc_stat{'Average Raw Data'}），经过质控得到 $qc_stat{'Total Clean Data'} 的有效数据(Clean Data)（平均数据量为 $qc_stat{'Average Clean Data'}），经过单样品组装及混合组装后，共得到 $ass_stat{'Total length (nt)scaftigs'} 的 Scaftigs。对各样品及混合组装的结果，采用 MetaGeneMark 软件进行基因预测，共得到 $gene_stat{'Total ORFs'} 个开放阅读框（ORFs）（平均为 $gene_stat{'Average ORFs'}），经过去冗余后，共获得 $gene_stat{'Gene catalogue'} 个ORFs，总长为 $gene_stat{'Total length (Mbp)'} Mbp，其中完整基因的个数为 $gene_stat{'Complete ORFs number'}，所占比例为 $gene_stat{'Complete ORFs precent'}。非冗余基因集与 MicroNR 库进行 blastp 比对，运用 LCA 算法进行物种注释，注释到属和门的比例分别为 $tax_stat{'Annotated on Genus level'} , $tax_stat{'Annotated on Phylum level'}。使用 DIAMOND 软件对非冗余基因集进行常用功能数据库注释（e-value ≤10−5），有 $fun_stat{'Annotated on CAZy'} 个 ORFs 比对到 CAZy 数据库，$fun_stat{'Annotated on KEGG'} 个 ORFs 比对到 KEGG 数据库，$fun_stat{'Annotated on eggNOG'} 个 ORFs 比对到 eggNOG 数据库。非冗余基因集与抗性基因数据库（CARD）进行注释（e-value ≤10−30），有$ardb_stat{'Annotated on CARD'} 个基因比对到 CARD 数据库。";
}

    #01.CleanData
#my $CleanData_stat;
    my $CleanData_stat="质控结果概述：总共测序数据量为 $qc_stat{'Total Raw Data'}，平均测序数据量为 $qc_stat{'Average Raw Data'}，质控后总体数据量及平均数据量分别为 $qc_stat{'Total Clean Data'}，$qc_stat{'Average Clean Data'}，质控的有效数据率为 $qc_stat{'Effective percent'}。";
    $CleanData_stat.="去宿主后的总体数据量为 $qc_stat{'Total Nohost Data'}，平均数据量为 $qc_stat{'Average Nohost Data'}，去除宿主的有效数据率为 $qc_stat{'Effective rate'}。" if $opt{host};

    my $clean_description="数据预处理的具体处理步骤如下：
    1) 去除所含低质量碱基（质量值≤38）超过一定比例（默认设为 40bp）的 reads； 
    2) 去除 N 碱基达到一定比例的 reads（默认设为10bp）； 
    3) 去除与 Adapter 之间 overlap 超过一定阈值（默认设为 15bp）的 reads；
    4) 如果样品存在宿主污染，需与宿主数据库进行比对，过滤掉可能来源于宿主的 reads；";
    my $CleanData_dis_table=&get_table_descri(\@qc_stat,\%qc_stat,$CleanData_stat,$clean_description,"测序数据预处理","3.1 测序数据预处理");

    #02.assembly
    my $assembly_stat="组装结果概述：共组装得到 $ass_stat{'Total length (nt)'} 的 Scaffolds ，平均长度为 $ass_stat{'Average length (nt)'}，最大长度为 $ass_stat{'Longest length (nt)'}，N50 为 $ass_stat{'N50 length (nt)'}，N90 为 $ass_stat{'N90 length (nt)'}；从 N 处打断 Scaffolds，生成 Scaftigs, 共得到 $ass_stat{'Total length (nt)scaftigs'} 的 Scaftigs，Scaftigs 平均长度为 $ass_stat{'Average length (nt)scaftigs'}，N50 为 $ass_stat{'N50 length (nt)scaftigs'}，N90 为 $ass_stat{'N90 length (nt)scaftigs'}。";
    my $ass_description;
    if ($opt{type} eq 'soapdenovo') {
     $ass_description="Metagenome 组装的具体处理步骤如下：
     1）经过预处理后得到 Clean Data，使用 SOAP denovo 组装软件进行组装；
    2）对于单个样品，首先选取一个 K-mer（默认选取55）进行组装，得到该样品的组装结果；
    3）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs (i.e., continuous sequences within scaffolds)；
    4）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；
    5）将各样品未被利用上的 reads 放在一起，进行混合组装，组装时，考虑到计算消耗和时间消耗，只选取一个 kmer 进行组装（默认-K 55），其他组装参数与单样品组装参数相同；
    6）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；
    7）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp 以下的片段，并进行统计分析和后续基因预测；";
    }elsif($opt{type} eq 'IDBA_UD'){
     $ass_description="Metagenome 组装的具体处理步骤如下：
    1）经过预处理后得到 Clean Data，使用 IDBA_UD 组装软件进行组装；
    2）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs (i.e., continuous sequences within scaffolds)；
    3）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；
    4）将各样品未被利用上的 reads 放在一起，进行混合组装；
    5）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；
    6）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp 以下的片段，并进行统计分析和后续基因预测；";
    }elsif($opt{type} eq 'megahit'){
	$ass_description="Metagenome 组装的具体处理步骤如下：
    1）经过预处理后得到 Clean Data，使用 MEGAHIT 组装软件进行组装；
    2）将组装得到的 Scaffolds 从 N 连接处打断，得到不含 N 的序列片段，称为 Scaftigs (i.e., continuous sequences within scaffolds)；
    3）将各样品质控后的 CleanData 采用 Bowtie2 软件比对至各样品组装后的 Scaftigs 上，获取未被利用上的 PE reads；
    4）将各样品未被利用上的 reads 放在一起，进行混合组装；
    5）将混合组装的 Scaffolds 从 N 连接处打断，得到不含 N 的 Scaftigs 序列；
    6）对于单样品和混合组装生成的 Scaftigs，过滤掉 500bp 以下的片段，并进行统计分析和后续基因预测；";
	}
    my $ass_dis_table=&get_table_descri(\@ass_stat,\%ass_stat,$assembly_stat,$ass_description,"Metagenome 组装","3.2 Metagenome 组装");


    #03.gene.predict
    my $gene_predict_stat="基因预测结果概述：一共预测得到 $gene_stat{'Total ORFs'} 条 ORFs，平均每个样品 $gene_stat{'Average ORFs'} 条 ORFs；经去冗余后，得到 $gene_stat{'Gene catalogue'} 条 ORFs，去冗余后的 ORFs 总长为 $gene_stat{'Total length (Mbp)'} Mbp，平均长度 $gene_stat{'Average length (bp)'} bp，GC 含量为 $gene_stat{'GC percent'}，其中，完整基因有 $gene_stat{'Complete ORFs number'} 个，占所有非冗余基因总数的 $gene_stat{'Complete ORFs precent'}。
    ";
    my $gene_predict_description="基因预测基本步骤：
    1）从各样品及混合组装的 Scaftigs（>=500bp）出发，采用 MetaGeneMark 进行 ORF (Open Reading Frame) 预测及过滤；
    2）对各样品及混合组装的 ORF 预测结果，采用 CD-HIT 软件进行去冗余；
    3）将各样品的 Clean Data 比对至去冗余后的代表性基因上，计算得到基因在各样品中比对上的 reads 数目；
    4）过滤掉在各个样品中，不存在支持 reads 数目>2 的基因，获得最终用于后续分析的 gene catalogue（Unigenes）；
    5）从比对上的 reads 数目及基因长度出发，计算得到各基因在各样品中的丰度信息；
    6）基于 gene catalogue 中各基因在各样品中的丰度信息，进行基本信息统计，core-pan 基因分析，样品间相关性分析，及基因数目韦恩图分析。";
    my $gene_predict_dis_table=&get_table_descri(\@gene_stat,\%gene_stat,$gene_predict_stat,$gene_predict_description,"基因预测及丰度分析","3.3 基因预测及丰度分析");

    #04.taxonomy.annotation
    my $taxonomy_stat="物种注释结果概述：原始去冗余后的预测基因共有 $tax_stat{'Gene catalogue'} 条，其中，能够注释到 NR 数据库的 ORFs 数目为 $tax_stat{'Annotated on NR'}，在能够注释到 NR 数据库的 ORFs 中，注释到界水平的比例为 $tax_stat{'Annotated on Kingdom level'}，门水平的比例为 $tax_stat{'Annotated on Phylum level'}，纲水平的比例为 $tax_stat{'Annotated on Class level'}，目水平的比例为 $tax_stat{'Annotated on Order level'}，科水平的比例为 $tax_stat{'Annotated on Family level'}，属水平的比例为 $tax_stat{'Annotated on Genus level'}，种水平的比例为 $tax_stat{'Annotated on Species level'}。其中占主导地位的门主要包括 $tax_stat{'Assigned Phyla(top 5)'} 等。";
    $taxonomy_stat .="组间具有显著性差异的门主要有 $tax_stat{'Sign_diff Phyla(top 5)'} 等。" if $tax_stat{'Sign_diff Phyla(top 5)'};
    my $taxonomy_description="注释基本步骤：
    1）使用DIAMOND软件将 Unigenes 与从 NCBI 的 NR(Version: 2014-10-19) 数据库中抽提出的细菌(Bacteria)、真菌(Fungi)、古菌(Archaea)和病毒(Viruses)序列进行比对（blastp，evalue ≤ 1e-5）；
    2）比对结果过滤：对于每一条序列的比对结果，选取 evalue <= 最小 evalue*10 的比对结果进行后续分析；
    3）过滤后，采取 LCA 算法(应用于 MEGAN 软件的系统分类)，将出现第一个分支前的分类级别，作为各序列的物种注释信息；
    4）从 LCA 注释结果及基因丰度表出发，获得各个样品在各个分类层级（界门纲目科属种）上的丰度信息和基因数目信息；
    5）从各个分类层级（界门纲目科属种）上的丰度表出发，进行 Krona 分析，相对丰度概况展示，丰度聚类热图展示，PCA 和 NMDS 降维分析，Anosim组间（内）差异分析，组间差异物种的Metastat和LEfSe多元统计分析。";
    my $taxonomy_dis_table=&get_table_descri(\@tax_stat,\%tax_stat,$taxonomy_stat,$taxonomy_description,"物种注释","3.4 物种注释");

    #05.function.annotation
    my $function_stat="常用功能数据库注释结果概述：原始去冗余后的预测基因共有 $fun_stat{'Gene catalogue'} 个，有 $fun_stat{'Annotated on KEGG'} 个基因能够比对上 KEGG 数据库，其中，有 $fun_stat{'Annotated on KO'} 个基因能够比对上数据库中的 $fun_stat{'Annotated on KO number'} 个 KEGG ortholog group （KO）；有 $fun_stat{'Annotated on eggNOG'} 个基因能够比对上 eggNOG 数据库；有 $fun_stat{'Annotated on CAZy'} 个基因能够比对上 CAZy 数据库。";
    my $function_description="注释基本步骤：
    1）使用DIAMOND软件将 Unigenes 与各功能数据库进行比对（blastp，evalue ≤ 1e-5）；    2）比对结果过滤：对于每一条序列的比对结果，选取identity值大于数据库要求的保证该抗性基因注释结果可靠的最低identity值；
    3）从比对结果出发，统计不同功能层级的相对丰度和基因数目信息；   4）从各个分类层级上的丰度表出发，进行注释基因数目统计，相对丰度概况展示，丰度聚类热图展示，PCA和NMDS降维分析，基于功能丰度的Anosim组间（内）差异分析，代谢通路比较分析，组间功能差异的Metastat和LEfSe分析。";
    my $function_dis_table=&get_table_descri(\@fun_stat,\%fun_stat,$function_stat,$function_description,"常用功能数据库注释","3.5 常用功能数据库注释");
	
	#06.ARDB.annotation
my ($ardb_stat,$ardb_description);
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.png"){
	$ardb_stat="抗性基因注释结果概述：原始去冗余后的预测基因共有 $ardb_stat{'Gene catalogue'} 个，有 $ardb_stat{'Annotated on ARDB'} 个基因能够比对到 ARDB 数据库，共分为 $ardb_stat{'Annotated ARGs'} 个抗性基因类型（ARG）";
	$ardb_description="注释基本步骤：
	1）使用DIAMOND软件将 Unigenes 与ARDB数据库进行比对（blastp，evalue ≤ 1e-5）；
	2）比对结果过滤：对于每一条序列的 比对结果，选取 score 最高的比对结果进行后续分析；
	3）从比对结果出发，统计不同坑性基因的相对丰度; 4）从抗性基因丰度出发，进行丰度柱形图展示，丰度聚类热图展示，组间抗性基因数目差异分析、抗性基因在各样品中丰度分布情况展示，抗性基因物种归属分析及抗性基因的抗性机制分析。";
}
    #06.CARD.annotation    add by zhangjing at 2017-04-25
if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_card.png"){
    $ardb_stat="抗性基因注释结果概述：原始去冗余后的预测基因共有 $ardb_stat{'Gene catalogue'} 个，有 $ardb_stat{'Annotated on CARD'} 个基因能够比对到 CARD 数据库，共包含 $ardb_stat{'Annotated AROs'} 种ARO（the Antibiotic Resistance Ontology）";
    $ardb_description="注释基本步骤：
    1）使用CARD数据库提供的Resistance Gene Identifier (RGI)软件将 Unigenes 与CARD数据库进行比对（RGI内置blastp，默认evalue ≤ 1e-30）；
    2）根据RGI的比对结果，结合Unigenes的丰度信息，统计出各ARO的相对丰度；
    3）从ARO的丰度出发，进行丰度柱形图展示，丰度聚类热图展示，丰度分布圈图展示，组间ARO差异分析，抗性基因（注释到ARO的unigenes）物种归属分析等（对部分名称较长的ARO，用其前三个单词与下划线缩写的形式展示）；";
}
    my $ardb_dis_table=&get_table_descri(\@ardb_stat,\%ardb_stat,$ardb_stat,$ardb_description,"抗性基因注释","3.6 抗性基因注释");
    ###end for get png, json and head

    ##################main script##################
    open(OUT,">$index_file");

    print OUT << "OUT"
    <!DOCTYPE HTML>
    <html>
      <head>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8">
        <title>项目概述</title>   
        <link rel="stylesheet" type="text/css" href="src/css/novo.css" > 
      </head>
    <body onload="initialize_all();">

       <div id="topbar">
        <table style="width: 100%; border-spacing: 0px;">
          <tr>
        <td style='width: 100%; padding: 0px;'>
          
             <div style='height: 60px;'></div>
          
        </td>
          </tr>
        </table>
      </div>


    <div id="content_frame">
        <div id="page_title">诺禾致源 Metagenome 分析结题报告</div>
        <div id="content">
          <p>
            <div style='width: 700px'>
              <div style='float: left'>
                <table>
                  <tr>
                    <td><b>项目编号</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$id</td>
                  </tr>
                  <tr>
                    <td><b>项目名称</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$pro</td>
                  </tr>
                  <tr>
                    <td><b>报告时间</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$date</td>
                  </tr>
                  <tr>
                    <td><b>报告编号</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$report_id</td>
                  </tr>
                  <tr>
                    <td><b>联系人</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;${$contact{$opt{contact}}}[0]</td>
                  </tr>
                  <tr><td><b>邮箱</b></td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="mailto:${$contact{$opt{contact}}}[2]" target="_blank" >${$contact{$opt{contact}}}[2]</a></td></tr>
                  <tr>
                    <td><b>电话</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;${$contact{$opt{contact}}}[1]</td>
                  </tr>
                  <tr>
                    <td><b>结题报告详细版</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="report.detail.html" target="_blank" >请点击</a></td>
                  </tr>
                  <tr>
                    <td><b>公司主页</b></td>
                    <td><a href='http://www.novogene.com' target="_blank" >&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;http://www.novogene.cn</a></td>
                  </tr>
				  <tr>
                    <td><b>结题时间</b></td>
                    <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$date</td>
                  </tr>
                </table>
              </div>
            </div>
          </p>
          <div style='clear: both; height: 10px'></div>
          <table>
            <tr><td>
             <h2>Metagenomics 概述</h2>
              <div style='width:500px;'>
                <p class="pra">微生物群体几乎存在于这个世界每一个生态群落之中，从个体体表到肠道，从高原空气到深海海底淤泥，从冰川冻湖到火山岩浆都无处不在，并扮演着不可或缺的角色。对微生物的研究从 Antoni van Leeuwenhoek 发明显微镜开始的数百年中，主要基于纯培养的研究方式。在数以万亿计的微生物种类中，仅 0.1%~1% 的物种可培养，极大地限制了对微生物多样性资源的研究和开发。</p>
                <p class="pra">Metagenomics(翻译成元基因组学，或者翻译成宏基因组学)是由 Handelman 最先提出的一种直接对微生物群体中包含的全部基因组信息进行研究的手段。之后， Kevin等对 Metagenomics 进行了定义，即“绕过对微生物个体进行分离培养，应用基因组学技术对自然环境中的微生物群落进行研究”的学科。它规避了对样品中的微生物进行分离培养，提供了对无法分离培养的微生物进行研究的途径，避免了实验过程中由环境改变引起的微生物序列变化所带来的偏差。</p>
                <p class="pra">近年来，随着测序技术和信息技术的快速发展，利用新一代测序技术(Next Generation Sequencing)研究 Metagenomics，能快速准确的得到大量生物数据和丰富的微生物研究信息，从而成为研究微生物多样性和群落特征的重要手段。如致力于研究微生物与人类疾病健康关系的人体微生物组计划(HMP, Human Microbiome Project, http://www.hmpdacc.org/ )，研究全球微生物组成和分布的全球微生物组计划(EMP, Earth Microbiome Project, http://www.earthmicrobiome.org/ )都主要利用高通量测序技术进行研究。</p>
              </div>
            </td>
        
            <td rowspan='4' style='padding-left:25px;'></td>
            <td  <td rowspan='4'><h2>目录</h2>
              <div style='border:2px solid #AAAAAA;padding:40px;background-color:#EEEEEE;'>
                <li>Metagenomics 概述</li>
                <li style='padding-top:15px;'>分析流程</li>
                <ul style='margin:0;'>
                  <li style='padding-top:5px'><a href='report.detail.html#2.1 建库测序流程' target="_blank" >建库测序流程</a></li>
                  <li style='padding-top:5px'><a href='report.detail.html#2.2 信息分析流程' target="_blank" >信息分析流程</a></li>
                </ul>

                <li style='padding-top:15px;'>分析结果</li>
                <ul style='margin:0;'>
                  <li style='padding-top:5px'><a href='#分析结果概述' target="_blank" >分析结果概述</a></li>
                  <li style='padding-top:5px'><a href='#测序数据预处理' target="_blank" >测序数据预处理</a></li>
                  <li style='padding-top:5px'><a href='#Metagenome 组装' target="_blank" >Metagenome 组装</a></li>
                  <li style='padding-top:5px'><a href='#基因预测及丰度分析' target="_blank" >基因预测及丰度分析</a></li>
                  <li style='padding-top:5px'><a href='#物种注释' target="_blank" >物种注释</a></li>
                  <li style='padding-top:5px'><a href='#常用功能数据库注释' target="_blank" >功能注释</a></li>
                </ul>
              </div>
            </td></tr>
          </table>
          <br>
          
          <!---------------分析结果概述-------------->
          <table>
            <tr>
            <a name="分析结果概述"></a> 
            <a href="report.detail.html#3 分析结果" target="_blank"> <h2>分析结果概述</h2></a>
            </tr>
            <tr>
              <td>
                <div style='width:900px;'>
            <p class="pra">
OUT
;
     print OUT "$total_stat";
     print OUT << "OUT"
                </p>
                </div>
              </td>
            </tr>
          </table>

    <!---------------测序数据预处理-------------->
OUT
;

    print OUT 
    "
    $CleanData_dis_table
    <!---------------Metagenome 组装-------------->
    $ass_dis_table";

    print OUT 
    "
    <!---------------基因预测-------------->
    $gene_predict_dis_table
    ";
    if (-s "$report/src/pictures/03.GeneComp/combine.gene.png" && -s "$report/src/pictures/03.GeneComp/correlation.heatmap.png"){
          print OUT   <<"OUT"  
          <table>
            <tr>
              <td>
                <div style='width:900px;'>
                <p class="pra">从基因在各样品中的丰度表出发，可以获得各样品的基因数目信息，通过随机抽取不同数目的样品，可以获得不同数目样品组合间的基因数目，由此我们构建和绘制了 Core 和 Pan 基因的稀释曲线，曲线越接近平缓，表示随着测序样品数目的增加，基因数目逐渐趋于稳定。</p>
                <p class="pra">生物学重复是任何生物学实验所必须的，高通量测序技术也不例外。样品间基因丰度相关性是检验实验可靠性和样本选择是否合理性的重要指标。相关系数越接近1，表明样品之间基因丰度模式的相似度越高。</p>
                 <div style="text-align:center;">
                 <p class="center">
                 <a href="src/pictures/03.GeneComp/combine.gene.png" target="_blank" ><img  src="src/pictures/03.GeneComp/combine.gene.png" width="85%" height="85%"/></a>
                 </p>
                 </div>
              </div>
              </td>
            </tr>        
          </table>
      <table>
             <tr>
              <td>
                <div style='width:500px;'>
                </br>
              </br>
              <p class="pra">图例：</pra>
                  <p class="pra">a) Core 基因稀释曲线，横坐标表示抽取的样品个数；纵坐标表示抽取的样品组合的基因数目。</p> 
                  <p class="pra">b) Pan 基因稀释曲线，横坐标表示抽取的样品个数；纵坐标表示抽取的样品组合的基因数目。</p> 
                  <p class="pra">c) 样品间相关系数热图，不同颜色代表 spearman 相关系数的高低；相关系数与颜色间的关系见右侧图例说明；颜色越深代表样品间相关系数的绝对值越大；椭圆向左偏表明相关系数为正，右偏为负；椭圆越扁说明相关系数的绝对值越大。</p>              
                </div>
              </td>
              <td rowspan='3' style='padding-left:25px;'></td>
              <td rowspan='3'>
                <p class ="pra">c</p>
                <div class='metagenome_info' style='width: 320px;'>
                 <div style="text-align:center;">
                 <p class="center"><a href="src/pictures/03.GeneComp/correlation.heatmap.png" target="_blank" ><img  src="src/pictures/03.GeneComp/correlation.heatmap.png" width="110%" height="110%"/></a></p>
               </div>
                </div>
              </td>  
            </tr> 
      </table> 
OUT
;   }


    print OUT "
    <!---------------物种注释-------------->
    $taxonomy_dis_table
    ";
    if(-s "$report/src/pictures/04.Taxonomy/tax.bp.png"){
        print OUT << "OUT"
           <table>
            <a> <h3>物种丰度分析</h3></a>
              <tr>
              <td>
                <div style='width:900px;'>
                <p class="pra">从不同分类层级的相对丰度表出发，选取出在各样品中的最大相对丰度排名前 10 的物种，并将其余的物种设置为 Others，绘制出各样品对应的物种注释结果在不同分类层级上的相对丰度柱形图。</p>
                <p class="pra">为了研究不同样品的相似性，还可以通过对样品进行聚类分析，构建样品的聚类树。从基因在各样品中的丰度表出发，以 Bray-Curtis 距离矩阵进行样品间聚类分析，并将聚类结果与各样品在门水平上的物种相对丰度整合进行展示。</p>
                <p class="pra">NMDS是非线性模型，可以更好地反映生态学数据的非线性结构，应用NMDS分析，根据样本中包含的物种信息，以点的形式反映在多维空间上，而不同样本间的差异程度则是通过点与点间的距离体现，能够反映样本的组间或组内差异等，进而揭示复杂数据背景下的简单规律。
                <p class="pra">基于不同分类层级的物种丰度表，我们进行了 NMDS 分析，如果样品的物种组成越相似，则它们在 NMDS 图中的距离越接近。</p>
                 <p class="center">
                 <a href="src/pictures/04.Taxonomy/tax.bp.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/tax.bp.png" width="80%" height="80%"/></a>
                 </p>
                <p class="pra">图例：</p>
                <p class="pra">a) 样品聚类分析，左侧是 Bray-Curtis 距离聚类树结构；右侧的是各样品在门水平上的物种相对丰度分布图。</p>
                 <p class="pra">b) 门水平的 NMDS 分析结果，图中的每个点表示一个样品，点与点之间的距离表示差异程度，同一个组的样品使用同一种颜色表示；Stress小于0.2时，表明NMDS分析具有一定的可靠性。</p>
              </div>
              </td>
            </tr>     
    </table>
OUT
;
    }


    if (-s "$report/src/pictures/04.Taxonomy/meta.com.png" &&  -s "$report/src/pictures/04.Taxonomy/LEfSe.png"){
    print OUT << "OUT"
              <table>
      <a> <h3>物种显著性差异分析</h3></a>
             <tr>
              <td>
                <div style='width:400px;'>
               <p class="pra">为了研究组间具有显著性差异的物种，通过Metastat和LEfSe多元统计分析寻找组间差异biomarker。从不同层级的物种丰度表出发，利用 Metastat 方法对组间的物种丰度数据进行假设检验得到 p 值，通过对 p 值的校正，得到 q 值；最后根据 q 值筛选具有显著性差异的物种，并绘制差异物种在组间的丰度分布箱图。同时，利用LEfSe分析对组间的物种丰度数据通过秩和检验的方法检测不同分组间的差异物种并通过LDA（线性判别分析）实现降维并评估差异物种的影响大小，即得到LDA score，最后绘制差异物种的LDA值分布柱状图以及差异物种的进化分支图，展示结果如右图所示:</p>
             </br>
               <p class="pra">图例：</p>
               <p class="pra">a) 属水平差异物种丰度箱图，横轴为差异物种名称，纵向为对应物种的相对丰度，箱体颜色代表不同分组；</p>
              <p class="pra">b) 差异物种的LDA值分布柱状图和差异物种的进化分支图，LDA值分布柱状图中展示了LDA Score大于设定值（默认设置为4）的物种，即组间具有统计学差异的Biomarker，柱状图的长度代表差异物种的影响大小（即为 LDA Score）；进化分支图中由内至外辐射的圆圈代表了由门至属（或种）的分类级别，在不同分类级别上的每一个小圆圈代表该水平下的一个分类，小圆圈直径大小与相对丰度大小呈正比；着色原则：无显著差异的物种统一着色为黄色，差异物种Biomarker跟随组进行着色，红色节点表示在红色组别中起到重要作用的微生物类群，绿色节点表示在绿色组别中起到重要作用的微生物类群；图中英文字母表示的物种名称在右侧图例中进行展示。</p>              
                </div>
              </td>
              <td rowspan='3' style='padding-left:25px;'></td>
              <td rowspan='3'>
                <div class='metagenome_info' style='width: 320px;'>
                 <div style="text-align:center;">
                 <p class="center">a<a href="src/pictures/04.Taxonomy/meta.com.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/meta.com.png" width="150%" height="150%"/></a></p>
                 <p class="center">b<a href="src/pictures/04.Taxonomy/LEfSe.png" target="_blank" ><img  src="src/pictures/04.Taxonomy/LEfSe.png" width="150%" height="150%"/></a></p>
               </div>
                </div>
              </td>  
            </tr> 
      </table> 
OUT
;   }
    print OUT "
    <!---------------功能注释-------------->  
    $function_dis_table
    ";
    if(-s "$report/src/pictures/05.FunctionAnnotation/kegg.com.png" && -s "$report/src/pictures/05.FunctionAnnotation/kegg.com2.png"){
    print OUT << "OUT"
    <table>
      <a> <h3>KEGG 数据库注释结果分析</h3></a>
             <tr>
              <td>
                <div style='width:400px;'>
               <p class="pra">KEGG 数据库为一个综合性数据库，其中最核心的为 KEGG PATHWAY 和 KEGG ORTHOLOGY 数据库。在 KEGG PATHWAY 数据库中，将生物代谢通路划分为 6 类，分别为：细胞过程（Cellular Processes）、环境信息处理（Environmental Information Processing）、遗传信息处理（Genetic Information Processing）、人类疾病（Human Diseases）、新陈代谢（Metabolism）、生物体系统（Organismal Systems），KEGG 数据库在研究基因功能方面发挥着重要的作用，是 Metagenomics 分析中，必不可少的一部分。</p>
               </br>
               <p class="pra">图例：</p>
               <p class="pra">a) KEGG Unigenes 注释数目统计图，条形图上的数字代表注释上的 Unigenes 数目；其余一个坐标轴是各数据库中 level1 各功能类的代码，代码的解释见对应的图例说明；</p>
              <p class="pra">b) KEGG 数据库 level1 上的相对丰度柱形图，纵轴表示注释到某功能类的相对比例；横轴表示样品名称；各颜色区块对应的功能类别见右侧图例；</p>
              <p class="pra">c) KEGG 功能丰度聚类热图，横向为样品信息；纵向为功能注释信息；图中左侧的聚类树为功能聚类树；中间热图对应的值为每一行功能相对丰度经过标准化处理后得到的 Z 值；</p>
              <p class="pra">d) KEGG 功能丰度的 PCA 分析结果展示，横坐标表示第一主成分，百分比则表示第一主成分对样品差异的贡献值；纵坐标表示第二主成分，百分比表示第二主成分对样品差异的贡献值；图中的每个点表示一个样品，同一个组的样品使用同一种颜色表示；</p>
                </div>
              </td>
              <td rowspan='3' style='padding-left:25px;'></td>
              <td rowspan='3'>
                <div class='metagenome_info' style='width: 320px;'>
                 <div style="text-align:center;">
                 <p class="center"><a href="src/pictures/05.FunctionAnnotation/kegg.com.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/kegg.com.png" width="170%" height="170%"/></a></p>
                 <p class="center"><a href="src/pictures/05.FunctionAnnotation/kegg.com2.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/kegg.com2.png" width="170%" height="170%"/></a></p>
               </div>
                </div>
              </td>  
            </tr> 
      </table> 
OUT
;
    }
    if ($opt{ipath}){
        print OUT << "OUT"
              <table>
              <tr>
               <td>
                <div style='width:900px;'>
                  <h3>代谢通路分析</h3>
                  <p class="pra">为了研究不同分组（不同样品）在代谢通路图中的差异，绘制了代谢通路网页版结果展示，整体网页版报告分为两部分：</p>
     <p class="pra">第一部分为 KEGG 9 大 pathway overview 图，图中，展示了两个分组（或两个样品）共有及特有的代谢通路信息，在代谢通路图中，节点代表各种化合物，边代表一系列的酶类反应，红色代表两个分组（或两个样品）共有的酶类反应，蓝色代表分组 A（或样品 A）独有的酶类反应，绿色代表分组 B（或样品 B）独有的酶类反应；</p>
     <p class="pra">第二部分为注释到的 pathway 代谢通路图，在代谢通路图中，节点代表各种化合物, 方框代表酶类信息（默认边框为黑色，背景为白色），不同颜色的方框代表注释为该酶类的不同 Unigenes 数目，黄色背景的酶类代表在分组间具有显著差异的酶类（若没有进行显著差异分析，则没有此部分信息），鼠标移动至该酶类，可显示差异酶类在不同分组间的丰度分布箱图。</p>
     <p class="pra"><a href="src/pictures/05.FunctionAnnotation/pathwaymaps/pathway.html" target="_blank" >展示结果请点击。</a></p>
                </div>
              </td>
            </tr>
            </table>
OUT
;   }

#if(!$opt{s2}){
        print OUT "
        <!---------------抗性基因注释-------------->  
        $ardb_dis_table
        ";
		if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_ardb.png" && -s "$report/src/pictures/05.FunctionAnnotation/circos.png"){
            print OUT << "OUT"
            <table>
            <a> <h3>抗性基因注释结果分析</h3></a>
                <tr>
                <td>
                <div style='width:400px;'>
                   <p class="pra">不管是人肠道微生物还是其他环境微生物中，抗性基因是普遍存在的。抗生素的滥用导致人体和环境中微生物群落发生不可逆的变化，对人体健康和生态环境造成风险，因此抗性基因的相关研究受到了研究者的广泛关注。目前，抗生素抗性基因的研究主要利用<a href="http://ardb.cbcb.umd.edu/" target="_blank" >ARDB</a>（Antibiotic Resistance Genes Database） 数据库。通过该数据库的注释，可以找到抗生素抗性基因（Antibiotic Resistance Genes ，ARG）及其抗性类型（Antibiotic Resistance Type）以及这些基因所耐受的抗生素种类（ Antibiotic）等信息。</p> 
                   <p class="pra">另外，ARDB数 据 库 中 列 举 了 几 个 重 要 的 抗 性 机 制，详细的抗性机制说明<a href="http://ardb.cbcb.umd.edu/browsegene.shtml" target="_blank" >请点击</a>：</br>
                   （1）氨基糖苷类抗生素的抗药性(Aminoglycoside Resistance)：细菌对氨基糖苷类抗生素存在抗性主要是由于乙酰转移酶（ acetyltransferase），核苷酸转移酶（ nucleotidyltransferase），磷酸转移酶（ phosphotransferases）的失活导致的；</br>
				   （2）β-内酰胺酶(Beta-Lactamase or beta-lactam resistance)：β-内酰胺酶能广泛作用于含有丝氨酸残基活性位点的蛋白，类似于细菌盘尼西林结合蛋白，或作用于含锌离子的金属酶；</br>                   （3）大环内酯-林肯胺-链霉杀阳菌素抗性(MLS):大环内酯的抗性机制是由于转录后23rRNA 被腺嘌呤-N6-甲基转移酶修饰导致的；</br>
                   （4）多药转运蛋白(Multidrug Transporters)：其抗性是由于活跃的转移蛋白能将不同的细胞毒素分子泵出细胞外导致的；</br>
				   （5）四环素抗性(Tetracycline Resistance)：对四环素的抗性，一般包含外排蛋白降低了细胞内药物含量和核糖体保护蛋白降低核糖体对四环素作用的易感性导致的；</br>
                   （6）万古霉素抗性(Vancomycin Resistance)：万古霉素的抗性是由于操纵子的存在，编码的酶合成低亲和力的前体， 修饰了万古霉素的结合区，消除高亲和力的前体，移除万古霉素的结合区域导致的。
                   <p class="pra">图例：</p>
                   <p class="pra">各样品中坑性基因丰度概况：a）表示抗性基因在各个样品中的含量，单位 ppm，是将原始相对丰度数据放大 10<SUP>6</SUP>倍的结果；b）表示抗性基因在各个样品中的相对丰度；</p>
                   <p class="pra">c) 各样品中抗性基因类型分布比例概览：圈图分为两个部分，右侧为样品信息，左侧为 ARG 耐受的抗生素信息。内圈不同颜色表示不同的样品和 Antibiotic， 刻度为相对丰度， 单位为 ppm， 左侧为样品中抗性基因的相对丰度之和， 右侧为各 Antibiotic 中抗性基因的相对丰度之和； 外圈左侧为各样品中抗性基因其所属的 Antibiotic 的相对百分含量，外圈右侧为各 Antibiotic 中抗性基因其所在的样品的相对百分含量。</p>
                </div>
                </td>
                <td rowspan='3' style='padding-left:25px;'></td>
                <td rowspan='3'>
                <div class='metagenome_info' style='width: 320px;'>
                <div style="text-align:center;">
                    <p class="center"><a href="src/pictures/05.FunctionAnnotation/antibiotic_ardb.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/antibiotic_ardb.png" width="170%" height="170%"/></a></p>
                    <p class="center">c<a href="src/pictures/05.FunctionAnnotation/circos.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/circos.png" width="170%" height="170%"/></a></p>
                </div>
                </div>
                </td>  
                </tr> 
            </table> 
OUT
;
        }
        if(-s "$report/src/pictures/05.FunctionAnnotation/antibiotic_card.png" && -s "$report/src/pictures/05.FunctionAnnotation/circos.png"){
            print OUT << "OUT"
                <table>
                <a> <h3>抗性基因注释结果分析</h3></a>
                <tr>
                <td>
                <div style='width:400px;'>
                <p class="pra">不管是人肠道微生物还是其他环境微生物中，抗性基因是普遍存在的。抗生素的滥用导致人体和环境中微生物群落发生不可逆的变化，对人体健康和生态环境造成风险，因此抗性基因的相关研究受到了研究者的广泛关注。目前，抗生素抗性基因的研究主要利用<a href="http://arpcard.mcmaster.ca/" target="_blank" >CARD</a>（Comprehensive Antibiotic Resistance Database），该数据库的核心构成是Antibiotic Resistance Ontology（ARO），它整合了序列、抗生素抗性、作用机制、ARO之间的关联等信息，并在线提供ARO与PDB、NCBI等数据库的接口。</p>
                <p class="pra">图例：</p>
                <p class="pra">各样品中坑性基因丰度概况：</p>
                <p class="pra">a）表示ARO在各个样品中的含量，单位 ppm，是将原始相对丰度数据放大 10<SUP>6</SUP>倍的结果；</p>
                <p class="pra">b）表示top20 ARO在所有 ARO中的相对丰度，others为非top 20 ARO相对丰度总和；</p>
                <p class="pra">c）各样品中抗性基因类型分布比例概览：圈图分为两个部分，右侧为样品信息，左侧为 ARO 信息。内圈不同颜色表示不同的样品和 ARO， 刻度为相对丰度， 单位为 ppm， 左侧为某ARO各个样本中的相对丰度之和， 右侧为各 ARO 在某样本种的相对丰度之和； 外圈左侧为某ARO中各个样品的相对百分含量，外圈右侧为某样品中各ARO的相对百分含量。</p>
                </div>
                </td>
                <td rowspan='3' style='padding-left:25px;'></td>
                <td rowspan='3'>
                <div class='metagenome_info' style='width: 320px;'>
                <div style="text-align:center;">
                <p class="center"><a href="src/pictures/05.FunctionAnnotation/antibiotic_card.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/antibiotic_card.png" width="170%" height="170%"/></a></p>
                <p class="center">c<a href="src/pictures/05.FunctionAnnotation/circos.png" target="_blank" ><img  src="src/pictures/05.FunctionAnnotation/circos.png" width="170%" height="170%"/></a></p>
                </div>
                </div>
                </td>
                </tr>
                </table>
OUT
;
        
        }
    }
    print OUT "</br></br></br></br></br></br></body>";
    close OUT;
#}
