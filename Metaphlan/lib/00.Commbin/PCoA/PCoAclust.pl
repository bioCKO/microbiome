#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
die "perl $0 <dist_matrix> <group> <outdir>\n" unless @ARGV==3;
use FindBin qw($Bin);
use lib "$Bin/../../00.Commbin/";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin, $!\n";
my ($R,$convert)=get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(R CONVERT)]);
my $dist_matrix = shift;
my $groups = shift;
my $outdir = shift;
(-d $outdir) || mkdir($outdir);
for($dist_matrix,$groups,$outdir){$_ = abs_path($_);}
if(`head -1 $groups` !~ /sample\s+group/){
    system"echo \"sample\tgroup\" > $outdir/group.xls
    cat $groups >> $outdir/group.xls";
    $groups = "$outdir/group.xls";
}

### Draw Dendorgram and PCA plot

my $file =<< "EOF";

	library(ggplot2)
#library(WGCNA)
    library(extrafont)
	require(grid)
    require(ade4)
	setwd(\"$outdir\")
	data = read.table(\"$dist_matrix\")
    d=as.dist(data)
	groups = read.table(\"$groups\", head=T,colClasses=c("character","character"),na.strings=T)

    length=length(unique(as.character(groups\$group)))
    times1=length%/%8
    res1=length%%8
    times2=length%/%5
    res2=length%%5
    col1=rep(1:8,times1)
    col=c(col1,1:res1)
    pich1=rep(c(15:18,20,7:14,0:6),times2)
    pich=c(pich1,15:(15+res2))
    
# Dendorgram
    h = hclust(d, "average");
    pdf("$outdir/Dendrogram.pdf",height=5,width=8)
    plot(as.dendrogram(h),main = "Sample Cluster", sub="",xlab="",ylab="",horiz=T)
    dev.off()

# PCoA   		
	pca = cmdscale(d,k=2,eig=T) 
    PC1=pca\$points[,1]
    PC2=pca\$points[,2]
    write.csv(pca\$points,file="PCoA.csv")
	PC12<-pca\$points[,1:2]
    ncol=ncol(groups)
    group1=c()
    group2=c()
    for(i in 1:length(groups\$sample)){
        Order=grep(paste0('^',rownames(pca\$points)[i],'\$'),groups\$sample,perl=T)
        group1[i]=groups\$group[Order]
        if(ncol==3){
            group2[i]=groups\$group2[Order]
        }
    }
    group1=factor(group1,levels=unique(group1))## edit by ye,to fix group order 2015-12-07
    group2=factor(group2,levels=unique(group2))## edit by ye,to fix group order 2015-12-07
    if(ncol==2){
        plotdata = data.frame(rownames(pca\$points),PC1,PC2,group1)
        colnames(plotdata)=c("sample","PC1","PC2","group")
    }else if(ncol==3){
        plotdata = data.frame(rownames(pca\$points),PC1,PC2,group1,group2)
        colnames(plotdata)=c("sample","PC1","PC2","group1","group2")
    }
	plotdata\$sample = factor(plotdata\$sample)
	plotdata\$PC1=as.numeric(as.vector(plotdata\$PC1))
	plotdata\$PC2=as.numeric(as.vector(plotdata\$PC2))
	pc1 =floor(pca\$eig[1]/sum(pca\$eig)*10000)/100
	pc2 = floor(pca\$eig[2]/sum(pca\$eig)*10000)/100

	p2<-ggplot(plotdata, aes(PC1, PC2)) +
        geom_point(aes(colour=group,shape=group),size=6)+ 
        scale_shape_manual(values=pich)+
        scale_colour_manual(values=col)+
        labs(title="PCoA - PC1 vs PC2") + xlab(paste("PC1 ( ",pc1,"%"," )",sep="")) + ylab(paste("PC2 ( ",pc2,"%"," )",sep=""))+
        theme(text=element_text(family="Arial",size=18))+
#        geom_vline(aes(x=0,y=0),linetype="dotted")+
#        geom_hline(aes(x=0,y=0),linetype="dotted")+
#        theme(panel.background = element_rect(fill='white', colour='black'), panel.grid=element_blank(), axis.title = element_text(color='black',family="Arial",size=18),axis.ticks.length = unit(0.4,"lines"), axis.ticks = element_line(color='black'), axis.ticks.margin = unit(0.6,"lines"),axis.line = element_line(colour = "black"), axis.title.x=element_text(colour='black', size=18),axis.title.y=element_text(colour='black', size=18),axis.text=element_text(colour='black',size=18),legend.title=element_blank(),legend.text=element_text(family="Arial", size=18),legend.key=element_blank())+
        geom_vline(aes(x=0,y=0),xintercept=0,linetype="dotted")+
        geom_hline(aes(x=0,y=0),yintercept=0,linetype="dotted")+
       	theme(panel.background = element_rect(fill='white', colour='black'), panel.grid=element_blank(), axis.title = element_text(color='black',family="Arial",size=18),axis.ticks.length = unit(0.4,"lines"), axis.ticks = element_line(color='black'), axis.line = element_line(colour = "black"), axis.title.x=element_text(colour='black', size=18),axis.title.y=element_text(colour='black', size=18),axis.text=element_text(colour='black',size=18),legend.title=element_blank(),legend.text=element_text(family="Arial", size=18),legend.key=element_blank())+
            theme(plot.title = element_text(size=22,colour = "black",face = "bold",hjust=0.5))
	
	cairo_pdf("$outdir/PCoA12.pdf",height=12,width=15)
	p2
#    png(filename="$outdir/PCoA12.png",res=600,height=5400,width=7200,type="cairo")
#	p2
        dev.off()
	

    p5<-ggplot(plotdata, aes(PC1, PC2)) +
        geom_text(aes(label=sample),size=5,family="Arial",hjust=0.5,vjust=-1)+ 
        geom_point(aes(colour=group,shape=group),size=6)+ 
        scale_shape_manual(values=pich)+
        scale_colour_manual(values=col)+
        labs(title="PCoA - PC1 vs PC2") + xlab(paste("PC1 ( ",pc1,"%"," )",sep="")) + ylab(paste("PC2 ( ",pc2,"%"," )",sep=""))+
        theme(text=element_text(family="Arial",size=18))+
		geom_vline(aes(x=0,y=0),xintercept=0,linetype="dotted")+
        geom_hline(aes(x=0,y=0),yintercept=0,linetype="dotted")+
        theme(panel.background = element_rect(fill='white', colour='black'), panel.grid=element_blank(), axis.title = element_text(color='black',family="Arial",size=18),axis.ticks.length = unit(0.4,"lines"), axis.ticks = element_line(color='black'), axis.ticks.margin = unit(0.6,"lines"),axis.line = element_line(colour = "black"), axis.title.x=element_text(colour='black', size=18),axis.title.y=element_text(colour='black', size=18),axis.text=element_text(colour='black',size=18),legend.title=element_blank(),legend.text=element_text(family="Arial", size=18),legend.key=element_blank())+
        theme(plot.title = element_text(size=22,colour = "black",face = "bold",hjust = 0.5))
#        geom_vline(aes(x=0,y=0),linetype="dotted")+
#        geom_hline(aes(x=0,y=0),linetype="dotted")+
#      	    theme(panel.background = element_rect(fill='white', colour='black'), panel.grid=element_blank(), axis.title = element_text(color='black',family="Arial",size=18),axis.ticks.length = unit(0.4,"lines"), axis.ticks = element_line(color='black'), axis.ticks.margin = unit(0.6,"lines"),axis.line = element_line(colour = "black"), axis.title.x=element_text(colour='black', size=18),axis.title.y=element_text(colour='black', size=18),axis.text=element_text(colour='black',size=18),legend.title=element_blank(),legend.text=element_text(family="Arial", size=18),legend.key=element_blank())+
#          theme(plot.title = element_text(size=22,colour = "black",face = "bold",hjust=0.5))

        cairo_pdf("$outdir/PCoA12_2.pdf",height=12,width=15)
        p5
#        png(filename="$outdir/PCoA12_2.png",res=600,height=5400,width=7200,type="cairo")
#        p5
        dev.off()
######## PCoA withcluster ######
     cairo_pdf("$outdir/PCoA12_withcluster_2.pdf",height=12,width=15)
    par(mar=c(4,4,4,10),mgp=c(2,0.5,0),bg="white",cex.lab=1.2)
    plot(PC12,type="n", xlab=paste("PC1 ( ",pc1,"%"," )",sep=""), ylab=paste("PC2 ( ",pc2,"%"," )",sep=""), main="PCoA plot")
    abline(h=0,v=0,lty=2)
    s.class(PC12, fac=as.factor(plotdata\$group), grid=F, xax = 1, yax = 2,cellipse=0.8,clabel=1.5,cpoint=1.5,add.plot=TRUE,col=col,pch=19)
    legend("right",inset=c(-0.13,0),xpd=TRUE,bty="n",legend=as.vector(levels(plotdata\$group)),col=col,pch=19,cex=1.5,pt.cex=1.6)
dev.off()
    
    cairo_pdf("$outdir/PCoA12_withcluster.pdf",height=12,width=15)
par(mar=c(4,4,4,10),mgp=c(2,0.5,0),bg="white",cex.lab=1.2)
    plot(PC12,type="n", xlab=paste("PC1 ( ",pc1,"%"," )",sep=""), ylab=paste("PC2 ( ",pc2,"%"," )",sep=""), main="PCoA plot")
        abline(h=0,v=0,lty=2)
        s.class(PC12, fac=as.factor(plotdata\$group), grid=F, xax = 1, yax = 2,cellipse=0.8,clabel=1.5,cpoint=1.5,add.plot=TRUE,col=col,pch=19)
            text(PC12[,1],PC12[,2],labels=as.vector(plotdata\$sample),cex=1.2,pos=3,offset=0.5)
        legend("right",inset=c(-0.13,0),xpd=TRUE,bty="n",legend=as.vector(levels(plotdata\$group)),col=col,pch=19,cex=1.5,pt.cex=1.6)
   dev.off()  

EOF

open OUT, ">DendoPCA.R" or die $!;
print OUT $file;
close OUT;

system"$R -f DendoPCA.R
       $convert $outdir/PCoA12.pdf $outdir/PCoA12.png
       $convert $outdir/PCoA12_2.pdf $outdir/PCoA12_2.png
	   $convert -density 300 $outdir/PCoA12_withcluster_2.pdf $outdir/PCoA12_withcluster_2.png
	   $convert -density 300 $outdir/PCoA12_withcluster.pdf $outdir/PCoA12_withcluster.png";
