arg <- commandArgs(T)
library(ggplot2)
data=read.table(arg[1], header=TRUE,sep="\t")
BinSize<-as.numeric(gsub(",","",data[,2]))
Contamination<-data[,4]
Completeness<-data[,3]
P<-ggplot(data,mapping=aes(x=Contamination,y=Completeness,size=BinSize))+geom_point(color='#79CDCD')+scale_size_area(max_size=10)+geom_hline(aes(yintercept=70))+geom_vline(aes(xintercept=10))
P<-P+theme(panel.background=element_rect(fill='white',colour='black'))+theme(text=element_text(family="serif"))
f1<-paste(arg[2],"/CheckM.pdf",sep="")
cairo_pdf(filename=f1,height=12,width=15)
P
f2<-paste(arg[2],"/CheckM.png",sep="")
png(filename=f2,res=600,height=5400,width=7200,type="cairo")
P
dev.off()

