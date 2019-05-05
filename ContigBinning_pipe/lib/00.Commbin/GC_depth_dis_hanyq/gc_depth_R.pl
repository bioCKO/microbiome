#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
#my ($dep_clu,$heigh,$clustf);
#GetOptions(
#        "dep_cut:i"=>\$dep_cut,"dep_clu:i"=>\$dep_clu,"rank:s"=>\$rank,"cluster:i"=>\$cluster,
#        "width:i"=>\$width,"heigh:i"=>\$heigh,"xtitle:s"=>\$xtitle,"ytitle:s"=>\$ytitle,
#        "clustf:s"=>\$clustf,"gc_range:s"=>\$gc_range,"grey"=>\$grey
##);
#$dep_clu ||= $dep_cut;
#$heigh ||= $width;
#################################################################################
@ARGV || die"Name: gc_depth_R.pl
Description: script to draw GC-depth or other edge dot figure with R
Connect: liuwenbin\@genomics.org
Usage: perl $0 <in.gcdepth> <out.pdf>
    --rank <str>        the rank GC and depth in, default= 3:4
    --cluster <num>     dot clusert number, default=5
    --clustf <file>     set output cluster result file name, default=<in.gcdepth>.cluster
    --xtitle <str>      x-asia title, defulat='GC%'
    --ytitle <str>      y-asia title, defualt='Sequencing Depth(X)'
    --gc_range <str>    GC% range show, min:max(e.g 20:80), negative means auto, default=-1,-1
    --dep_cut <num>     maxdepth to show at the figure, negative means auto, default=-1
    --dep_clu <num>     borde depth cut for culuster, defualt=dep_cut
    --grey              show depth pot in grey, default in red\n\n";
#################################################################################
my ($infile,$outfile,$scaf_file) = @ARGV;#从命令行获取输入文件GC_depth.pos与输出文件GC_depth.pos.pdf
#my $r_script = "/usr/bin/R";
my $r_script = "/PUBLIC/software/public/System/R-2.15.3/bin/Rscript";
my $kmean_R = "kmer$$.R";#记录进程号，kmer30617.R
open KR,">$kmean_R" || die$!;
my $rfile=&make_kmean($infile,$outfile,$scaf_file);
print KR $rfile;
close KR;

system "$r_script $kmean_R >/dev/null;rm $kmean_R";

#################################################################################
sub make_kmean{
   my ($infile,$outfile,$scaf_file) = @_;#$clustf==GC_depth.pos.cluster
   my $strs = "
pos<-read.table('$infile',head=F)
colnames(pos)<- c('v1','v2','gc','depth')
#length(pos\$gc)
dbwin_data <- data.frame(gc= pos\$gc,depth= pos\$depth,row.names=1:length(pos[,1]))#找出gc和depth的两列
library('fpc')
db <-dbscan(dbwin_data,eps=0.12,MinPts=555550,scale=T,method='raw')
win_cluster<-db\$cluster

dbwin_data\$cluster<-win_cluster
win_data_all_clusterd<-dbwin_data[dbwin_data\$cluster!=0,]




scaf <- read.table('$scaf_file',head=F)
library('class')
scafgd<-data.frame(gc=scaf\$V3,depth=scaf\$V4)
#scafknn<-knn(train=dbwin_data,test=scafgd,cl=win_cluster,k=20)

scafknn<-knn(train= win_data_all_clusterd[,c(1,2)],test=scafgd,cl=win_data_all_clusterd\$cluster,k=20)
scaf\$cluster<-scafknn





scafknn1<-as.numeric(scafknn)
scafknn1<-as.vector(scafknn1)
ratio<-(length(scafknn1[scafknn1==2])+length(scafknn1[scafknn1==3])+length(scafknn1[scafknn1==4]))/(length(scafknn1[scafknn1==2])+length(scafknn1[scafknn1==1])+length(scafknn1[scafknn1==3])+length(scafknn1[scafknn1==4]))
ratio<-ratio*100
ratio <- round(ratio,2)
write.table(scaf, '$scaf_file',col.names=F,row.names=F,quote=F,sep='\t')


unclustered<-scaf[scaf\$cluster==0,1]
if(length(unclustered!=0)){
    write.table(as.data.frame(unclustered),'cluster_file/unclusterd',append=T,quote=F,row.names=F,col.names='unclustered:')
}
cluster1<-scaf[scaf\$cluster==1,1]
if(length(cluster1!=0)){
    write.table(as.data.frame(cluster1),'cluster_file/cluster1',append=T,quote=F,row.names=F,col.names='cluster1:')
}
cluster2<-scaf[scaf\$cluster==2,1]
if(length(cluster2!=0)){
    write.table(cluster2,'cluster_file/cluster2',append=T,quote=F,col.names='cluster2:',row.names=F)
}
cluster3<-scaf[scaf\$cluster==3,1]
if(length(cluster3!=0)){
    write.table(cluster3,'cluster_file/cluster3',append=T,quote=F,col.names='cluster3:',row.names=F)
}


write.table(ratio,'$scaf_file',append=T,col.names=F,row.names='ratio:',quote=F)
library('ggplot2')
p<-ggplot(dbwin_data,aes(x=gc,y=depth))

pdf('$outfile')
pic<-p+geom_point(colour=factor(win_cluster+1),alpha=1/20,na.rm=T)+xlim(0,100)+ylim(0,400)+xlab('GC%')+ylab('Seq dep(x)')+theme_bw()
pic
dev.off()";
   $strs;
}
