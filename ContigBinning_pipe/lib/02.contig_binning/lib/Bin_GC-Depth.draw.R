arg <- commandArgs(T)
library(ggplot2)
data<-read.table(arg[1], header=TRUE,sep="\t")
ContigSize<-data[,5]
P<-ggplot(data,mapping=aes(x=data[,4],y=data[,3],size=ContigSize))+geom_point(color='#79CDCD',alpha=.5)+xlim(0,100)+labs(x="GC(%)",y="Depth(X)")+scale_size_area(max_size=10)
BinID<-data[,1]
P<-P+facet_wrap(~BinID)
P<-P+theme(panel.background=element_rect(fill='white',colour='black'))+theme(text=element_text(family="serif"))
f1<-paste(arg[2],"/Bin_GC-Depth.pdf",sep="")
cairo_pdf(filename=f1,height=12,width=15)
P
f2<-paste(arg[2],"/Bin_GC-Depth.png",sep="")
png(filename=f2,res=600,height=5400,width=7200,type="cairo")
P
dev.off()

