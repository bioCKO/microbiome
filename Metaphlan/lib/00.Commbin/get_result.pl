#!/usr/bin/perl -w
use utf8;
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use File::Basename; 
use Data::Dumper;
# set default options
my %opt = (indir=>"",result=>".",shdir=>"./Shell",cpu=>'1',avf=>'1G',qopts=>' --qopts \' -q all.q,micro.q \' ',type=>'soapdenovo',contact=>'yuanyuqi',"step"=>"123457");
GetOptions (\%opt,"indir:s","result:s","shdir:s","rawdata:s","cpu:i","avf:s","help:s","locate","s2","notrun","host:s","ipath","vs","type:s","contact:s","info:s","lefse","step:s","rf"); 

##==Usage help information==
($opt{indir} && -s $opt{indir} && $opt{type} )|| die "usage: perl get_result.pl --indir work_dir --result result_dir<result> [--options]
Name:      get_result.pl
Function:  To creat result directory.
Version:   0.4  Date: 2015-7-3,Updating to MetaV3.0
Version:   0.3  Date: 2015-3-2,add md5 function,modified some filenames
Version:   0.2  Date: 2015-01-26, add option s2;delivery by 'ln -s' instead of by 'cp'
Version:   0.1  Date: 2014-11-20   
Author(s): Yu Jinhui,Chen Junru;
Contact:   yujinhui[AT]novogene.cn
Options:
      *--indir    [str]      input the workdir,default=.
      --result    [str]      input the parrent dir of result,default=.
      *-type      [str]      choose different assembly Methods discription according to deffirent type,default=soapdenovo.
      --s2                    to creat result directory for two samples(or just 1 sample)
      --host      [str]       host mode,input the host for last screening
      --info      [file]      input information of project,format:NHID\\tReportID\\tProject Name
      --contact   [str]       contact name, default=yaonana
      --qopts     [str]       set other super_worker options, default is --qopts \' -q all.q,micro.q \'
      --avf       [str]       set qsub memory in M,default=1G
      --shdir     [dir]       set shell directory,default=./Shell
      --ipath                 if there is ipath analysis
      --vs                    if there is metastasts analysis
      --lefse                 if there is LEfSe analysis
	  --rf 	                  if there is RandForest analysis
      --notrun                only write the shell script, but not run
      --locate                run md5.sh locate, not qusb
Example:
    perl $0 --indir Host/ --result ./ \n";

##==Basic ==
my ($indir,$result);
$indir=$opt{indir}||".";
(-d $indir) || die "The work_dir doesn't exist\!";
$indir=abs_path($indir);
$result=$opt{result}||".";
my $result_ori=$result;
open INFO, "< $opt{info}" || die "$!\n";
my $result_prefix = <INFO>;
close INFO;
chomp ($result_prefix);
 my @result_prefix= split (/\t/,$result_prefix);
$result_prefix[1]=~s/-/\_/g;
my $date = `date +"%Y""%m""%d"`;
chomp ($date);
$result .= "/$result_prefix[1]_result_$date";
$result = abs_path($result);
(-d $result) ? (`rm -rf $result ; mkdir -p $result`):(`mkdir -p $result`);
#`cp -f $Bin/ReadMe.pdf $result/ReadMe.pdf`;
`cp -f $Bin/ReadMe.html $result/ReadMe.html`;###add by zhanghao 20180106 edit by liuruoling
#`ln -s $Bin/MetaGenome_Result_Detail_Information.V3.0.pdf $result/`;
my $get_report="perl $Bin/get_report.pl ";
my $release_rm="perl $Bin/release.pl";
($opt{info}) && ($get_report .= " --info $opt{info} ");
($opt{s2}) && ($get_report .= " --s2 ");
($opt{ipath}) && ($get_report .= " --ipath ");
($opt{vs}) && ($get_report .= " --vs ");
($opt{lefse}) && ($get_report .= " --lefse ");
($opt{rf}) && ($get_report .= " --rf ");

($opt{type}) && ($get_report .= " --type $opt{type} ");
#$opt{id} && ($get_report .=" --id $opt{id} ");
$opt{contact} && ($get_report .= " --contact $opt{contact} ");
$opt{shdir}||="./Shell";
$opt{shdir}=abs_path($opt{shdir});
( -d $opt{shdir} ) || `mkdir -p $opt{shdir} `;
my $use =`whoami`;
#get software pathway
use lib "$Bin/../00.Commbin";
my $lib = "$Bin/../../lib";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my ($super_worker,$trigger) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(SUPER_WORK SH_CONTRAL2)],$Bin,$lib);
$super_worker.=" --resource $opt{avf}  ";
 my $checkdir="perl $Bin/dirCheckSize.pl  ";
##===Main===
my @step=split("",$opt{step});
my %rawdir = ("1"=>"01.CleanData","2"=>"02.Assembly","3"=>"03.GenePredict","4"=>"04.TaxAnnotation","5"=>"05.FunctionAnnotation");
my @dir;
foreach my $n (sort keys %rawdir)
{
        foreach my $step (sort @step)
                {    
                            push(@dir,$rawdir{$step}) if ($step eq $n );
                                }    
}
#my @dir = qw(01.CleanData 02.Assembly 03.GenePredict 04.TaxAnnotation 05.FunctionAnnotation);
open RE, "> $indir/Shell/release_meta.sh";
print RE "$release_rm --resultdir $result --info $result/../$opt{info} --outdir $result/../Shell --rpm_path /RRM/MICRO/meta/$use \n";
close RE;
#print TAR "cd $result/$dir[0] 
#tar -zchf QC_raw_report.tar.gz QC_raw_report
#rm -rf QC_raw_report
#cd $result
#tar -zcvhf $dir[2].tar.gz $dir[2]
#tar -zchvf $dir[3].tar.gz $dir[3]
#tar -zcvhf $dir[4].tar.gz $dir[4]
#rm -rf $dir[2]
#rm -rf $dir[3]
#rm -rf $dir[4]
#$checkdir $result 2>../error.log\n";
#close TAR;
for (@dir){
	(-s "$result/$_") || `mkdir -p $result/$_`;	
    system("cp -rf $Bin/result/$_--readme.pdf $result/$_/\n");
   # system("ln -s $Bin/result/$_--readme.pdf $result/$_/\n");
    $_ = "$result/$_";
}
#open filehandles
my $mdsh="MD5.sh";
open SH,">$opt{shdir}/$mdsh";
my $md5list="$opt{shdir}/MD5.list";
(-s "$opt{shdir}/MD5.list") ? `rm -f $opt{shdir}/MD5.list` : 1;
open(MD5LIST,">$opt{shdir}/MD5.list") || warn"touching for MD5.list is not successed!\n";

###get sample name list 
my (@name,$name,%fq);
(-s "$indir/01.DataClean/Dataclean.total.list") || die $!;
   for(`less $indir/01.DataClean/Dataclean.total.list`){
      my @l=split;
	  $name=$l[0];
	  $fq{$name}=$l[-1];#name->name.fq1.gz,name.fq2.gz;	  
    }
	for(sort (keys %fq)){
	   push @name, $_;
	}
my @all_name=@name;

#00.RawData
if ($opt{rawdata}){
    push @dir,"00.RawData";
    $dir[-1].="$result/";
	(-d $dir[-1]) || mkdir($dir[-1]);
## we'll go on later....	

} 

##01.CleanData
if($opt{step} =~ /1/){
my %name_insize;
my $host=0;
if(-s "$indir/01.DataClean/Dataclean.total.list"){
    (-d "$dir[0]") || mkdir "$dir[0]";
	for(@name){
	   (-d "$dir[0]/$_") || mkdir ("$dir[0]/$_");
       my @fq=split/\,/,$fq{$_};#name.fq1.gz,name.fq2.gz;
	   $fq[0]=~/\/($_\_\d+)/;
	   $name_insize{$_}=$1; #samplename=>name_size 
	   if($fq[0]=~/nohost/){ #exist hosts
	      $host=1;
		  my @array = get_filename($fq[0]);
		  my $gz_path=$array[1];
          system "ln -s $fq[0] $dir[0]/$_/$name_insize{$_}\.nohost.fq1.gz" || die "$!";
          system "ln -s $fq[1] $dir[0]/$_/$name_insize{$_}\.nohost.fq2.gz" || die "$!";
          system "ln -s $indir/01.DataClean/SystemClean/$_/{*.fq1.gz,*.fq2.gz} $dir[0]/$_" || die "$!";
          system "ls $result/01.CleanData/$_/$name_insize{$_}\.nohost\.{fq1.gz,fq2.gz} >> $md5list";
		  system "ls $result/01.CleanData/$_/$name_insize{$_}\.{fq1.gz,fq2.gz} >> $md5list";		  
          }
       else {    #no hosts
          system "ln -s $indir/01.DataClean/SystemClean/$_/{*.fq1.gz,*.fq2.gz} $dir[0]/$_" || die "$!"; 
		  system "ls $result/01.CleanData/$_/{*.fq1.gz,*.fq2.gz} >> $md5list";	      	     
	   }       	  
	 }
    cp_datalist("$indir/01.DataClean/png.list","$dir[0]");
    (-s "$indir/01.DataClean/novototal.QCstat.info.xls") &&
    #system "ln -s $indir/01.DataClean/{novototal.QCstat.info.xls,total.QCstat.info.xls} $dir[0]";
    system "cp -rf $indir/01.DataClean/{novototal.QCstat.info.xls,total.QCstat.info.xls} $dir[0]";
    #$opt{host} && system "ln -s $indir/01.DataClean/*.NonHostQCstat.info.xls $dir[0]";
    $opt{host} && system "cp -rf  $indir/01.DataClean/*.NonHostQCstat.info.xls $dir[0]";
	
#QC_raw_report
    (-s "$indir/01.DataClean/QC_raw_report") || warn "$indir/01.DataClean/QC_raw_report does not exist!\n";
#(-s "$dir[0]/QC_raw_report") || mkdir ("$dir[0]/QC_raw_report");
    system "cp -rf $indir/01.DataClean/QC_raw_report/ $dir[0]/QC_raw_report ";
    system  "rm $dir[0]/QC_raw_report/novo.html";
    system "rm $dir[0]/QC_raw_report/monitor.xls";
#	chdir $dir[0];
#	system "tar -zchf QC_raw_report.tar.gz QC_raw_report";
#	system "rm -rf $dir[0]/QC_raw_report";
#system "ln -s $indir/01.DataClean/QC_raw_report/{image,index.html} $dir[0]/QC_raw_report";
    	

}
else {warn "[Warnning]The file '01.DataClean/Dataclean.total.list' does not exist!\n";
 }
}
##02.Assembly
if ($opt{step}=~/2/){
my $seqlist="$indir/02.Assembly/total.scafSeq.ss.list";
if(-s $seqlist){
    (-d $dir[1]) || mkdir($dir[1]);	
    for (`less $seqlist`){
	    chomp;
		my @or=split/\//;
		my $name=$or[-2];
		push @all_name,$name if(!exists $fq{$name});
        (-d "$dir[1]/$name") || mkdir "$dir[1]/$name";
        system "cp -rf  $indir/02.Assembly/$name/{*.*.ss.txt,*.len.png,*.len.svg} $dir[1]/$name " || die "$!";	
        system "ln -s $indir/02.Assembly/$name/*.fa $dir[1]/$name " || die "$!";	
		system "ls $result/02.Assembly/$name/*.fa >> $md5list";        		
    }

	system "cp -rf  $indir/02.Assembly/*.info.xls $dir[1]" || die "$!";
	#system "ln -s $indir/02.Assembly/*.info.xls $dir[1]" || die "$!";
}
else {warn "[Warnning]The file '02.Assembly/total.scafSeq.ss.list' does not exist!\n";
}

##ReadsMapping
my $mapdir="$indir/02.Assembly/NOVO_MIX/ReadsMapping";
if(-s "$mapdir"){
#    (-d $dir[2]) || mkdir($dir[2]);
    for (@name){
        (-d "$dir[1]/ReadsMapping/$_") || `mkdir -p $dir[1]/ReadsMapping/$_`;
        system "cp -rf  $mapdir/$_/{coverage_depth.png,coverage_depth.svg} $dir[1]/ReadsMapping/$_" || die "$!";
        system "ln -s $mapdir/$_/{*fq1.gz,*fq2.gz} $dir[1]/ReadsMapping/$_" || die "$!";
        system "cp -rf  $mapdir/$_/coverage.depth.table $dir[1]/ReadsMapping/$_/coverage.depth.table.xls" || die "$!";		
        #system "ln -s $mapdir/$_/coverage.depth.table $dir[1]/ReadsMapping/$_/coverage.depth.table.xls" || die "$!";		
#        if($host){ #exist hosts  
#		   system "ln -s $mapdir/$_/*.SE.soap $dir[2]/$_/$name_insize{$_}\.nohost.fq1.gz.SE.soap" || die "$!";
#		   system "ln -s $mapdir/$_/*.PE.soap $dir[2]/$_/$name_insize{$_}\.nohost.fq1.gz.PE.soap" || die "$!";
#		   system "ls result/03.ReadsMapping/$_/*.soap >> $md5list";
#        }
 #       else {   #nohost
#system "ln -s $mapdir/$_/{*.SE.soap,*.PE.soap} $dir[1]/ReadsMapping/$_" || die "$!";    change by zhangjing at 2017-04-20
#		   system "ls result/02.Assembly/ReadsMapping/$_/*.soap >> $md5list";
#		}		   
    }
  }
}
##03.GenePredict
if($opt{step}=~/3/){
my $genedir="$indir/03.GenePredict";
  if(-s $genedir){
    (-d $dir[2]) || mkdir($dir[2]);
	for(@all_name){

#GenePredict
	    my $name=$_;
	    my $gpdir="$dir[2]/GenePredict/$name";
		(-d $gpdir)||`mkdir -p $gpdir`;
	    system "ln -s $genedir/GenePredict/$name/{*.CDS.fa,*.protein.fa,*len.svg,*len.png,*.CDS.fa.integrity.stat.xls,*.CDS.fa.len.xls,*.CDS.fa.stat.xls} $gpdir";#*scaf.300.fa,
	    system "ln -s $genedir/GenePredict/$name/$name.rename.mgm.gff $gpdir/$name.mgm.gff";
	}
		
	for(@name){		
#GeneTable
 	    my $name=$_;
	    my $gpdir="$dir[2]/GenePredict/$name";
		(-d $gpdir)||`mkdir -p $gpdir`;       		
		my $gtdir="$dir[2]/GeneTable/$name";
	    (-d $gtdir) || `mkdir -p $gtdir`;
#system "ln -s $genedir/GeneTable/$name/{soap.coverage.depthsingle,coverage_depth.png,coverage_depth.svg,*PE.soap,*SE.soap} $gtdir"  || die "$!";#*fq1.gz,*fq2.gz,*fa
	    system "ln -s $genedir/GeneTable/$name/{coverage_depth.png,coverage_depth.svg} $gtdir"  || die "$!";#*fq1.gz,*fq2.gz,*fa
	    system "ln -s $genedir/GeneTable/$name/coverage.depth.table $gtdir/coverage.depth.table.xls"  || die "$!";		
	}
		
		my $gptotal="$dir[2]/GeneTable/Total";
		(-d $gptotal) || `mkdir -p $gptotal`;		
#		my @total=qw(readsNum);#cover  
#		for (@total){
#		    $_="$gptotal/$_";
#			(-d $_) || `mkdir -p $_`;
#		}
#       my $cover="$genedir/GeneTable/Total/cover";
		my $readnum="$genedir/GeneTable/Total/readsNum";
#		system "ln -s $cover/{Unigenes.coverage.single.xls,Unigenes.cover.length.xls,Unigenes.coverage.xls,Unigenes.cover.screening.fa,Unigenes.coverage.single.even.xls,Unigenes.cover.depth.xls} $total[0]";
		system "ln -s $readnum/{Unigenes.readsNum.even.xls,Unigenes.readsNum.screening.fa,Unigenes.readsNum.xls,Unigenes.readsNum.relative.xls} $gptotal";
#		($opt{s2}) || system "ln -s $cover/Unigenes.coverage.single.even.tree $total[0]";
		($opt{s2}) || system "ln -s $readnum/Unigenes.readsNum.even.tree $gptotal";
        
		#UniqGenes       
		my $uniqgene="$dir[2]/UniqGenes";
		(-d $uniqgene) || mkdir ($uniqgene);
        system " ln -s $genedir/UniqGenes/{Unigenes.CDS.cdhit.fa,Unigenes.CDS.cdhit.fa.len.png,Unigenes.CDS.cdhit.fa.len.svg,Unigenes.protein.cdhit.fa,Unigenes.protein.fa,Unigenes.protein.table.txt,Unigenes.CDS.cdhit.fa.integrity.stat.xls,Unigenes.CDS.cdhit.fa.len.xls,Unigenes.CDS.cdhit.fa.stat.xls,Unigenes.protein.cdhit.fa.len.xls} $uniqgene";
        
		#GeneStat		
		my $genestat="$dir[2]/GeneStat";
		my @stat=qw(core_pan correlation genebox venn_flower);
		for (@stat){
		    (-s "$indir/03.GenePredict/GeneStat/$_") || next;
		    $_="$genestat/$_";
			(-d $_) || `mkdir -p $_`;
		}
#print "$_\n";
        if (-d $stat[0]){
		   (-s "$genedir/GeneStat/core_pan/core.gene.png") ?
		   system "ln -s $genedir/GeneStat/core_pan/{core.gene.pdf,core.gene.png,pan.gene.pdf,pan.gene.png} $stat[0]":
		   (-s "$genedir/GeneStat/core_pan/core.flower.png") ?		
		   system "ln -s $genedir/GeneStat/core_pan/core.flower.svg,core.flower.png $stat[0]":warn "core_pan gene figures lost!\n";#		
# system "ln -s $genedir/GeneStat/core_pan/{core.flower.svg,core.flower.png} $stat[0]":warn "core_pan gene figures lost!\n";#		change by zhanghao 20182027
		   system "ln -s $genedir/GeneStat/core_pan/core.geneid.txt $stat[0]";	
		}
		system "ln -sf $genedir/GeneStat/correlation/correlation.xls.xls $stat[1]" if(! $opt{s2} && -d $stat[1]);		
		system "ln -sf $genedir/GeneStat/correlation/{correlation.heatmap.pdf,correlation.heatmap.png,correlation.xls.xls} $stat[1]" if(! $opt{s2} && -d $stat[1]);
		system "ln -s $genedir/GeneStat/genebox/{group.genebox.pdf,group.genebox.png,gene.num.txt} $stat[2]" if(-d $stat[2]);
        if (-s "$genedir/GeneStat/venn_flower" && -d $stat[3]){
		    for my $temp(`ls $genedir/GeneStat/venn_flower/{*pdf,*png,*svg}`){chomp $temp;system "ln -s $temp $stat[3]"}
        }
        if(-s "$genedir/GeneStat/venn_flower/venndata"){system "cp -rf $genedir/GeneStat/venn_flower/venndata $stat[3]";}
        if(-s "$genedir/GeneStat/venn_flower/flowerdata"){system "cp -rf $genedir/GeneStat/venn_flower/flowerdata $stat[3]";}
		#remove the empty dirs such as correlation 2015-11-11
		for (@stat){
            `rmdir $_` if (!-s $_);	
		}
		
  }
}
##04.TaxAnnotation
if($opt{step}=~/4/){
if(-s "$indir/04.TaxAnnotation"){ 
    (-d $dir[3]) || mkdir($dir[3]);
    my @TaxAnno;
    $opt{s2}?(@TaxAnno=qw(MAT MicroNR_Anno top)):(@TaxAnno=qw(MAT MicroNR_Anno Cluster_Tree heatmap PCA PCoA top NMDS));
	for (@TaxAnno){
        (-d "$dir[3]/$_") || mkdir"$dir[3]/$_";
    }
#heatmap	
	$opt{s2} || (-d "$dir[3]/heatmap/figure") || mkdir("$dir[3]/heatmap/figure");
	$opt{s2} || (-d "$dir[3]/heatmap/table") || mkdir("$dir[3]/heatmap/table");	
	if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap"){
	   system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap/cluster.{k,p,c,o,f,g,s}.txt $dir[3]/heatmap/table" if(! $opt{s2});
 
	   system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap/cluster.{k,p,c,o,f,g,s}.{pdf,png} $dir[3]/heatmap/figure" if(! $opt{s2});
	}
#heatmap_group
if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap_group"){
$opt{s2} || (-d "$dir[3]/heatmap_group/figure") || `mkdir -p "$dir[3]/heatmap_group/figure"`;
$opt{s2} || (-d "$dir[3]/heatmap_group/table") || `mkdir -p "$dir[3]/heatmap_group/table"`;
    system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap_group/cluster.{k,p,c,o,f,g,s}.txt $dir[3]/heatmap_group/table" if(! $opt{s2});
    system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/heatmap_group/cluster.{k,p,c,o,f,g,s}.{pdf,png} $dir[3]/heatmap_group/figure" if(! $opt{s2});
     }

#cluster	
	if (! $opt{s2} && -s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/cluster"){
       (-d "$dir[3]/Cluster_Tree/figure") || mkdir("$dir[3]/Cluster_Tree/figure");
       (-d "$dir[3]/Cluster_Tree/table") || mkdir("$dir[3]/Cluster_Tree/table");
       system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/cluster/*.{k,p,c,o,f,g,s}10.{svg,png} $dir[3]/Cluster_Tree/figure";
       system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/cluster/*.cluster.xls $dir[3]/Cluster_Tree/table";	   	   
    }
#MAT	
	(-d "$dir[3]/MAT/Relative")||mkdir("$dir[3]/MAT/Relative");
	(-d "$dir[3]/MAT/Absolute")||mkdir("$dir[3]/MAT/Absolute");	
	system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/Relative/*.xls $dir[3]/MAT/Relative";
#	system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/Relative/heatmap $dir[3]/MAT/Relative" if(!$opt{s2});
	system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/EvenAbsolute/*.{k,p,c,o,f,g,s}.xls $dir[3]/MAT/Absolute";
    system" ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/{Unigenes.lca.tax.detail.xls,Unigenes.lca.tax.xls,Unigenes.m8.tax.xls,Unigenes.screening.m8.xls,Unigenes.absolute.total.tax.xls} $dir[3]/MicroNR_Anno";#add Unigenes.absolute.total.tax.xls zhanghao 20180104
	
#PCA
	if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/PCA" && ! $opt{s2}){
	    for(qw(class family genus order phylum species)){
	        (-d "$dir[3]/PCA/$_") || mkdir ("$dir[3]/PCA/$_");
	        system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/PCA/$_/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.png,PCA12_with_cluster_2.pdf,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[3]/PCA/$_ ";
	    }
	}

#PCoA 
 if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/PCoA" && ! $opt{s2}){
       for(qw(class family genus order phylum species)){
           (-d "$dir[3]/PCoA/$_") || mkdir ("$dir[3]/PCoA/$_");
            system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/PCoA/$_/{PCoA12_2.pdf,PCoA12_2.png,PCoA12.pdf,PCoA12.png,PCoA.csv,BCD.xls,PCoA12_withcluster_2.pdf,PCoA12_withcluster_2.png,PCoA12_withcluster.pdf,PCoA12_withcluster.png} $dir[3]/PCoA/$_ ";
       }
   }

#NMDS
    if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/NMDS" && ! $opt{s2}){
        for(qw(class family genus order phylum species)){
            (-d "$dir[3]/NMDS/$_") || mkdir ("$dir[3]/NMDS/$_");
            system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/NMDS/$_/{NMDS_2.pdf,NMDS_2.png,NMDS.pdf,NMDS.png,NMDS_scores.txt,NMDS_withcluster_2.pdf,NMDS_withcluster_2.png,NMDS_withcluster.pdf,NMDS_withcluster.png} $dir[3]/NMDS/$_ ";
        }
    }

#top tax	
	(-d "$dir[3]/top/figure") || `mkdir -p "$dir[3]/top/figure"`;
	(-d "$dir[3]/top/table") || `mkdir -p "$dir[3]/top/table"`;
	system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/top/{k,p,c,o,f,g,s}10.dis.{png,svg} $dir[3]/top/figure" || warn $!;
	system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/top/table.{k,p,c,o,f,g,s}10.tran.xls $dir[3]/top/table" || warn $!;
#top_group_tax
    if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/top_group" && ! $opt{s2}){
        (-d "$dir[3]/top_group/figure") || `mkdir -p "$dir[3]/top_group/figure"`;
        (-d "$dir[3]/top_group/table") || `mkdir -p "$dir[3]/top_group/table"`;
        system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/top_group/{k,p,c,o,f,g,s}10.group.dis.{png,svg} $dir[3]/top_group/figure" || warn $!;
        system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/top_group/table.{k,p,c,o,f,g,s}10.tran.group.xls $dir[3]/top_group/table" || warn $!;
    }

#Krona
    my $Kronadir="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/Krona";
	if (-s $Kronadir){
	   (-d "$dir[3]/Krona") || `mkdir -p $dir[3]/Krona`;
	   system "ln -s $Kronadir/taxonomy.krona.html $dir[3]/Krona";#don't need "img,src" now,edit by yelei,2016-03-30 
       system "cp -r $Kronadir/img $dir[3]/Krona";
       system "cp -r $Kronadir/src $dir[3]/Krona"; #local krona,edit by zhangjing 2017-03-03
#system "ln -s $Kronadir/taxonomy.krona.html.files $dir[3]/Krona" if(-s "$Kronadir/taxonomy.krona.html.files");#yu 2015-11-11	   
	}
	
#GeneNums
    if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/GeneNums"){
	    system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/GeneNums $dir[3]";		
	}
	
#GeneNums.BetweenSamples
    if (-s "$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/GeneNums.BetweenSamples"){
	    system "ln -s $indir/04.TaxAnnotation/MicroNR/MicroNR_stat/GeneNums.BetweenSamples $dir[3]";
	}	
	
#GeneNums.BetweenSamples.heatmap
    my $gehmp="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/GeneNums.BetweenSamples.heatmap";
    if (-s $gehmp && !$opt{s2}){
	    for(qw(class family genus kingdom order phylum species)){
		   (-d "$dir[3]/GeneNums.BetweenSamples.heatmap/$_") || `mkdir -p $dir[3]/GeneNums.BetweenSamples.heatmap/$_`;
	       system "ln -s $gehmp/$_/{*.txt,*.png,*.pdf} $dir[3]/GeneNums.BetweenSamples.heatmap/$_";
		}
	}		

#MetaStats
    my $matstats="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/MetaStats";
    if (!$opt{s2} && -s $matstats){
	    for(qw(class family genus kingdom order phylum species)){
		    (-d "$dir[3]/MetaStats/$_")|| `mkdir -p $dir[3]/MetaStats/$_`;
            for my $temp(`ls $matstats/$_/{*.diff.png,*.diff.pdf,*diff.txt,*_diff_relative.xls,*_qsig.xls,*.psig.xls,*.qsig.xls,*.test.xls}`){
                chomp $temp;
                system "ln -s $temp $dir[3]/MetaStats/$_";#*_diff_relative*.xls,$_.xls,*.diff.txt,*.diff.png,*.diff.pdf
            }
			if(-s "$matstats/$_/boxplot/"){
                (-d "$dir[3]/MetaStats/$_/boxplot")|| `mkdir -p $dir[3]/MetaStats/$_/boxplot`;
                system "ln -s $matstats/$_/boxplot/{figures,*.png,*.svg,*.pdf,combine_box/{*.pdf,*.png}} $dir[3]/MetaStats/$_/boxplot";
            }
			if(-s "$matstats/$_/PCA/PCA12.png"){#vs,files,
			   (-d "$dir[3]/MetaStats/$_/PCA") || `mkdir -p $dir[3]/MetaStats/$_/PCA`;
		       system "ln -s $matstats/$_/PCA/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.png,PCA12_with_cluster_2.pdf,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[3]/MetaStats/$_/PCA";	
			}	    
		}
	}
	
#LDA and ROC
    my $lda="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/LDA_ROC";
    if (!$opt{s2} && -s $lda){
        for my $d(`ls $lda/`){
            chomp $d;
            my @l=split /_/,$d;
            if( -d "$lda/$d/" && -s "$lda/$d/LDA.$l[0].tree.png"){ 
                (-d "$dir[3]/LDA/$d/") || `mkdir -p $dir[3]/LDA/$d/`;
                for my $temp(`ls $lda/$d/{*.png,*.pdf,*.res}`){
                    chomp $temp;
                    system"ln -s $temp $dir[3]/LDA/$d/";
                }
            }
            if(-s "$lda/$d/heatmap/cluster.pdf"){
                (-d "$dir[3]/LDA/$d/heatmap") || `mkdir -p $dir[3]/LDA/$d/heatmap/`;
                for my $temp(`ls $lda/$d/heatmap/{*.png,*.pdf,*.txt}`){
                    chomp $temp;
                    system"ln -s $temp $dir[3]/LDA/$d/heatmap";
                }
            }
            my @temp=split/_/,$d;
            if(-s "$lda/$d/ROC/$temp[-1]\_ROC.png"){
                (-d "$dir[3]/LDA/$d/ROC") || `mkdir -p $dir[3]/LDA/$d/ROC/`;
                for my $temp(`ls $lda/$d/ROC/{*.png,*.pdf,*probabilty.xls}`){
                    chomp $temp;
                    system"ln -s $temp $dir[3]/LDA/$d/ROC";
                }
            }
        }
    }
###RandForest ROC 
    my $rf="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/rf_roc";
    if (!$opt{s2} && -s $rf)
	{
	    for my $rank (qw(class family genus kingdom order phylum species))
		{
			if (-s "$rf/$rank/trainset_group_max_roc.png")
			{
				(-s "$dir[3]/rf_roc/$rank") || `mkdir -p $dir[3]/rf_roc/$rank`;
				for my $temp (`ls $rf/$rank/`) 
				{
					chomp $temp;
					system ("cp -rf $rf/$rank/*.png $dir[3]/rf_roc/$rank ") if ($temp =~ /.*png/);
					system ("cp -rf $rf/$rank/*.pdf $dir[3]/rf_roc/$rank ") if ($temp =~ /.*pdf/);
					if (-d "$rf/$rank/$temp")
					{
						system("cp -rf $rf/$rank/$temp $dir[3]/rf_roc/$rank");
						system("rm -rf $dir[3]/rf_roc/$rank/$temp/*temp*.xls");
						system("rm -rf $dir[3]/rf_roc/$rank/$temp/*/cross_validation*.xls");
						system("rm -rf $dir[3]/rf_roc/$rank/$temp/*/cross_validation*.txt");
						system("rm -rf $dir[3]/rf_roc/$rank/$temp/*/*.roc.xls");						
					}
					
				}
				
			}
			
		}
	}



#Anosim
    my $anosim="$indir/04.TaxAnnotation/MicroNR/MicroNR_stat/Anosim/";
    if (!$opt{s2} && -s $anosim){
        for my $rank(qw(Class Family Genus Kingdom Order Phylum Species)){
            if (-s "$anosim/$rank/"){ ###change by zhanghao
            (-d "$dir[3]/Anosim/$rank/") || `mkdir -p $dir[3]/Anosim/$rank`;
            system"ln -s $anosim/$rank/{*.png,*.pdf,stat_anosim.txt} $dir[3]/Anosim/$rank";
        }
        }
    }
}else{
    warn "[Warnning]The directory '04.TaxAnnotation' does not exist!\n";
  }
}
##05.FunctionAnnotation
if($opt{step}=~/5/){
if(-s "$indir/05.FunctionAnnotation"){
    (-d $dir[4]) || mkdir($dir[4]);
#CAZy
	if (-s "$indir/05.FunctionAnnotation/CAZy"){  
	    (-d "$dir[4]/CAZy") || mkdir("$dir[4]/CAZy");
	    my @CazyAnno;
    	$opt{s2}?(@CazyAnno=qw(CAZy_MAT CAZy_Anno)):(@CazyAnno=qw(CAZy_MAT CAZy_Anno heatmap PCA PCoA NMDS));
	    foreach(@CazyAnno){
		   (-d "$dir[4]/CAZy/$_") || mkdir("$dir[4]/CAZy/$_");
	    }
#
	    if (-s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat"){
            (-d "$dir[4]/CAZy/CAZy_MAT/Absolute") || mkdir("$dir[4]/CAZy/CAZy_MAT/Absolute");
            (-d "$dir[4]/CAZy/CAZy_MAT/Relative") || mkdir("$dir[4]/CAZy/CAZy_MAT/Relative");			
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/EvenAbsolute/*.xls $dir[4]/CAZy/CAZy_MAT/Absolute";		  
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/Relative/*.xls $dir[4]/CAZy/CAZy_MAT/Relative";	
#		    system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/Relative/heatmap $dir[4]/CAZy/CAZy_MAT/Relative" if(!$opt{s2});
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/{*png,*pdf,*svg} $dir[4]/CAZy/CAZy_Anno";	
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/DrawAnnotationPic.R.txt $dir[4]/CAZy/CAZy_Anno/cazy.unigenes.num.txt";
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/Unigenes.filter.xls $dir[4]/CAZy/CAZy_Anno/Unigenes.blast.m8.filter.xls";
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/Unigenes.filter.anno.xls $dir[4]/CAZy/CAZy_Anno/Unigenes.blast.m8.filter.anno.xls";			  
            system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/Unigenes.CAZY.tax.xls $dir[4]/CAZy/CAZy_Anno/";
#	     ($opt{s2}) && system"rm -f $dir[4]/CAZy/CAZy_Anno/Unique.Genes.level1.bar.tree.*";
	        system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/heatmap/cluster.*.{pdf,png,txt} $dir[4]/CAZy/heatmap" if(!$opt{s2});
		 
		 #PCA
		    my $cpca="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/PCA";
		    if((!$opt{s2}) && -s $cpca){
                for (qw(ec level1 level2)){
			       (-d "$dir[4]/CAZy/PCA/$_") || `mkdir -p $dir[4]/CAZy/PCA/$_`;
		           system "ln -s $cpca/$_/{PCA12_2.{pdf,png},PCA12.{pdf,png},pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/CAZy/PCA/$_";			   
			    }
		    }
       
        #heatmap_group
         my $heatmap_group="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/heatmap_group";
        if (( !$opt{s2}) && -s $heatmap_group){
           (-d "$dir[4]/CAZy/heatmap_group") || `mkdir -p $dir[4]/CAZy/heatmap_group`;
          system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/heatmap_group/cluster.*.{pdf,png,txt} $dir[4]/CAZy/heatmap_group";
        }
       if (-s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat/top"){
       (-d "$dir[4]/CAZy/top/figure") || `mkdir -p "$dir[4]/CAZy/top/figure"`;
       (-d "$dir[4]/CAZy/top/table") || `mkdir -p "$dir[4]/CAZy/top/table"`;
 system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/top/{level1,ec,level2}.top10.{png,svg} $dir[4]/CAZy/top/figure" || warn $!;
system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/top/table.{level1,ec,level2}.tran10.xls $dir[4]/CAZy/top/table" || warn $!;
       }
      if (( !$opt{s2}) && -s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat/top_group"){
      (-d "$dir[4]/CAZy/top_group/figure") || `mkdir -p "$dir[4]/CAZy/top_group/figure"`;
      (-d "$dir[4]/CAZy/top_group/table") || `mkdir -p "$dir[4]/CAZy/top_group/table"`;
      system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/top_group/{level1,ec,level2}.group.top10.{png,svg} $dir[4]/CAZy/top_group/figure" || warn$!;
      system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/top_group/table.{level1,ec,level2}.group.tran10.xls $dir[4]/CAZy/top_group/table" || warn $!;
      }

          #PCoA 
           my $cpcoa="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/PCoA";
           if((!$opt{s2}) && -s $cpcoa){
               for (qw(ec level1 level2)){
                  (-d "$dir[4]/CAZy/PCoA/$_") || `mkdir -p $dir[4]/CAZy/PCoA/$_`;
                  system "ln -s $cpcoa/$_/{PCoA12_2.{pdf,png},PCoA12.{pdf,png},PCoA.csv,BCD.xls,PCoA12_withcluster_2.pdf,PCoA12_withcluster_2.png,PCoA12_withcluster.pdf,PCoA12_withcluster.png} $dir[4]/CAZy/PCoA/$_";
               }
           }

         #NMDS
            if(!$opt{s2} && -s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat/NMDS"){
                for (qw(ec level1 level2)){
                    (-d "$dir[4]/CAZy/NMDS/$_") || `mkdir -p $dir[4]/CAZy/NMDS/$_`;
                    system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/NMDS/$_/{NMDS_2.pdf,NMDS_2.png,NMDS.pdf,NMDS.png,NMDS_scores.txt,NMDS_withcluster_2.pdf,NMDS_withcluster_2.png,NMDS_withcluster.pdf,NMDS_withcluster.png} $dir[4]/CAZy/NMDS/$_";
                }
            }
		
         #GeneNums
            if (-s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat/GeneNums"){
	            system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/GeneNums $dir[4]/CAZy";		
	        }
	
         #GeneNums.BetweenSamples
            if (-s "$indir/05.FunctionAnnotation/CAZy/CAZy_stat/GeneNums.BetweenSamples"){
	            system "ln -s $indir/05.FunctionAnnotation/CAZy/CAZy_stat/GeneNums.BetweenSamples $dir[4]/CAZy";
	        }	
	
         #GeneNums.BetweenSamples.heatmap
            my $cghmp="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/GeneNums.BetweenSamples.heatmap";
            if (-s $cghmp && !$opt{s2}){
	            for(qw(ec level1 level2)){
		            (-d "$dir[4]/CAZy/GeneNums.BetweenSamples.heatmap/$_") || `mkdir -p $dir[4]/CAZy/GeneNums.BetweenSamples.heatmap/$_`;
	                system "ln -s $cghmp/$_/{*.txt,*.png,*.pdf} $dir[4]/CAZy/GeneNums.BetweenSamples.heatmap/$_";
		        }
	        }		
		
		#Metastats
		    my $matstats="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/Metastats";
            if (-s $matstats){
	            for(qw(EC level2 level1)){
		            (-d "$dir[4]/CAZy/MetaStats/$_")|| `mkdir -p $dir[4]/CAZy/MetaStats/$_`;
                    for my $temp(`ls $matstats/$_/{*.diff.png,*.diff.pdf,*diff.txt,*_diff_relative.xls,*_qsig.xls,*.psig.xls,*.qsig.xls,*.test.xls}`){
                        chomp $temp;
                        system "ln -s $temp $dir[4]/CAZy/MetaStats/$_";
                    }
			        if(-s "$matstats/$_/boxplot/"){
                        (-d "$dir[4]/CAZy/MetaStats/$_/boxplot" || `mkdir -p $dir[4]/CAZy/MetaStats/$_/boxplot`);
                        system "ln -s $matstats/$_/boxplot/{figures,*.png,*.svg,*.pdf,combine_box/{*.pdf,*.png}} $dir[4]/CAZy/MetaStats/$_/boxplot";
                    }
			        if(!$opt{s2} && -s "$matstats/$_/PCA/PCA12.png"){
			            (-d "$dir[4]/CAZy/MetaStats/$_/PCA") || `mkdir -p $dir[4]/CAZy/MetaStats/$_/PCA`;
		                system "ln -s $matstats/$_/PCA/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/CAZy/MetaStats/$_/PCA";
			        }	    
		        }
	        }#for if (-s $matstats)

       #LDA and ROC
            my $lda="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/LDA_ROC";
            if(!$opt{s2} && -s $lda){
                for my $rank(qw(level2 EC level1)){
                    (-s "$lda/$rank") || next;
                    for my $d(`ls $lda/$rank`){
                        chomp $d;
                        my @l=split /_/,$d;
                        if( -d "$lda/$rank/$d/" && -s "$lda/$rank/$d/LDA/LDA.$l[0].png"){
                            (-d "$dir[4]/CAZy/LDA/$rank/$d/LDA") || `mkdir -p $dir[4]/CAZy/LDA/$rank/$d/LDA`;
                            for my $temp(`ls $lda/$rank/$d/LDA/{*.png,*.pdf,*.res}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/CAZy/LDA/$rank/$d/LDA";
                            }
                        }
                        if(-s "$lda/$rank/$d/heatmap/cluster.pdf"){
                            (-d "$dir[4]/CAZy/LDA/$rank/$d/heatmap") || `mkdir -p $dir[4]/CAZy/LDA/$rank/$d/heatmap`;
                            for my $temp(`ls $lda/$rank/$d/heatmap/{*.png,*.pdf,*.txt}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/CAZy/LDA/$rank/$d/heatmap";
                            }
                        }
                        my @temp=split/_/,$d;
                        if(-s "$lda/$rank/$d/ROC/$temp[-1]\_ROC.png"){
                            (-d "$dir[4]/CAZy/LDA/$rank/$d/ROC/") || `mkdir -p $dir[4]/CAZy/LDA/$rank/$d/ROC/`;
                            for my $temp(`ls $lda/$rank/$d/ROC/{*.png,*.pdf,*probabilty.xls}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/CAZy/LDA/$rank/$d/ROC/";
                            }
                        }
                    }
                }
            }
####RandForest roc 
    my $rf="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/rf_roc";
    if (!$opt{s2} && -s $rf)
	{
	    for my $rank (qw(level2 EC level1))
		{
			if (-s "$rf/$rank/trainset_group_max_roc.png")
			{
				(-s "$dir[4]/CAZy/rf_roc/$rank/") || `mkdir -p $dir[4]/CAZy/rf_roc/$rank/`;
				for my $temp (`ls $rf/$rank/`) 
				{
					chomp $temp;
					system ("cp -rf $rf/$rank/*.png $dir[4]/CAZy/rf_roc/$rank/ ") if ($temp =~ /.*png/);
					system ("cp -rf $rf/$rank/*.pdf $dir[4]/CAZy/rf_roc/$rank/ ") if ($temp =~ /.*pdf/);
					if (-d "$rf/$rank/$temp")
					{
						system("cp -rf $rf/$rank/$temp $dir[4]/CAZy/rf_roc/$rank/");
						system("rm -rf $dir[4]/CAZy/rf_roc/$rank/$temp/*temp*.xls");
						system("rm -rf $dir[4]/CAZy/rf_roc/$rank/$temp/*/cross_validation*.xls");
						system("rm -rf $dir[4]/CAZy/rf_roc/$rank/$temp/*/cross_validation*.txt");
						system("rm -rf $dir[4]/CAZy/rf_roc/$rank/$temp/*/*.roc.xls");						
					}
					
				}
				
			}
			
		}
	}
       #Anosim
            my $anosim="$indir/05.FunctionAnnotation/CAZy/CAZy_stat/Anosim/";
            if (!$opt{s2} && -s $anosim){
                for my $rank(qw(level2 ec level1)){
                    (-s "$anosim/$rank/") || next; ###change by zhanghao 20171204
                    (-d "$dir[4]/CAZy/Anosim/$rank/") || `mkdir -p $dir[4]/CAZy/Anosim/$rank/`;
                    system "ln -s $anosim/$rank/{*.png,*.pdf,stat_anosim.txt} $dir[4]/CAZy/Anosim/$rank/";
                }
            }
        }
    }


#eggNOG
	if (-s "$indir/05.FunctionAnnotation/eggNOG"){  
	    (-d "$dir[4]/eggNOG") || mkdir("$dir[4]/eggNOG");
	    my @eggAnno;
    	$opt{s2}?(@eggAnno=qw(eggNOG_MAT eggNOG_Anno)):(@eggAnno=qw(eggNOG_MAT eggNOG_Anno heatmap PCA PCoA));
	    foreach(@eggAnno){
		    (-d "$dir[4]/eggNOG/$_") || mkdir("$dir[4]/eggNOG/$_");
		}
#     
        my $estat= "$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/";
	    if (-s $estat){
	        (-d "$dir[4]/eggNOG/eggNOG_MAT/Absolute") || mkdir("$dir[4]/eggNOG/eggNOG_MAT/Absolute");
		    (-d "$dir[4]/eggNOG/eggNOG_MAT/Relative") || mkdir("$dir[4]/eggNOG/eggNOG_MAT/Relative");
	        system "ln -s $estat/EvenAbsolute/*.xls $dir[4]/eggNOG/eggNOG_MAT/Absolute";		  
	        system "ln -s $estat/Relative/*.xls $dir[4]/eggNOG/eggNOG_MAT/Relative"; 
#		    system "ln -s $estat/Relative/heatmap $dir[4]/eggNOG/eggNOG_MAT/Relative" if(!$opt{s2});
		  
#	        system "ln -s $estat/{Unigenes.filter.anno.xls,Unigenes.filter.xls,DrawAnnotationPic.R.txt,*.png,*.pdf,*.svg,} $dir[4]/eggNOG/eggNOG_Anno";		  
	        system "ln -s $estat/{*png,*pdf,*svg} $dir[4]/eggNOG/eggNOG_Anno";	
	        system "ln -s $estat/DrawAnnotationPic.R.txt $dir[4]/eggNOG/eggNOG_Anno/eggNOG.unigenes.num.txt";
	        system "ln -s $estat/Unigenes.filter.xls $dir[4]/eggNOG/eggNOG_Anno/Unigenes.blast.m8.filter.xls";
	        system "ln -s $estat/Unigenes.filter.anno.xls $dir[4]/eggNOG/eggNOG_Anno/Unigenes.blast.m8.filter.anno.xls";			  
            system "ln -s $estat/Unigenes.eggNOG.tax.xls $dir[4]/eggNOG/eggNOG_Anno/";
		  
#	      ($opt{s2}) && system"rm -f $dir[4]/eggNOG/eggNOG_Anno/Unique.Genes.level1.bar.tree.*";

          #heatmap	
	        system "ln -s $estat/heatmap/cluster.*.{pdf,png,txt} $dir[4]/eggNOG/heatmap" if(!$opt{s2});
          #heatmap_group
           if(!$opt{s2} && -s "$estat/heatmap_group"){
               (-d "$dir[4]/eggNOG/heatmap_group") || `mkdir -p $dir[4]/eggNOG/heatmap_group`;
               system "ln -s $estat/heatmap_group/cluster.*.{pdf,png,txt} $dir[4]/eggNOG/heatmap_group";
           }
	      #nog.tax
#system "ln -s $estat/NOG.Tax/ $dir[4]/eggNOG/NOG.Tax";   annotation change by zhangjing at 2017-04-20
		 if (-s "$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top"){
            (-d "$dir[4]/eggNOG/top/figure") || `mkdir -p "$dir[4]/eggNOG/top/figure"`;
           (-d "$dir[4]/eggNOG/top/table") || `mkdir -p "$dir[4]/eggNOG/top/table"`;
          system "ln -s $indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top/{level1,og,level2}.top10.{png,svg} $dir[4]/eggNOG/top/figure" || warn $!;
         system "ln -s $indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top/table.{level1,og,level2}.tran10.xls $dir[4]/eggNOG/top/table" || warn $!;
         }
        if (( !$opt{s2}) && -s "$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top_group"){
           (-d "$dir[4]/eggNOG/top_group/figure") || `mkdir -p "$dir[4]/eggNOG/top_group/figure"`;
          (-d "$dir[4]/eggNOG/top_group/table") || `mkdir -p "$dir[4]/eggNOG/top_group/table"`;
         system "ln -s $indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top_group/{level1,og,level2}.group.top10.{png,svg} $dir[4]/eggNOG/top_group/figure" || warn$!;
        system "ln -s $indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/top_group/table.{level1,og,level2}.group.tran10.xls $dir[4]/eggNOG/top_group/table" || warn $!;
        } 
		  #PCA
	        if(!$opt{s2} && -s "$estat/PCA"){
		        for (qw(level1 level2 og)){
		            (-d "$dir[4]/eggNOG/PCA/$_") || `mkdir -p $dir[4]/eggNOG/PCA/$_`;	
	                system "ln -s $estat/PCA/$_/{PCA12_2.{pdf,png},PCA12.{pdf,png},pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/eggNOG/PCA/$_";		
	            }
	   	    }
        
          #PCoA 
            if(!$opt{s2} && -s "$estat/PCoA"){
               for (qw(level1 level2 og)){
                  (-d "$dir[4]/eggNOG/PCoA/$_") || `mkdir -p $dir[4]/eggNOG/PCoA/$_`; 
                  system "ln -s $estat/PCoA/$_/{PCoA12_2.{pdf,png},PCoA12.{pdf,png},PCoA.csv,BCD.xls,PCoA12_withcluster_2.pdf,PCoA12_withcluster_2.png,PCoA12_withcluster.pdf,PCoA12_withcluster.png} $dir[4]/eggNOG/PCoA/$_";
               }
            }

          #NMDS
            if(!$opt{s2} && -s "$estat/NMDS"){
                for(qw(level1 level2 og)){
                    (-d "$dir[4]/eggNOG/NMDS/$_") || `mkdir -p $dir[4]/eggNOG/NMDS/$_`;
                    system "ln -s $estat/NMDS/$_/{NMDS_2.pdf,NMDS_2.png,NMDS.pdf,NMDS.png,NMDS_scores.txt,NMDS_withcluster_2.pdf,NMDS_withcluster_2.png,NMDS_withcluster.pdf,NMDS_withcluster.png} $dir[4]/eggNOG/NMDS/$_";
                }
            }
		  		  
		  #GeneNums
            if (-s "$estat/GeneNums"){
	           system "ln -s $estat/GeneNums $dir[4]/eggNOG/";		
	        }
	
          #GeneNums.BetweenSamples
            if (-s "$estat/GeneNums.BetweenSamples"){
	           system "ln -s $estat/GeneNums.BetweenSamples $dir[4]/eggNOG";
	        }	
	
          #GeneNums.BetweenSamples.heatmap
            my $eghmp="$estat/GeneNums.BetweenSamples.heatmap";
            if (-s $eghmp && !$opt{s2}){
	           for(qw(level1 og)){
		          (-d "$dir[4]/eggNOG/GeneNums.BetweenSamples.heatmap/$_") || `mkdir -p $dir[4]/eggNOG/GeneNums.BetweenSamples.heatmap/$_`;
	              system "ln -s $eghmp/$_/{*.txt,*.png,*.pdf} $dir[4]/eggNOG/GeneNums.BetweenSamples.heatmap/$_";
		       }
	        }
		
		  #Metastats
		    my $matstats="$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/Metastats";#eggNOG/eggNOG_MAT
            if (-s $matstats){
	            for(qw(level1 level2 og)){
		            (-d "$dir[4]/eggNOG/MetaStats/$_/")|| `mkdir -p $dir[4]/eggNOG/MetaStats/$_/`;
                    for my $temp(`ls $matstats/$_/{*.diff.png,*.diff.pdf,*diff.txt,*_diff_relative.xls,*_qsig.xls,*.psig.xls,*.qsig.xls,*.test.xls}`){
                        chomp $temp;
                        system "ln -s $temp $dir[4]/eggNOG/MetaStats/$_";
                    }
			        if(-s "$matstats/$_/boxplot/"){
                        (-d "$dir[4]/eggNOG/MetaStats/$_/boxplot/" || `mkdir -p $dir[4]/eggNOG/MetaStats/$_/boxplot/`);
                        system "ln -s $matstats/$_/boxplot/{figures,*.png,*.svg,*.pdf,combine_box/{*.pdf,*.png}} $dir[4]/eggNOG/MetaStats/$_/boxplot";
                    }
			        if (-s "$matstats/$_/og.trees/") {
			  	        system "ln -s $matstats/$_/og.trees/ $dir[4]/eggNOG/MetaStats/$_/og.trees";
			        }
			        if(!$opt{s2} && -s "$matstats/$_/PCA/PCA12.png"){ 
			            (-d "$dir[4]/eggNOG/MetaStats/$_/PCA") || `mkdir -p $dir[4]/eggNOG/MetaStats/$_/PCA`;
		                system "ln -s $matstats/$_/PCA/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/eggNOG/MetaStats/$_/PCA";
			        }	    
		        }
	        }
		  
		  #NOG.Tax
		    if(-s "$indir/05.FunctionAnnotation/eggNOG_stat/NOG.Tax"){
		        system "$indir/05.FunctionAnnotation/eggNOG_stat/NOG.Tax $dir[4]/eggNOG/";	  
		    }		 
          
          #LDA and ROC
            my $lda="$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/LDA_ROC";
            if(!$opt{s2} && -s $lda){
                for my $rank(qw(level2 level1)){
                    (-s "$lda/$rank/") || next;
                    for my $d(`ls $lda/$rank/`){
                        chomp $d;
                        my @l=split /_/,$d;
                        if( -d "$lda/$rank/$d/" && -s "$lda/$rank/$d/LDA/LDA.$l[0].png"){
                            (-d "$dir[4]/eggNOG/LDA/$rank/$d/LDA/") || `mkdir -p $dir[4]/eggNOG/LDA/$rank/$d/LDA/`;
                            for my $temp(`ls $lda/$rank/$d/LDA/{*.png,*.pdf,*.res}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/eggNOG/LDA/$rank/$d/LDA/";
                            }
                        }
                        if(-s "$lda/$rank/$d/heatmap/cluster.pdf"){
                            (-d "$dir[4]/eggNOG/LDA/$rank/$d/heatmap/") || `mkdir -p $dir[4]/eggNOG/LDA/$rank/$d/heatmap/`;
                            for my $temp(`ls $lda/$rank/$d/heatmap/{*.png,*.pdf,*.txt}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/eggNOG/LDA/$rank/$d/heatmap/";
                            }
                        }
                        my @temp=split/_/,$d;
                        if(-s "$lda/$rank/$d/ROC/$temp[-1]\_ROC.png"){
                            (-d "$dir[4]/eggNOG/LDA/$rank/$d/ROC/") || `mkdir -p $dir[4]/eggNOG/LDA/$rank/$d/ROC/`;
                            for my $temp(`ls $lda/$rank/$d/ROC/{*.png,*.pdf,*probabilty.xls}`){
                                chomp $temp;
                                system "ln -s $temp $dir[4]/eggNOG/LDA/$rank/$d/ROC/";
                            }
                        }
                    }
                }
            }

####RandForest roc 
    my $rf="$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/rf_roc";
    if (!$opt{s2} && -s $rf)
	{
	    for my $rank (qw(level2 og level1))
		{
			if (-s "$rf/$rank/trainset_group_max_roc.png")
			{
				(-s "$dir[4]/eggNOG/rf_roc/$rank/") || `mkdir -p $dir[4]/eggNOG/rf_roc/$rank/`;
				for my $temp (`ls $rf/$rank/`) 
				{
					chomp $temp;
					system ("cp -rf $rf/$rank/*.png $dir[4]/eggNOG/rf_roc/$rank/ ") if ($temp =~ /.*png/);
					system ("cp -rf $rf/$rank/*.pdf $dir[4]/eggNOG/rf_roc/$rank/ ") if ($temp =~ /.*pdf/);
					if (-d "$rf/$rank/$temp")
					{
						system("cp -rf $rf/$rank/$temp $dir[4]/eggNOG/rf_roc/$rank/");
						system("rm -rf $dir[4]/eggNOG/rf_roc/$rank/$temp/*temp*.xls");
						system("rm -rf $dir[4]/eggNOG/rf_roc/$rank/$temp/*/cross_validation*.xls");
						system("rm -rf $dir[4]/eggNOG/rf_roc/$rank/$temp/*/cross_validation*.txt");
						system("rm -rf $dir[4]/eggNOG/rf_roc/$rank/$temp/*/*.roc.xls");
						
					}
					
				}
				
			}
			
		}
	}
          #Anosim
            my $anosim="$indir/05.FunctionAnnotation/eggNOG/eggNOG_stat/Anosim";
            if (!$opt{s2} && -s $anosim){
               for my $rank(qw(og level1 level2)){
                   (-s "$anosim/$rank/") || next; ###change by zhangao 20171204
                   (-d "$dir[4]/eggNOG/Anosim/$rank") || `mkdir -p $dir[4]/eggNOG/Anosim/$rank`;
                   system "ln -s $anosim/$rank/{*.png,*.pdf,stat_anosim.txt} $dir[4]/eggNOG/Anosim/$rank/";
               }
            }
	    }
#eggNOG end	   
    }#eggNOG
	
#KEGG	
	if (-s "$indir/05.FunctionAnnotation/KEGG"){ #KEGG 
	   (-d "$dir[4]/KEGG") || mkdir("$dir[4]/KEGG");
	    my @keggAnno;
    	$opt{s2}?(@keggAnno=qw(KEGG_MAT KEGG_Anno)):(@keggAnno=qw(KEGG_MAT KEGG_Anno heatmap PCA PCoA));
	    foreach(@keggAnno){
		   (-d "$dir[4]/KEGG/$_") || mkdir("$dir[4]/KEGG/$_");
		}
#		
        my $kstat="$indir/05.FunctionAnnotation/KEGG/KEGG_stat";
        (-d "$dir[4]/KEGG/KEGG_MAT/Absolute") || mkdir("$dir[4]/KEGG/KEGG_MAT/Absolute");
        (-d "$dir[4]/KEGG/KEGG_MAT/Relative") || mkdir("$dir[4]/KEGG/KEGG_MAT/Relative");		
	    system "ln -s $kstat/EvenAbsolute/*.xls $dir[4]/KEGG/KEGG_MAT/Absolute";		
	    system "ln -s $kstat/Relative/*.xls $dir[4]/KEGG/KEGG_MAT/Relative";
#	    system "ln -s $kstat/Relative/heatmap $dir[4]/KEGG/KEGG_MAT/Relative" if(!$opt{s2});	

#		system "ln -s $kstat/{Unigenes.KEGG.anno.xls,Unigenes.KEGG_blast_m8.filter.xls,*png,*pdf,*svg} $dir[4]/KEGG/KEGG_Anno";
	    system "ln -s $kstat/{*png,*pdf,*svg} $dir[4]/KEGG/KEGG_Anno";	
	    system "ln -s $kstat/DrawAnnotationPic.R.txt $dir[4]/KEGG/KEGG_Anno/kegg.unigenes.num.txt";
	    system "ln -s $kstat/Unigenes.KEGG_blast_m8.filter.xls $dir[4]/KEGG/KEGG_Anno/Unigenes.blast.m8.filter.xls";
	    system "ln -s $kstat/Unigenes.KEGG.anno.xls $dir[4]/KEGG/KEGG_Anno/Unigenes.blast.m8.filter.anno.xls";		
        system "ln -s $kstat/Unigenes.KEGG.tax.xls $dir[4]/KEGG/KEGG_Anno/";
#		($opt{s2}) && system"rm -f $dir[4]/KEGG/KEGG_Anno/Unique.Genes.level1.bar.tree.*";
		
		#pathwaymaps
		my $pathway="$kstat/pathwaymaps";
	    system "ln -s  $pathway $dir[4]/KEGG/" if(-s "$pathway");
        `cp -f $Bin/src/images/KEGG_ReadMe.pdf $dir[4]/KEGG/pathwaymaps` if(-s "$pathway");
	    system "ln -s  $pathway.report $dir[4]/KEGG/" if(-s "$pathway.report");
		
		#heatmap
	    system "ln -s $kstat/heatmap/cluster.*.{pdf,png,txt} $dir[4]/KEGG/heatmap" if(!$opt{s2});
        #heatmap_group
        if(!$opt{s2} && -s "$kstat/heatmap_group"){
            (-d "$dir[4]/KEGG/heatmap_group") || `mkdir -p $dir[4]/KEGG/heatmap_group`;
            system "ln -s $kstat/heatmap_group/cluster.*.{pdf,png,txt} $dir[4]/KEGG/heatmap_group" if(!$opt{s2});
         }
        #top
        if (-s "$indir/05.FunctionAnnotation/KEGG/KEGG_stat/top"){
            (-d "$dir[4]/KEGG/top/figure") || `mkdir -p "$dir[4]/KEGG/top/figure"`;
            (-d "$dir[4]/KEGG/top/table") || `mkdir -p "$dir[4]/KEGG/top/table"`;
            system "ln -s $indir/05.FunctionAnnotation/KEGG/KEGG_stat/top/{level1,ec,level2,ko,level3,module}.top10.{png,svg} $dir[4]/KEGG/top/figure" || warn $!;
            system "ln -s $indir/05.FunctionAnnotation/KEGG/KEGG_stat/top/table.{level1,ec,level2,ko,level3,module}.tran10.xls $dir[4]/KEGG/top/table" || warn $!;
        }
        if (( !$opt{s2}) && -s "$indir/05.FunctionAnnotation/KEGG/KEGG_stat/top_group"){
            (-d "$dir[4]/KEGG/top_group/figure") || `mkdir -p "$dir[4]/KEGG/top_group/figure"`;
            (-d "$dir[4]/KEGG/top_group/table") || `mkdir -p "$dir[4]/KEGG/top_group/table"`;
            system "ln -s $indir/05.FunctionAnnotation/KEGG/KEGG_stat/top_group/{level1,ec,level2,ko,level3,module}.group.top10.{png,svg} $dir[4]/KEGG/top_group/figure" || warn$!;
            system "ln -s $indir/05.FunctionAnnotation/KEGG/KEGG_stat/top_group/table.{level1,ec,level2,ko,level3,module}.group.tran10.xls $dir[4]/KEGG/top_group/table" || warn $!;
        }

        #PCA
        if(!$opt{s2} && -s "$kstat/PCA"){
		    for (qw(ec ko level1 level2 level3 module)){
		        (-d "$dir[4]/KEGG/PCA/$_") || ` mkdir $dir[4]/KEGG/PCA/$_ `;	
	            system "ln -s $kstat/PCA/$_/{PCA12_2.{pdf,png},PCA12.{pdf,png},pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/KEGG/PCA/$_";		
	        }		
	    }

       #PCoA
        if(!$opt{s2} && -s "$kstat/PCoA"){
            for (qw(ec ko level1 level2 level3 module)){
                (-d "$dir[4]/KEGG/PCoA/$_") || ` mkdir $dir[4]/KEGG/PCoA/$_ `;
                system "ln -s $kstat/PCoA/$_/{PCoA12_2.{pdf,png},PCoA12.{pdf,png},PCoA.csv,BCD.xls,PCoA12_withcluster_2.pdf,PCoA12_withcluster_2.png,PCoA12_withcluster.pdf,PCoA12_withcluster.png} $dir[4]/KEGG/PCoA/$_";
            }
        }
        
        #NMDS
        if(!$opt{s2} && -s "$kstat/NMDS"){
            for (qw(ec ko level1 level2 level3 module)){
                (-d "$dir[4]/KEGG/NMDS/$_") || ` mkdir -p $dir[4]/KEGG/NMDS/$_ `;
                system "ln -s $kstat/NMDS/$_/{NMDS_2.pdf,NMDS_2.png,NMDS.pdf,NMDS.png,NMDS_scores.txt,NMDS_withcluster_2.pdf,NMDS_withcluster_2.png,NMDS_withcluster.pdf,NMDS_withcluster.png} $dir[4]/KEGG/NMDS/$_";
            }
        }
            
		#GeneNums
        if (-s "$kstat/GeneNums"){
	        system "ln -s $kstat/GeneNums $dir[4]/KEGG";		
	    }
	
        #GeneNums.BetweenSamples
        if (-s "$kstat/GeneNums.BetweenSamples"){
	       system "ln -s $kstat/GeneNums.BetweenSamples $dir[4]/KEGG";
	    }	
	
        #GeneNums.BetweenSamples.heatmap
        my $kghmp="$kstat/GeneNums.BetweenSamples.heatmap";
        if (-s $kghmp && !$opt{s2}){
	        for(qw(ec ko level2 level1 level3 module)){
		        (-d "$dir[4]/KEGG/GeneNums.BetweenSamples.heatmap/$_") || `mkdir -p $dir[4]/KEGG/GeneNums.BetweenSamples.heatmap/$_`;
	            system "ln -s $kghmp/$_/{*.txt,*.png,*.pdf} $dir[4]/KEGG/GeneNums.BetweenSamples.heatmap/$_";
		    }
	    }		
		
		  #Metastats
		my $matstats="$kstat/Metastats";#KEGG/KEGG_MAT
        if (-s $matstats){
	        for(qw(ec ko level2 level3 module level1)){
		        (-d "$dir[4]/KEGG/MetaStats/$_")|| `mkdir -p $dir[4]/KEGG/MetaStats/$_`;
                for my $temp(`ls $matstats/$_/{*.diff.pdf,*.diff.png,*diff.txt,*.psig.xls,*.qsig.xls,*.test.xls,*_qsig.xls,*_diff_relative.xls}`){
                    chomp $temp;
                    system "ln -s $temp $dir[4]/KEGG/MetaStats/$_";
                }
			    if(-s "$matstats/$_/boxplot/"){
                    (-d "$dir[4]/KEGG/MetaStats/$_/boxplot") || `mkdir -p $dir[4]/KEGG/MetaStats/$_/boxplot`;
                    system "ln -s $matstats/$_/boxplot/{figures,*.png,*.svg} $dir[4]/KEGG/MetaStats/$_/boxplot";
                }
			    if(!$opt{s2} && -s "$matstats/$_/PCA/PCA12.png"){
			        (-d "$dir[4]/KEGG/MetaStats/$_/PCA") || `mkdir -p $dir[4]/KEGG/MetaStats/$_/PCA`;
		            system "ln -s $matstats/$_/PCA/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/KEGG/MetaStats/$_/PCA";
			    }	    
		    }
	    }
        
        #LDA and ROC
        my $lda="$kstat/LDA_ROC";
        if(!$opt{s2} && -s $lda){
            for my $rank(qw(ec ko level1 level2 level3)){
                (-s "$lda/$rank") || next;
                for my $d(`ls $lda/$rank`){
                    chomp $d;
                    my @l=split /_/,$d;
                    if( -d "$lda/$rank/$d/" && -s "$lda/$rank/$d/LDA/LDA.$l[0].png"){
                        (-d "$dir[4]/KEGG/LDA/$rank/$d/LDA") || `mkdir -p $dir[4]/KEGG/LDA/$rank/$d/LDA`;
                        for my $temp(`ls $lda/$rank/$d/LDA/{*.png,*.pdf,*.res}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/KEGG/LDA/$rank/$d/LDA";
                        }
                    }
                    if(-s "$lda/$rank/$d/heatmap/cluster.pdf"){
                        (-d "$dir[4]/KEGG/LDA/$rank/$d/heatmap") || `mkdir -p $dir[4]/KEGG/LDA/$rank/$d/heatmap`;
                        for my $temp(`ls $lda/$rank/$d/heatmap/{*.png,*.pdf,*.txt}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/KEGG/LDA/$rank/$d/heatmap";
                        }
                    }
                    my @temp=split/_/,$d;
                    if(-s "$lda/$rank/$d/ROC/$temp[-1]\_ROC.png"){
                        (-d "$dir[4]/KEGG/LDA/$rank/$d/ROC") || `mkdir -p $dir[4]/KEGG/LDA/$rank/$d/ROC`;
                        for my $temp(`ls $lda/$rank/$d/ROC/{*.png,*.pdf,*probabilty.xls}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/KEGG/LDA/$rank/$d/ROC";
                        }
                    }
                }
            }
        }
####RandForest roc 
    my $rf="$indir/05.FunctionAnnotation/KEGG/KEGG_stat/rf_roc";
    if (!$opt{s2} && -s $rf)
	{
	    for my $rank (qw(ko))
		{
			if (-s "$rf/$rank/trainset_group_max_roc.png")
			{
				(-s "$dir[4]/KEGG/rf_roc/$rank/") || `mkdir -p $dir[4]/KEGG/rf_roc/$rank/`;
				for my $temp (`ls $rf/$rank/`) 
				{
					chomp $temp;
					system ("cp -rf $rf/$rank/*.png $dir[4]/KEGG/rf_roc/$rank/ ") if ($temp =~ /.*png/);
					system ("cp -rf $rf/$rank/*.pdf $dir[4]/KEGG/rf_roc/$rank/ ") if ($temp =~ /.*pdf/);
					if (-d "$rf/$rank/$temp")
					{
						system("cp -rf $rf/$rank/$temp $dir[4]/KEGG/rf_roc/$rank/");
						system("rm -rf $dir[4]/KEGG/rf_roc/$rank/$temp/*temp*.xls");
						system("rm -rf $dir[4]/KEGG/rf_roc/$rank/$temp/*/cross_validation*.xls");
						system("rm -rf $dir[4]/KEGG/rf_roc/$rank/$temp/*/cross_validation*.txt");
						system("rm -rf $dir[4]/KEGG/rf_roc/$rank/$temp/*/*.roc.xls");						
					}
					
				}
				
			}
			
		}
	}
        #Anosim
        my $anosim="$kstat/Anosim";
        if (!$opt{s2} && -s $anosim){
            for my $rank(qw(ec ko level1 level2 level3 module)){
                (-s "$anosim/$rank/") || next; ###change by zhanghao 20171204
                (-d "$dir[4]/KEGG/Anosim/$rank/") || `mkdir -p $dir[4]/KEGG/Anosim/$rank/`;
                system "ln -s $anosim/$rank/{*.png,*.pdf,stat_anosim.txt} $dir[4]/KEGG/Anosim/$rank/";
            }
        }
##KEGG end		
    }#KEGG	 

    #ARDB
    my $ardb="$indir/05.FunctionAnnotation/ARDB/ARDB_stat";
    if(-s "$indir/05.FunctionAnnotation/ARDB"){
        (-d "$dir[4]/ARDB") || `mkdir $dir[4]/ARDB`;
        (-d "$dir[4]/ARDB/ARDB_Anno") || `mkdir -p $dir[4]/ARDB/ARDB_Anno`;
        (-d "$dir[4]/ARDB/Absolute") || `mkdir -p $dir[4]/ARDB/Absolute`;
        (-d "$dir[4]/ARDB/Relative") || `mkdir -p $dir[4]/ARDB/Relative`;
        (-d "$dir[4]/ARDB/GeneNum") || `mkdir -p $dir[4]/ARDB/GeneNum`;
        system "cp -rf $ardb/ARDB.blastout.list.filter $dir[4]/ARDB/ARDB_Anno/ARDB.filter.m8.xls
                cp -rf $ardb/ARDB.blastout.list.filter.anno.xls $dir[4]/ARDB/ARDB_Anno/ARDB.anno.xls
                cp -rf $ardb/ARDB.stat.table.xls $dir[4]/ARDB/ARDB_Anno/";
        system "cp -rf $ardb/Absolute/* $dir[4]/ARDB/Absolute";
        system "cp -rf $ardb/Relative/* $dir[4]/ARDB/Relative";
        system "cp -rf $ardb/GeneNum/* $dir[4]/ARDB/GeneNum";
        if(-s "$ardb/Bar"){
            (-d "$dir[4]/ARDB/bar_plot") || `mkdir -p $dir[4]/ARDB/bar_plot`;
            system "cp -rf $ardb/Bar/* $dir[4]/ARDB/bar_plot";
        }
        if(-s "$ardb/Box"){
            (-d "$dir[4]/ARDB/box_plot") || `mkdir -p $dir[4]/ARDB/box_plot`;
            system "cp -rf $ardb/Box/* $dir[4]/ARDB/box_plot;
                    rm $dir[4]/ARDB/box_plot/*/{*.R,*.txt}";
        }
        if(-s "$ardb/Heatmap"){
            (-d "$dir[4]/ARDB/heatmap") || `mkdir -p $dir[4]/ARDB/heatmap`;
            system "cp -rf $ardb/Heatmap/* $dir[4]/ARDB/heatmap;
                    rm $dir[4]/ARDB/heatmap/*/*.R";
        }
        if(-s "$ardb/Circos/"){
            (-d "$dir[4]/ARDB/Overview") || `mkdir -p  $dir[4]/ARDB/Overview`;
            system "cp -rf $ardb/Circos/{*.png,*.svg,*.xls} $dir[4]/ARDB/Overview";
        }
        if(-s "$ardb/Venn"){
            (-d "$dir[4]/ARDB/venn") || `mkdir -p $dir[4]/ARDB/venn`;
            system "cp -rf $ardb/Venn/* $dir[4]/ARDB/venn;
                    rm $dir[4]/ARDB/venn/*/{*.R,log}";
        }
        if(-s "$ardb/Tax_ARDB/"){
            (-d "$dir[4]/ARDB/ARDB_Tax/ARG_taxonomy") || `mkdir -p $dir[4]/ARDB/ARDB_Tax/ARG_taxonomy`;
            (-d "$dir[4]/ARDB/ARDB_Tax/ARG_mechanism") || `mkdir -p $dir[4]/ARDB/ARDB_Tax/ARG_mechanism`;
            system "cp -rf $ardb/Tax_ARDB/Antibiotic/{*.png,*.svg} $dir[4]/ARDB/ARDB_Tax/ARG_taxonomy";
            system "cp -rf $ardb/Tax_ARDB/Mechanism/{Mech_tax/*.p.xls,*.png,*.svg} $dir[4]/ARDB/ARDB_Tax/ARG_mechanism";
        }
    }
#CARD
    my $card="$indir/05.FunctionAnnotation/CARD/stat_result";
    if( -s "$indir/05.FunctionAnnotation/CARD"){
        (-d "$dir[4]/CARD") || mkdir("$dir[4]/CARD");
        (-d "$dir[4]/CARD/stat_result") || `mkdir -p $dir[4]/CARD/stat_result`;
        system "cp -rf $Bin/../05.Function/lib/CARD/doc/Readme.pdf $dir[4]/CARD/";
        -s "$card/../Unigenes.protein.rgi.del.txt" && system "cp -rf $card/../Unigenes.protein.rgi.del.txt $dir[4]/CARD/";
        -s "$card/stat.ARO.absolute.xls" &&  system "cp -rf $card/stat.ARO.absolute.xls $dir[4]/CARD/stat_result";
        -s "$card/stat.ARO.id.xls" && system "cp -rf $card/stat.ARO.id.xls $dir[4]/CARD/stat_result";
        -s "$card/stat.ARO.relative.xls" && system "cp -rf $card/stat.ARO.relative.xls $dir[4]/CARD/stat_result";
        -s "$card/getARO.xls" && system "cp -rf $card/getARO.xls $dir[4]/CARD/stat_result";
        if(-s "$card/bar/"){
            (-d "$dir[4]/CARD/stat_result/bar")||`mkdir -p $dir[4]/CARD/stat_result/bar`;
            system "cp -rf $card/bar/* $dir[4]/CARD/stat_result/bar";
        }
       if(-s "$card/box/"){
           (-d "$dir[4]/CARD/stat_result/box/genebox")||`mkdir -p $dir[4]/CARD/stat_result/box/genebox`;
           (-d "$dir[4]/CARD/stat_result/box/arobox")||`mkdir -p $dir[4]/CARD/stat_result/box/arobox`;
           system "cp -rf $card/box/genebox/{*.png,*.pdf,*.xls} $dir[4]/CARD/stat_result/box/genebox";
           system "cp -rf $card/box/arobox/{*.png,*.pdf,*.xls} $dir[4]/CARD/stat_result/box/arobox";
        }
        if(-s "$card/circos/"){
            (-d "$dir[4]/CARD/stat_result/circos")||`mkdir -p $dir[4]/CARD/stat_result/circos`;
            system "cp -rf $card/circos/{*.png,*.svg,*.circos.xls} $dir[4]/CARD/stat_result/circos";
        }
        if(-s "$card/heatmap/"){
            (-d "$dir[4]/CARD/stat_result/heatmap/aro_heat")||`mkdir -p $dir[4]/CARD/stat_result/heatmap/aro_heat`;
            (-d "$dir[4]/CARD/stat_result/heatmap/aro_bw")||`mkdir -p $dir[4]/CARD/stat_result/heatmap/aro_bw`;
            system "cp -r $card/heatmap/aro_heat/{*.png,*.pdf,*.heat.xls} $dir[4]/CARD/stat_result/heatmap/aro_heat";
    (-s "$card/heatmap/aro_bw/bw.png") ? (system "cp -r $card/heatmap/aro_bw/{*.png,*.pdf,*.bw.xls} $dir[4]/CARD/stat_result/heatmap/aro_bw"):(system "cp -r $card/heatmap/aro_bw/*.bw.xls $dir[4]/CARD/stat_result/heatmap/aro_bw");
        }
        if(-s "$card/heatmap_group/"){
            (-d "$dir[4]/CARD/stat_result/heatmap_group/aro_heat")||`mkdir -p $dir[4]/CARD/stat_result/heatmap_group/aro_heat`;
            (-d "$dir[4]/CARD/stat_result/heatmap_group/aro_bw")||`mkdir -p $dir[4]/CARD/stat_result/heatmap_group/aro_bw`;
            system "cp -r $card/heatmap_group/aro_heat/{*.png,*.pdf,*.xls} $dir[4]/CARD/stat_result/heatmap_group/aro_heat";
            (-s "$card/heatmap_group/aro_bw/bw.png") ? (system "cp -r $card/heatmap_group/aro_bw/{*.png,*.pdf,*.xls} $dir[4]/CARD/stat_result/heatmap_group/aro_bw"):(system "cp -r $card/heatmap_group/aro_bw/*.xls $dir[4]/CARD/stat_result/heatmap_group/aro_bw");
        }
        if(-s "$card/twocircle/"){
            (-d "$dir[4]/CARD/stat_result/twocircle")||`mkdir -p $dir[4]/CARD/stat_result/twocircle`;
            system "cp -r $card/twocircle/{*.png,*.svg,*.tax.xls} $dir[4]/CARD/stat_result/twocircle";
        }
		if (-s "$card/venn_flower"){
			my @venn_flower=("venn","flower","venn_G","flower_G");
			for my $hua (@venn_flower)
			{
				((-d "$dir[4]/CARD/stat_result/venn_flower/") || `mkdir -p $dir[4]/CARD/stat_result/venn_flower/`);
				system "cp -rf $card/venn_flower/$hua/ $dir[4]/CARD/stat_result/venn_flower/$hua";
				system "rm -rf $dir[4]/CARD/stat_result/venn_flower/$hua/{*.log,*.R}";

			}
		}
		my $metastasts="$card/Metastats/ARO/";
		if (-s "$metastasts")
		{
			(-d "$dir[4]/CARD/stat_result/Metastats/ARO/") || `mkdir -p $dir[4]/CARD/stat_result/Metastats/ARO/ `;
			for my $temp(`ls $metastasts/{*.diff.pdf,*.diff.png,*diff.txt,*.psig.xls,*.qsig.xls,*.test.xls,*_qsig.xls,*_diff_relative.xls}`)
			{
            chomp $temp;
            system "ln -s $temp $dir[4]/CARD/stat_result/Metastats/ARO/";
            }
			 if(-s "$metastasts/boxplot/")
			 {
                (-d "$dir[4]/CARD/stat_result/Metastats/ARO/boxplot") || `mkdir -p $dir[4]/CARD/stat_result/Metastats/ARO/boxplot`;
                system "ln -s $metastasts/boxplot/{figures,*.png,*.svg} $dir[4]/CARD/stat_result/Metastats/ARO/boxplot";
            }
			if(!$opt{s2} && -s "$metastasts/PCA/PCA12.png")
			{
			    (-d "$dir[4]/CARD/stat_result/Metastats/ARO/PCA") || `mkdir -p $dir[4]/CARD/stat_result/Metastats/ARO/PCA`;
		        system "ln -s $metastasts/PCA/{PCA12_2.pdf,PCA12_2.png,PCA12.pdf,PCA12.png,pca.csv,PCA_stat_correlation{1,2}.txt,PCA12_with_cluster_2.pdf,PCA12_with_cluster_2.png,PCA12_with_cluster.pdf,PCA12_with_cluster.png} $dir[4]/CARD/stat_result/Metastats/ARO/PCA";
			
			}	
		}			
		my $lda="$card/LDA_ROC";
		if (!$opt{s2} && -s $lda)
		{
			
            for my $rank(qw(ARO)){
                print "LDA $lda/$rank\n";
                (-s "$lda/$rank") || next;
                for my $d(`ls $lda/$rank`){
                    chomp $d;
                    my @l=split /_/,$d;
                    if( -d "$lda/$rank/$d/" && -s "$lda/$rank/$d/LDA/LDA.$l[0].png"){
                        (-d "$dir[4]/CARD/stat_result/LDA/$rank/$d/LDA") || `mkdir -p $dir[4]/CARD/stat_result/LDA/$rank/$d/LDA`;
                        for my $temp(`ls $lda/$rank/$d/LDA/{*.png,*.pdf,*.res}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/CARD/stat_result/LDA/$rank/$d/LDA";
                        }
                    }
                    if(-s "$lda/$rank/$d/heatmap/cluster.pdf"){
                        (-d "$dir[4]/CARD/stat_result/LDA/$rank/$d/heatmap") || `mkdir -p $dir[4]/CARD/stat_result/LDA/$rank/$d/heatmap`;
                        for my $temp(`ls $lda/$rank/$d/heatmap/{*.png,*.pdf,*.txt}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/CARD/stat_result/LDA/$rank/$d/heatmap";
                        }
                    }
                    my @temp=split/_/,$d;
                    if(-s "$lda/$rank/$d/ROC/$temp[-1]\_ROC.png"){
                        (-d "$dir[4]/CARD/stat_result/LDA/$rank/$d/ROC") || `mkdir -p $dir[4]/CARD/stat_result/LDA/$rank/$d/ROC`;
                        for my $temp(`ls $lda/$rank/$d/ROC/{*.png,*.pdf,*probabilty.xls}`){
                            chomp $temp;
                            system "ln -s $temp $dir[4]/CARD/stat_result/LDA/$rank/$d/ROC";
                        }
                    }
                }
            }
		}

		my $anosim="$card/Anosim";
        if (!$opt{s2} && -s $anosim){
            for my $rank(qw(ARO)){
                (-s "$anosim/$rank/") || next; ###change by zhanghao 20171204
                (-d "$dir[4]/CARD/stat_result/Anosim/$rank/") || `mkdir -p $dir[4]/CARD/stat_result/Anosim/$rank/`;
                system "ln -s $anosim/$rank/{*.png,*.pdf,stat_anosim.txt} $dir[4]/CARD/stat_result/Anosim/$rank/";
            }
        }










		
	  }		

   }
  }     
#05.FunctionAnnotation

##get statinfo
my $stat_info_file="$result/total.stat.info.xls";
my $cds_file="$dir[2]/GenePredict/total.CDS.stat.xls" if ($opt{step}=~/3/);
&get_statinfo($indir,$stat_info_file,$cds_file);
$get_report .= " --stat $stat_info_file ";

open IN,"<$md5list"||die $!;
my %md5sum;
while(<IN>){
    chomp;
#    $_="$result"."/../".$_;
    my($path,$name)=get_filename($_);
    print SH "cd $path\n","md5sum $name > $name.md5.txt\n","md5sum -c $name.md5.txt\n\n";
}

##add for report
#my $checkdir="perl $Bin/check_dir_size.pl  ";
my $attach ;
if ($opt{step}=~/123457/)
{
    $attach.="\'$result/total.stat.info.xls,$indir/$result_prefix[1].tar.gz\'"
}else
{
    $attach.="\'$result/total.stat.info.xls\'";
}
open RESH,">$opt{shdir}/check.and.report.sh"; ##change by zhanghao 20171215
print RESH "cd $result\n","$checkdir $result 2>../error.log\n\n";
print RESH "cd $indir\n","$get_report --resultdir $result --outdir ./\n" if ($opt{step}=~/123457/);
#print RESH "cd $indir\n","$get_report --resultdir $result --outdir ./\n$trigger  --sleept 3 --attach '$result/total.stat.info.xls' $indir/all.steps.date.finish\n";
close RESH;
close SH;
close MD5LIST;
#`$checkdir $result 2>$result/../error.log\n\n`;
(-s "$opt{shdir}/MD5.list") ? `rm -f $opt{shdir}/MD5.list` : 1;
$opt{notrun} && exit;
$opt{locate} ? system"cd $opt{shdir}\n
sh check.and.report.sh" :
system"cd $opt{shdir}\n
nohup $super_worker check.and.report.sh -splits \'\\n\\n\'   --prefix chrep     & wait\n
$trigger --title 'Meta项目:$result_prefix[1] 已完成'   --sleept 3 --attach '$result/total.stat.info.xls,$indir/$result_prefix[1].tar.gz' $indir/all.steps.date.finish\n"; ###add by zhanghao 20180316
#`rm -f $result/../Shell/detail/*/*.e[0-9]*`;
#`rm -f $result/../Shell/detail/*/*.o[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*.e[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*.o[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*.e[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*.o[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*/*.e[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*/*.o[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*/*/*.e[0-9]*`;
#`rm -f $result/../Shell/detail/*/*/*/*/*/*.o[0-9]*`;
#==================================================================================================================
sub cp_datalist{
    my ($lists,$outdir) = @_;
    my @list;
    if($lists=~/\*/){
        for (`ls $lists`){
            chomp;s/\*$//;
            (-s $_) && (push @list,$_);
        }
    }else{
        (-s $lists) && (push @list,$lists);
    }
    @list || return(0);
    (-d $outdir) || mkdir($outdir);
    for my $list(@list){
    for(`less $list`){
        my ($name,$file) = split;
        if(!$file){
            $file = $name;
            $name = (split/\//,$file)[-2];
        }
        (-f $file) || next;
#(-l $file) && next;
        my $bname = (split/\//,$file)[-1];
        (-d "$outdir/$name") || mkdir"$outdir/$name";
        `cp -f $file $outdir/$name`;
   #     `ln -s $file $outdir/$name`;		
#       `ln -s $outdir/$name/$bname $file`;
    }
    }
}

sub get_filename{ 
    my ($file)=@_; 
    my @suffixlist = qw(.fa .fasta .txt .fq .pl .sh .gz .soap);
    my ($name,$path,$suffix) = fileparse($file,@suffixlist);
    my $filename=$name.$suffix;
    $path=abs_path($path);
    $file=$path."/".$filename;
    my @array=($path,$filename,$file);
    return @array;
}

sub get_statinfo{
    my($dir,$stat_file,$cds_file)=@_;
	  if($opt{step} =~ /1/){
    open OUT,">$stat_file"||die$!;

    #get QC.total stat.info
    if ($opt{host}){
        my $name=basename($opt{host});
        open IN,"$dir/01.DataClean/total.$name.NonHostQCstat.info.xls";
        <IN>;
        my($i,$raw,$clean,$nohost);
        while (<IN>){
            chomp;
            s/\,//g;
            my @tmp=split/\t/;
            $raw += $tmp[3];
            $clean += $tmp[10];
            $nohost += $tmp[-1];
            $i++;
        }
        my $ave_raw=sprintf ("%.2f",$raw/$i);
        my $ave_clean=sprintf ("%.2f",$clean/$i);
        my $clean_per=sprintf("%.2f",100*$clean/$raw);
        my $ave_host=sprintf("%.2f",$nohost/$i);
        my $eff_per=sprintf("%.2f",100*$nohost/$clean);
        &digitize($raw,$clean,$nohost,$ave_raw,$ave_clean,$ave_host);
        print OUT "///Data Clean\nTotal Raw Data\t".$raw." Mbp\nAverage Raw Data\t".$ave_raw." Mbp\nTotal Clean Data\t".$clean." Mbp\nAverage Clean Data\t".$ave_clean." Mbp\nEffective percent\t".$clean_per."%\nTotal Nohost Data\t".$nohost." Mbp\nAverage Nohost Data\t".$ave_host." Mbp\nEffective rate\t".$eff_per."%\n";
        close IN;
    }else{
        open IN,"$dir/01.DataClean/total.QCstat.info.xls";
        <IN>;
        my($j,$raw,$clean);
        while (<IN>){
            chomp;
            s/\,//g;
            my @tmp=split/\t/;
            $raw +=$tmp[3];
            $clean +=$tmp[10];
            $j++;
        }
        my $ave_raw=sprintf ("%.2f",$raw/$j);
        my $ave_clean=sprintf ("%.2f",$clean/$j);
        my $clean_per=sprintf("%.2f",100*$clean/$raw);
        &digitize($raw,$clean,$ave_raw,$ave_clean);
        print OUT "///Data Clean\nTotal Raw Data\t".$raw." Mbp\nAverage Raw Data\t".$ave_raw." Mbp\nTotal Clean Data\t".$clean." Mbp\nAverage Clean Data\t".$ave_clean." Mbp\nEffective percent\t".$clean_per."%\n";
        close IN;
     }

	}
    #get assambly total.info
	if($opt{step}=~/2/){
    my @scaf_info=`less $dir/02.Assembly/total.scafSeq.stat.info.xls`;
    my $num=$#scaf_info;
    my($scaf_len,$scaf_num,$scaf_n50,$scaf_n90,@maxlen);
    shift @scaf_info;
    foreach my $scaf (@scaf_info){
        $scaf=~s/\,//g;
        chomp $scaf;
        my @tmp=split/\t/,$scaf;
        $scaf_len+=$tmp[1];
        $scaf_num+=$tmp[2];
        $scaf_n50 +=$tmp[4];
        $scaf_n90 +=$tmp[5];
        push @maxlen,$tmp[-1];
    }
    my $scaf_ave_len=sprintf("%.2f",$scaf_len/$scaf_num);
    my $scaf_ave_n50=sprintf("%.2f",$scaf_n50/$num);
    my $scaf_ave_n90=sprintf("%.2f",$scaf_n90/$num);
    my $scaf_ave_num=sprintf("%2.f",$scaf_num/$num);
    my $scaf_max=(sort {$a<=>$b} @maxlen)[-1];

    my @scaftig_info=`less $dir/02.Assembly/total.scaftigs.stat.info.xls`;
    shift@scaftig_info;
    my($scaftig_len,$scaftig_num,$scaftig_n50,$scaftig_n90);
    foreach my $scaftig (@scaftig_info){
        $scaftig=~s/\,//g;
        chomp $scaftig;
        my @tmp=split /\t/,$scaftig;
        $scaftig_len+=$tmp[1];
        $scaftig_num+=$tmp[2];
        $scaftig_n50 +=$tmp[4];
        $scaftig_n90 +=$tmp[5];
    }
    my $scaftig_ave_len=sprintf("%2.f",$scaftig_len/$scaftig_num);
    my $scaftig_ave_n50=sprintf("%2.f",$scaftig_n50/$num);
    my $scaftig_ave_n90=sprintf("%2.f",$scaftig_n90/$num);
    my $scaftig_ave_num=sprintf("%2.f",$scaftig_num/$num);
    &digitize($scaf_len,$scaf_ave_len,$scaf_max,$scaf_ave_n50,$scaf_ave_n90,$scaftig_len,$scaftig_ave_n50,$scaftig_ave_n90,$scaftig_ave_len,$scaftig_ave_num,$scaf_ave_num);
    print OUT "///Assembly and Mix-Assembly\nScaffolds (Average)\t$scaf_ave_num\nTotal length (nt)\t".$scaf_len." bp\nAverage length (nt)\t".$scaf_ave_len." bp\nLongest length (nt)\t".$scaf_max." bp\nN50 length (nt)\t".$scaf_ave_n50." bp\nN90 length (nt)\t".$scaf_ave_n90." bp\nScaftigs (Average)\t$scaftig_ave_num\nTotal length (nt)\t".$scaftig_len." bp\nAverage length (nt)\t".$scaftig_ave_len." bp\nN50 length (nt)\t".$scaftig_ave_n50." bp\nN90 length (nt)\t".$scaftig_ave_n90." bp\n";

	}
    #get gene predict info
	my @uniq;
	if($opt{step}=~/3/){
    my %hash;
    my @file=`ls $dir/03.GenePredict/GenePredict/*/*.CDS.fa.stat.xls`;
    open F,">$cds_file"; 
    print F "samplename\tORFs NO\tintegrity:none\tintegrity:end\tintegrity:start\tintegrity:all\tTotal length\tAverage length\tGC\n";
    my @title= ('ORFs NO.','integrity:none','integrity:end','integrity:start','integrity:all','Total Len.(Mbp)','Average Len.(bp)','GC percent');
    foreach my $file (@file){
        my $filename=basename($file);
        my $sample=$1 if ($filename=~/(.+)\.CDS\.fa\.stat\.xls/);
        open IN,$file;
        while (<IN>){
            chomp;
            my @tmp=split/\t/;
            $hash{$sample}{$tmp[0]}=$tmp[1];
        }
        close IN;
    }
    foreach my $sample (sort (keys %hash)){
        print F "$sample\t";
        foreach my $title (@title){
            print F  "$hash{$sample}{$title}\t";
        }
        print F "\n";
    }
    close F;

    my @totalgene=`less "$cds_file"`;
    shift @totalgene;
    my $total_orf;
    my $ave_orf;
    foreach my $gene (@totalgene){
        $gene=~s/\,//g;
        chomp $gene;
        my @tmp=split /\t/,$gene;
        $total_orf+=$tmp[1];
    }
    $ave_orf= sprintf("%2.f",$total_orf/($#totalgene+1));#$#totalgene 2015-09-14 yu
    &digitize ($total_orf,$ave_orf);
    print OUT "///Gene Prediction\nTotal ORFs\t$total_orf\nAverage ORFs\t$ave_orf\n"; 

    #my @uniq;
    open IN,"$dir/03.GenePredict/UniqGenes/Unigenes.CDS.cdhit.fa.stat.xls";
    while (<IN>){
        chomp;
        my @tmp=split/\t/;
        push @uniq,$tmp[1];
    }
    print OUT"Gene catalogue\t$uniq[0]\nComplete ORFs\t$uniq[1]\nTotal length (Mbp)\t$uniq[5]\nAverage length (bp)\t$uniq[6]\nGC percent\t".$uniq[7]."%\n";
    close IN;    
    $uniq[0]=~s/\,//g;
	}
    #get tax info
	if($opt{step}=~/4/){
    my $anno_num=(split /\s+/,`wc -l $dir/04.TaxAnnotation/MicroNR/MicroNR_stat/Unigenes.lca.tax.xls`)[0];
    open IN,"$dir/04.TaxAnnotation/MicroNR/MicroNR_stat/Unigenes.lca.tax.xls";
    my ($un,$k,$p,$c,$o,$f,$g,$s);
    while(<IN>){
        chomp;
        my @tmp=split/\t/;
        if ($tmp[1]=~/Unclassified/){
            $un++;
        }else{my @tax=split/;/,$tmp[1];
            if ($#tax==0){$k++;}
            elsif($#tax==1){$p++;}
            elsif($#tax==2){$c++;}
            elsif($#tax==3){$o++;}
            elsif($#tax==4){$f++;}
            elsif($#tax==5){$g++;}
            else{$s++;}
         }
    }
    close IN;

    my $un_abun=sprintf ("%.2f",100*$un/$anno_num);
    my $k_abun=sprintf ("%.2f",100*($k+$p+$c+$o+$f+$g+$s)/$anno_num);
    my $p_abun=sprintf ("%.2f",100*($p+$c+$o+$f+$g+$s)/$anno_num);
    my $c_abun=sprintf ("%.2f",100*($c+$o+$f+$g+$s)/$anno_num);
    my $o_abun=sprintf ("%.2f",100*($o+$f+$g+$s)/$anno_num);
    my $f_abun=sprintf ("%.2f",100*($f+$g+$s)/$anno_num);
    my $g_abun=sprintf ("%.2f",100*($g+$s)/$anno_num);
    my $s_abun=sprintf ("%.2f",100*$s/$anno_num);
    my @array=`head -6 $dir/04.TaxAnnotation/MicroNR/MicroNR_stat/Relative/Unigenes.relative.p.xls`;
    my @top_p;
    shift @array;
    foreach my $tax (@array){
        my @tmp=split /\t/,$tax;
        my $tax_p=$1 if ($tmp[0]=~/^\S+p__(.+)/);
        push @top_p,$tax_p;
    }
    my (@diff_tax_detail);
    if (-s "$dir/04.TaxAnnotation/MicroNR/MicroNR_stat/MetaStats/phylum/phylum_diff_relative.xls"){
        open IN,"$dir/04.TaxAnnotation/MicroNR/MicroNR_stat/MetaStats/phylum/phylum_diff_relative.xls";
        <IN>;
        my $i=0;
        while (<IN>){
            last if $i == 5;
            chomp;
            my @tmp=split/\t/;
            my ($tax_diff,$tax_diff_detail,);
            if ($tmp[0]=~/(.*;p__(.*))/){
                $tax_diff_detail=$1;
                $tax_diff=$2;
            }
            $tax_diff_detail=~s/;/\\;/;
            push @diff_tax_detail,$tax_diff_detail;
            $i++;
        }
        close IN;
    }
    my $anno_num_abun=sprintf ("%.2f",100*$anno_num/$uniq[0]);
    &digitize ($uniq[0],$anno_num,);
    print OUT "///Taxonomic Annotation\nGene catalogue\t$uniq[0]\nAnnotated on NR\t$anno_num($anno_num_abun%)\nAnnotated on Unclassified\t".$un_abun."%\nAnnotated on Kingdom level\t".$k_abun."%\nAnnotated on Phylum level\t".$p_abun."%\nAnnotated on Class level\t".$c_abun."%\nAnnotated on Order level\t".$o_abun."%\nAnnotated on Family level\t".$f_abun."%\nAnnotated on Genus level\t".$g_abun."%\nAnnotated on Species level\t".$s_abun."%\n";
    $uniq[0]=~s/\,//g;
    print OUT join ("\t",("Assigned Phyla(top 5)",@top_p))."\n";
    print OUT join ("\t",("Sign_diff Phyla(top 5)",@diff_tax_detail))."\n" if @diff_tax_detail;
	}
    #get function info 
	if($opt{step}=~/5/){
    my (%ko,%ec,%pathway,%check_kegg,$ko_gene,$ec_gene,$pathway_gene);
    open IN,"$dir/05.FunctionAnnotation/KEGG/KEGG_stat/Unigenes.KEGG.anno.xls";
    <IN>;
    while (<IN>){
        chomp;
        my @tmp=split /\t/;
        if($tmp[2] ne "-" ){
            $ko{$tmp[2]}=1;
            $ko_gene++ if !$check_kegg{$tmp[0]};
        }
        if ($tmp[-3] ne "-" ){
            $ec{$tmp[-3]}=1;
            $ec_gene++ if !$check_kegg{$tmp[0]};
        }
        if ($tmp[-1] ne "-" ){
            my @path=split /\|/,$tmp[-1];
            $pathway_gene++ if !$check_kegg{$tmp[0]};
            foreach my $path (@path){
                my $ko=(split/;/,$path,2)[0];
                $ko =~ s/\s+//g;
                $pathway{$ko}=1;
            }
        }
        $check_kegg{$tmp[0]}=1;
    }
    close IN;
    my $kegg=keys %check_kegg;
    my $ko_num=keys %ko;
    my $ec_num=keys %ec;
    my $path_num=keys %pathway;
    my $kegg_iden_abun=sprintf ("%.2f",100*$kegg/$uniq[0]);
    my $ko_gene_abun=sprintf ("%.2f",100*$ko_gene/$uniq[0]);
    my $ec_gene_abun=sprintf ("%.2f",100*$ec_gene/$uniq[0]);
    my $pathway_gene_abun=sprintf ("%.2f",100*$pathway_gene/$uniq[0]);
    &digitize ($uniq[0],$kegg,$ko_num,$ec_num,$path_num,$ko_gene,$ec_gene,$pathway_gene);
    print OUT "///Functional Annotation\nGene catalogue\t$uniq[0]\nAnnotated on KEGG\t$kegg($kegg_iden_abun\%)\nAnnotated on KO\t$ko_gene($ko_gene_abun\%)/$ko_num\nAnnotated on EC\t$ec_gene($ec_gene_abun\%)/$ec_num\nAnnotated on pathway\t$pathway_gene($pathway_gene_abun\%)/$path_num\n";
    $uniq[0]=~s/\,//g;

    my( %og,%check_nog,$og_gene,);
    open IN,"$dir/05.FunctionAnnotation/eggNOG/eggNOG_stat/Unigenes.filter.anno.xls";
    <IN>;
    while (<IN>){
        chomp;
        my @tmp=split /\t/;
        if ($tmp[2] ne "-" ){
            $og{$tmp[2]}=1;
            $og_gene++ if !$check_nog{$tmp[0]};
        }
        $check_nog{$tmp[0]}=1;
    }
    close IN;
    my $nog=keys %check_nog;
    my $og_num=keys %og;
    my $nog_abun=sprintf ("%.2f",100*$nog/$uniq[0]);
    my $og_gene_abun=sprintf ("%.2f",100*$og_gene/$uniq[0]);
    &digitize($uniq[0],$nog,$og_num,$og_gene);
    print OUT "Annotated on eggNOG\t$nog($nog_abun%)\nAnnotated on OG\t$og_gene($og_gene_abun%)/$og_num\n";
    $uniq[0]=~s/\,//g;

    my (%cazy,%check_cazy);
    open IN,"$dir/05.FunctionAnnotation/CAZy/CAZy_stat/Unigenes.filter.anno.xls";
    <IN>;
    while (<IN>){
        chomp;
        my @tmp=split /\t/;
        if ($tmp[2] ne "-"){
            $cazy{$tmp[2]}=1;
        }
        $check_cazy{$tmp[0]}=1;
    }
    close IN;
    my $cazy_num=keys %check_cazy;
    my $cazy_class=keys %cazy;
    my $cazy_abun=sprintf ("%.2f",100*$cazy_num/$uniq[0]);
    &digitize ($uniq[0],$cazy_num,$cazy_class);
    print OUT "Annotated on CAZy\t$cazy_num($cazy_abun%)\n";
    $uniq[0]=~s/\,//g;

    ##ARDB info
    if(-s "$indir/05.FunctionAnnotation/ARDB"){
        my $ardb_num=(split /\s+/,`wc -l $dir/05.FunctionAnnotation/ARDB/ARDB_stat/ARDB.blastout.list.filter.anno.xls`)[0];
        $ardb_num=$ardb_num-1;
        my $arg_num=(split /\s+/,`wc -l $dir/05.FunctionAnnotation/ARDB/ARDB_stat/ARDB.stat.table.xls`)[0];
        $arg_num =$arg_num-1;
        print OUT "///ARDB Annotation\nGene catalogue\t$uniq[0]\nAnnotated on ARDB\t$ardb_num\nAnnotated ARGs\t$arg_num\n";
    }

    ##CARD info
    if(-s "$indir/05.FunctionAnnotation/CARD"){
        my $card_num=(split /\s+/,`wc -l $dir/05.FunctionAnnotation/CARD/Unigenes.protein.rgi.txt`)[0];
        $card_num=$card_num-1;
        my $aro_num=(split /\s+/,`wc -l $dir/05.FunctionAnnotation/CARD/stat_result/stat.ARO.relative.xls`)[0];
        $aro_num=$aro_num-1;
        print OUT "///CARD Annotation\nGene catalogue\t$uniq[0]\nAnnotated on CARD\t$card_num\nAnnotated AROs\t$aro_num\n";
    }
    close OUT;
 }
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
