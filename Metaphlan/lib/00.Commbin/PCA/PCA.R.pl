#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
use lib "$Bin/../";
use PATHWAY;
my $cfg = "$Bin/../../../bin/Pathway_cfg.txt";
(-s $cfg) || die"error: can't find config file: $cfg, $!\n";
my ($R0,$convert)=get_pathway($cfg,[qw(R7 CONVERT)]);
my $T;
GetOptions("R:s"=>\$R0,"T"=>\$T);
die "perl $0 <exp_data> <group> <outdir> [-R R_PATH] [-T(to change input matrix)]\n" unless @ARGV>=3;
my ($exp_data, $groups, $outdir, $R) = @ARGV;
$R ||= $R0;
(-d $outdir) || mkdir($outdir);
$outdir =abs_path($outdir);
$groups =abs_path($groups);
if($T){
    my $bname = (split/\//,$exp_data)[-1];
    system"perl $Bin/taxa_table.pl $exp_data $outdir/$bname";
    $exp_data = "$outdir/$bname";
}

my $file =<< "EOF";
.libPaths('R/v3.0.3/lib64/R/library')
	require(FactoMineR)
	require(ade4)
    require(cluster)
    require(grid)
    require(fpc)
    require(clusterSim)
    require(RColorBrewer)
	require(ggplot2)
	setwd(\"$outdir\")
	data = read.table(\"$exp_data\", head=T, row.names=1,sep="\\t")
	groups = read.table(\"$groups\", head=F,colClasses=c(\"character\",\"character\"))
	
b <- matrix(0,nrow = nrow(data), ncol = ncol(data))
for(i in 1:ncol(data)){
        b[,i] = data[ ,i]/sum(data[ ,i])
}
colnames(b) <- colnames(data)
rownames(b) <- rownames(data)
data <- t(b)

        length=length(unique(as.character(groups\$V1)))
        times1=length%/%8
        res1=length%%8
        times2=length%/%5
        res2=length%%5
        col1=rep(1:8,times1)
        col=c(col1,1:res1)
        pich1=rep(c(15:18,20),times2)
        pich=c(pich1,15:(15+res2))


# PCA   		
	pca = PCA(data[,1:ncol(data)], scale.unit=T, graph=F)
	PC1 = pca\$ind\$coord[,1]
	PC2 = pca\$ind\$coord[,2]
        PC12 = pca\$ind\$coord[,1:2]
        write.csv(pca\$ind\$coord,file="pca.csv")

        ncol=ncol(groups)
        group1=c()
        group2=c() 
        for(i in 1:length(groups\$V1)){
#Order=grep(rownames(pca\$ind\$coord)[i],groups\$V1) modify, 2014-10-24, for sample to group match error, chen
        Order=grep(paste0('^',rownames(pca\$ind\$coord)[i],'\$'),groups\$V1,perl=T)
        group1[i]=groups\$V2[Order]
        if(ncol==3){
           group2[i]=groups\$V3[Order]
           }
        }
if(ncol==2){
        plotdata = data.frame(rownames(pca\$ind\$coord),PC1,PC2,group1)
        colnames(plotdata)=c("sample","PC1","PC2","group")
        point<-geom_point(aes(colour=group,shape=group),size=6)
}else if(ncol==3){
        plotdata = data.frame(rownames(pca\$ind\$coord),PC1,PC2,group1,group2)
        colnames(plotdata)=c("sample","PC1","PC2","group1","group2")
        point<-geom_point(aes(colour=group1,shape=group2),size=6)
}
#	plotdata = data.frame(groups\$sample,PC1,PC2,groups\$group,rownames(pca\$var\$cor),pca\$var\$cor[,1],pca\$var\$cor[,2],pca\$var\$cor[,3])
#	colnames(plotdata)=c("sample","PC1","PC2","group")
	plotdata\$sample = factor(plotdata\$sample)
#        plotdata\$spieces = factor(plotdata\$spieces)
	plotdata\$PC1=as.numeric(as.vector(plotdata\$PC1))
	plotdata\$PC2=as.numeric(as.vector(plotdata\$PC2))
	pc1 = floor(pca\$eig[1,2]*100)/100
	pc2 = floor(pca\$eig[2,2]*100)/100
#
	plot<-ggplot(plotdata, aes(PC1, PC2)) +
	geom_text(aes(label=sample),size=5,hjust=0.5,vjust=-1)+ 
	point+ 
        scale_shape_manual(values=pich)+
        scale_colour_manual(values=col)+
#    scale_shape_manual(values=as.numeric(unique(plotdata\$group)))+
	labs(title="PCA Plot") + xlab(paste("PC1, ",pc1,"%",sep="")) + ylab(paste("PC2, ",pc2,"%",sep=""))+
#	scale_colour_hue(name="group",l=30)+
	theme(panel.background = element_rect(fill='white', colour='black'))+
#        geom_segment(data = bb,x=0,y=0, aes(x=0,y=0,xend = bb[,1]*0.06, yend = bb[,2]*0.06),
#              colour="purple",
#             arrow=arrow(angle=25, length=unit(0.25, "cm")))+
#       geom_text(data=bb, aes(x=bb[,1]*0.065, y=bb[,2]*0.065, label=rownames(bb)), size=5, colour="purple")+
        theme(text=element_text(family="Arial",size=15))+
        theme(axis.text.x=element_text(size=12,colour="black"))+
        theme(axis.text.y=element_text(size=12,colour="black"))+
        theme(axis.text.x=element_text(size=14,colour="black"))+
        theme(axis.text.y=element_text(size=14,colour="black"))+
		geom_vline(aes(x=0,y=0),xintercept=0,linetype="dotted")+
        geom_hline(aes(x=0,y=0),yintercept=0,linetype="dotted")+
        theme(legend.title=element_blank(),plot.title=element_text(hjust= 0.5))+
        theme(legend.key=element_blank())
#       png(filename="$outdir/PCA12.png",height=420,width=540,type="cairo")
#       plot
       cairo_pdf(filename="$outdir/PCA12.pdf",height=10,width=12)
       plot  
#png(filename="$outdir/PCA12_2.png",res=700,height=7200,width=7200,type="cairo")


        plot<-ggplot(plotdata, aes(PC1, PC2)) +
#        geom_text(aes(label=sample),size=6,hjust=0.5,vjust=-0.7)+ 
        point+ 
        scale_shape_manual(values=pich)+
        scale_colour_manual(values=col)+
        labs(title="PCA Plot") + xlab(paste("PC1, ",pc1,"%",sep="")) + ylab(paste("PC2, ",pc2,"%",sep=""))+
        theme(panel.background = element_rect(fill='white', colour='black'))+
#        geom_segment(data = bb,x=0,y=0, aes(x=0,y=0,xend = bb[,1]*0.06, yend = bb[,2]*0.06),
#              colour="purple",
#             arrow=arrow(angle=25, length=unit(0.25, "cm")))+
#       geom_text(data=bb, aes(x=bb[,1]*0.065, y=bb[,2]*0.065, label=rownames(bb)), size=5, colour="purple")+
        theme(text=element_text(family="Arial",size=15))+
        theme(axis.text.x=element_text(size=12,colour="black"))+
        theme(axis.text.y=element_text(size=12,colour="black"))+
        theme(axis.text.x=element_text(size=14,colour="black"))+
		theme(axis.text.y=element_text(size=14,colour="black"))+
        geom_vline(aes(x=0,y=0),xintercept=0,linetype="dotted")+
        geom_hline(aes(x=0,y=0),yintercept=0,linetype="dotted")+
        theme(legend.title=element_blank(),plot.title=element_text(hjust= 0.5))+
        theme(legend.key=element_blank())
#        png(filename="$outdir/PCA12_2.png",height=420,width=540,type="cairo")
#        plot
        cairo_pdf(filename="$outdir/PCA12_2.pdf",height=10,width=12)
        plot
dev.off()	
######################### PCA plot with cluster ##########################
.libPaths('System/R-3.2.1/lib64/R/library')
length1=length(unique(as.character(groups\$V2)))
if (length > length1){
    cairo_pdf(filename="$outdir/PCA12_with_cluster.pdf",height=10,width=12)
    par(mar=c(4,4,4,10),mgp=c(2,0.5,0),bg="white",cex.lab=1.2)
    plot(PC12, type="n", xlab=paste("PC1 ( ",pc1,"%"," )",sep=""), ylab=paste("PC2 ( ",pc2,"%"," )",sep=""), main="PCA plot")
    abline(h=0,v=0,lty=2)
    s.class(pca\$ind\$coord, fac=as.factor(plotdata\$group), grid=F, xax = 1, yax = 2,cellipse=0.8,clabel=0,cpoint=1.5,add.plot=TRUE,col=col,pch=19)
    text(plotdata\$PC1,plotdata\$PC2,labels=as.vector(plotdata\$sample),cex=1.2,pos=3,offset=0.5)
    legend("right",inset=c(-0.20,0),xpd=TRUE,bty="n",legend=as.vector(levels(plotdata\$group)),col=col,pch=19,cex=1.5,pt.cex=1.6)
    dev.off()

    cairo_pdf(filename="$outdir/PCA12_with_cluster_2.pdf",height=10,width=12)
    par(mar=c(4,4,4,10),mgp=c(2,0.5,0),bg="white",cex.lab=1.2)
    plot(PC12, type="n", xlab=paste("PC1 ( ",pc1,"%"," )",sep=""), ylab=paste("PC2 ( ",pc2,"%"," )",sep=""), main="PCA plot")
    abline(h=0,v=0,lty=2)
    s.class(pca\$ind\$coord,, fac=as.factor(plotdata\$group), grid=F, xax = 1, yax = 2,cellipse=0.8,clabel=1.5,cpoint=1.5,add.plot=TRUE,col=col,pch=19)
    legend("right",inset=c(-0.20,0),xpd=TRUE,bty="n",legend=as.vector(levels(plotdata\$group)),col=col,pch=19,cex=1.5,pt.cex=1.6)
    dev.off()
}    

	



EOF

my $cor=<< "COR" ;
.libPaths('R/v3.0.3/lib64/R/library')
    library(FactoMineR)
	library(ggplot2)
    library(grid)
	setwd(\"$outdir\")
	data = read.table(\"$exp_data\", head=T, row.names=1,sep="\\t")
	groups = read.table(\"$groups\", head=F,colClasses=c(\"character\",\"character\"))
	
b <- matrix(0,nrow = nrow(data), ncol = ncol(data))
for(i in 1:ncol(data)){
        b[,i] = data[ ,i]/sum(data[ ,i])
}
colnames(b) <- colnames(data)
rownames(b) <- rownames(data)
data <- t(b)

        length=length(unique(as.character(groups\$V1)))
        times1=length%/%8
        res1=length%%8
        times2=length%/%5
        res2=length%%5
        col1=rep(1:8,times1)
        col=c(col1,1:res1)
        pich1=rep(c(15:18,20),times2)
        pich=c(pich1,15:(15+res2))


# PCA   		
	pca = PCA(data[,1:ncol(data)], scale.unit=T, graph=F)
#correlation
        dimdesc(pca, axes = c(1, 2), proba = 0.1 )
        di1<-dimdesc(pca, axes = c(1, 2), proba = 0.1 )
        di1\$Dim.1\$quanti[order(di1\$Dim.1\$quanti[,2]),]  
        di1\$Dim.2\$quanti[order(di1\$Dim.2\$quanti[,2]),]

        correlatonDim1 <- di1\$Dim.1\$quanti[order(di1\$Dim.1\$quanti[,2]),]
        correlatonDim2 <- di1\$Dim.2\$quanti[order(di1\$Dim.2\$quanti[,2]),]
		write.table(correlatonDim1,file="PCA_stat_correlation1.txt")
        write.table(correlatonDim2,file="PCA_stat_correlation2.txt")

COR



open OUT, ">$outdir/PCA.R" or die $!;
print OUT $file;
close OUT;
open OUT,"> $outdir/PCA_cor.R" or die $!;
print OUT $cor;
close OUT;
system "$R -f $outdir/PCA.R
        $convert -density 300 $outdir/PCA12.pdf $outdir/PCA12.png
        $convert -density 300 $outdir/PCA12_2.pdf $outdir/PCA12_2.png
		$convert -density 300 $outdir/PCA12_with_cluster.pdf $outdir/PCA12_with_cluster.png
		$convert -density 300 $outdir/PCA12_with_cluster_2.pdf $outdir/PCA12_with_cluster_2.png
		$R -f $outdir/PCA_cor.R > $outdir/PCA_cor.log";
