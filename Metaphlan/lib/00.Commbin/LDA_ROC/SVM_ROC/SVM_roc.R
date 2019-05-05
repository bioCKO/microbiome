suppressPackageStartupMessages(library("optparse"))

option_list <- list(
        make_option("--infile",action="store",default=NULL,help="The input file for ROC curve plot,look like: roc_file.xls,Sample\tClass\tvar1\tvar2...varn"),
        make_option("--outdir",action="store",default="./",help="The output dirctory"),
        make_option("--vs",action="store",default="",help="Set plot main title")
)

opt<-parse_args(OptionParser(usage="%prog [options] file\n",option_list=option_list))
if(is.null(opt$infile)){
    cat ("Use %prog -h for more help infomation\nThe author: yelei@novogene.com\n")
    quit("no")
}

infile<-opt$infile
outdir<-paste(opt$outdir,"/",sep="")
if(!file.exists(outdir)){
    dir.create(outdir)
}
title <- paste(opt$vs,"ROC Curve",sep=" ")

library(e1071)
library(pROC)
data <-read.table(infile,head=T,row.name=1,sep="\t")
Class <- data$Class
model <- svm(Class~.,data=data,probability = TRUE,kernel = "radial")
table <- subset(data,select = -Class)
svm_pre <- predict(model,table,probability = TRUE)
svm_prob <- attr(svm_pre,"probabilities")[1:length(as.character(Class)),]
outfile = paste(outdir,"/",opt$vs,"_predict_probabilty.xls",sep="")
write.table(svm_prob,outfile)
probability <- svm_prob[,1]
names(probability)=NULL
outpdf <- paste(outdir,"/",opt$vs,"_ROC.pdf",sep="")
pdf(outpdf)
ROC = roc(Class, probability, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)
plot.roc(ROC,col=2,lwd=3,main=title)
sens.ci <- ci.se(ROC,specificities=seq(0, 100, 5))
plot(sens.ci,type="shape",col="aquamarine")
plot(sens.ci,type="bars")
plot(ROC,col=2,lwd=3,add=T)
legend("bottomright",c(paste("AUC=",round(ROC$ci[2],2),"%"), paste("95% CI:",round(ROC$ci[1],2),"%-",round(ROC$ci[3],2),"%")),inset = c(0.45,0.4),bty="n",text.col="darkgreen",text.width=2)
dev.off()
