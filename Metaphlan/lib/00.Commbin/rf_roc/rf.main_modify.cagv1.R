suppressPackageStartupMessages(library("optparse"))

option_list <- list(
        make_option("--infile", action="store",default=NULL, help="The dirctory of Evenabs.mat, look like: result.txt: group_names\tvar1\tvar2...varn"),
        make_option("--outdir", action="store",default="./", help="The output dirctory,  [default %default]"),
        make_option("--headvar", action="store",  help="The important variables to use in randomForest to show in the picture,  [default %default]"),
        make_option("--scale", action="store", default="log",help=" shows the cross-validated prediction performance of models with sequentially reduced number of predictors (ranked by variable importance) via a nested cross-validation procedure."),
        make_option("--step", action="store",type="double", default=0.5,help=" if log=TRUE, the fraction of variables to remove at each step, else remove this many variables at a time")
)

opt<-parse_args(OptionParser(usage="%prog [options] file\n", option_list=option_list))
if(is.null(opt$infile)){
    cat ("Use  %prog -h for more help info\nThe author: hanyuqiao@novogene.cn\n")
    quit("no")
}

infile<-opt$infile
#head_im_vars = opt$headvar
outdir<-paste(opt$outdir,"/",sep="")
if(!file.exists(outdir)){
    dir.create(outdir)
}
####get option
step<-opt$step
#print (step)
if(! is.null(opt$headvar))
{
	head_im_vars<-opt$headvar
	head_im<-strsplit(head_im_vars,split=",")
	head_num=1
	head_im_vars<-c()
	for (jj in head_im[[1]])
	{
		jj<-as.numeric(jj)
		head_im_vars[head_num]<-jj
		head_num=head_num+1
	}
}else{
	
	var<-system(paste("awk '{print NF}' ",infile," | head -n 1"),intern=T)
	var<-as.numeric(var[[1]])-1
	if (!is.null(opt$scale) && opt$scale == "log") {#cv的x轴
#	    print (step)
        scale<-opt$scale
        k <- floor(log(var, base = 1/step)) #将变量分成多少份。
		head_im_vars <- round(var * step^(0:(k - 1))) #4*(1.0, 0.5)，每一份的变量
			
				same <- diff(head_im_vars) == 0
		if (any(same)) head_im_vars <- head_im_vars[-which(same)]
		if (1 %in% head_im_vars) head_im_vars <- head_im_vars[-match(1,head_im_vars)]
		
	}else{
		head_im_vars <- seq(from = var, to = 1, by = step)                       
	}   
}
colfile<-"lib/00.Commbin/rf_roc/group.colorx.xls"
col<-read.table("colfile",sep=",")
####
print (head_im_vars)

library(randomForest)
library(ggplot2)
set.seed(999)
source("share/MetaGenome_pipeline/RandomFrest/randomforest.crossvalidation.last.r")
c_table <- read.table(infile,sep="\t",header=T)
#c_table=read.table("result.xls", sep="\t", header=T);
cv.fold=10
repeattimes = 5
c_table <- data.frame(c_table)
table.split <- sample(2, nrow(c_table), replace = TRUE, prob=c(0.8,0.2))
trainset <- c_table[table.split == 1,]
testset <- c_table[table.split == 2,]
c_table <- trainset
trainset_outfile <- paste(outdir,"/","trainset.ori.xls",sep="")
testset_outfile <- paste(outdir,"/","testset.xls",sep="")
write.table(trainset,trainset_outfile,sep="\t",quote = F)
write.table(testset,testset_outfile,sep="\t",quote=F)
table(c_table[,1])
table(testset[,1])
X=c_table[2:ncol(c_table)]
Y=c_table[,1]
result <- replicate(repeattimes, rfcv1(X,Y , cv.fold=cv.fold,step=0.5), simplify=FALSE) 
error.cv <- sapply(result, "[[", "error.cv")

#       [,1]      [,2]      [,3]      [,4]      [,5]#repeattimes
#99 0.3157895 0.2456140 0.2456140 0.2280702 0.1929825#99个变量选到模型中
#50 0.2807018 0.2456140 0.2456140 0.2631579 0.2105263
#25 0.3157895 0.2456140 0.2280702 0.2631579 0.2105263
#12 0.2631579 0.2456140 0.2807018 0.2280702 0.2456140
#6  0.3508772 0.2807018 0.3157895 0.2982456 0.3508772
#3  0.3684211 0.3157895 0.3859649 0.3333333 0.3684211
#1  0.4912281 0.4736842 0.5263158 0.4912281 0.5087719
#画图

#head_im_vars <- c(5,20) #cag
#head_im_vars <- c(5,10,20,40,50,100,200,300,400,500,700,1000) #metabolic
#head_im_vars <- c(5,10,20,40,50,100,200,300,400,500,700,1000,2000) #cag+metabolic
auc_ma_train<-matrix(0,nrow=length(head_im_vars),ncol=2)
auc_ma_test<-matrix(0,nrow=length(head_im_vars),ncol=2)
num_head=1
roc_test_list<-list()
roc_train_list<-list()
ori_outdir <- outdir
for( head_im_var in head_im_vars){
	outdir <- paste(ori_outdir,"/",head_im_var,sep="")
	if(!file.exists(outdir)){
    	dir.create(outdir)
	}
#####draw cv_error_plot.pdf
    outpdf=paste(outdir,"/","cverrof.pdf",sep="")
# cairo_pdf(outpdf)   
#    pdf(outpdf)
    cv_plot<-ggplot()
    cv_plot<-cv_plot+geom_point(aes(result[[1]]$n.var,rowMeans(error.cv)))+geom_path(aes(x=result[[1]]$n.var,y=rowMeans(error.cv)))
    cv_plot<-cv_plot+labs(x="the numbers of variable",y="cv.error")+theme(panel.background = element_blank(),panel.border = element_rect(colour = "black",fill = NA),axis.text = element_text(face="bold",colour = "black"))
#   cv_plot
#   dev.off()
ggsave(outpdf)

######        
	outpdf = paste(outdir,"/","cv_error.pdf",sep="");
	pdf(outpdf)
	matplot(result[[1]]$n.var, cbind(rowMeans(error.cv), error.cv), type="l", lwd=c(2, rep(1, ncol(error.cv))), col=1, lty=1, log="x",xlab="Number of variables", ylab="CV Error") 
	abline(v=head_im_var,col="pink",lwd=2) 
	dev.off()
	error.cv.cbm<-cbind(rowMeans(error.cv), error.cv)
	cutoff<-min (error.cv.cbm[,1])+sd(error.cv.cbm[,1]) #所有变量中，cv最小对应的变量数目+一个sd，
	error.cv.cbm[error.cv.cbm[,1]<cutoff,]#取出10个变量，重复5次的cv


	#####pick 10 marker by corossvalidation####### k=1

	ncol_da = ncol(X)#自变量个数
	nrow_da = repeattimes*cv.fold
	b <- matrix(0,ncol=ncol_da,nrow=nrow_da);
	k=1;
	for(i in 1:repeattimes){
		for(j in 1:cv.fold){
			b[k,]<-result[[i]]$res[[j]] #4 3 1 2
			k=k+1
		} 
	}
	if(head_im_var == 1)
	{
			mlg.list<-b[,1:head_im_var]
			mlg.list<-as.matrix(mlg.list)
			
	}else
	{
	mlg.list<-b[,1:head_im_var]
	}
	list<-c()
	k=1
	for(i in 1:head_im_var){ #每次验证时候，最重要的前10个变量
		for(j in 1:nrow_da){#repeattimes*cv.fold
	 		list[k]<-mlg.list[j,i] 
	 		k=k+1
		} 
	}
	
	mlg.sort<-as.matrix(table(list))
	mlg.sort<-mlg.sort[rev(order(mlg.sort[,1])),] #因为所有验证在一起，最终要的可能多余10个
	pick<- as.numeric(names(head(mlg.sort,head_im_var)))#最重要的前10个变量
	mlg.pick<-colnames(X)[pick]#取出变量的名字
	outfile = paste(outdir,"/","cross_validation_pick_",head_im_var,".im.var.txt",sep="");
	write.table(mlg.pick,outfile, sep="\t",quote=F,col.names=F)

	###,用前10个重要变量做随机森林,并画box图
	set.seed(999)
	#######box1######
	train1.rf <- randomForest(X[,pick], Y,importance = TRUE,maxnodes=4,ntree=10000)
	outpdf = paste(outdir,"/","top_",head_im_var,"var_imp.pdf",sep="")
	pdf(outpdf)
	varImpPlot(train1.rf)
	dev.off()
	out_imp_file = paste(outdir,"/","top_",head_im_var,"var_imp.xls",sep="")
	imp <- importance(train1.rf)
	write.table(imp,out_imp_file,quote = F,sep="\t")
	train1.pre <- predict(train1.rf,testset[2:ncol(testset)],type="prob") 

	rownames(train1.pre) = testset[,1];
	box_data=c(length=length(testset[,1]))
	for(i in 1:nrow(train1.pre) ){
		box_data[i]=train1.pre[i,rownames(train1.pre)[i]]
	}
	outfile = paste(outdir,"/","testset.probabilty.xls",sep="")
	write.table(train1.pre, outfile,quote = F,sep="\t")
    #draw imp plot
outpdf=paste(outdir,"/","impplot",head_im_var,".pdf",sep="");
#require(ggplot2)
#impplot<-ggplot()
#   impplot<-impplot+geom_point(aes(x=imp[,1],y=reorder(rownames(imp),imp[,1])))
#   impplot<-impplot+geom_hline(aes(yintercept =seq(1:nrow(imp))),linetype=3,colour="red",size=1)
#   impplot<-impplot+geom_point(aes(x=imp[,1],y=reorder(rownames(imp),imp[,1])))
#   impplot<-impplot+labs(x="MeanDecreaseAccuracy",y="Taxnomy")+scale_size_continuous(name="")+theme(panel.background = element_blank()
#    ,panel.border = element_rect(colour = "black",fill = NA),axis.text = element_text(face="bold",colour = "black"))
#   impplot
    impplot<-ggplot()
    impplot<-impplot+geom_bar(aes(x=reorder(rownames(imp),imp[,1]),y=imp[,1]),stat="identity",fill="red",color="black")+coord_flip()
    impplot<-impplot+theme(panel.background = element_blank()
                                   ,panel.border = element_rect(colour = "black",fill = NA),axis.text = element_text(face = "bold",colour = "black"))
    impplot<-impplot+labs(x="Taxnomy",y="MeanDecreaseAccuracy")+scale_size_continuous(name="")
    
    impplot 

ggsave(outpdf)
#    ggsave(paste("impplot.",head_im_var,"pdf",sep=""),path=outdir)
    #draw_box
	outpdf = paste(outdir,"/","top_",head_im_var,"testset.var_predict_box_plot.pdf",sep="")
	pdf(outpdf)
	boxplot(box_data ~ testset[,1], col=c(1:length(as.character(unique(testset[,1])))  ),  main="Probability predict for the true class")
	dev.off()

	outfile = paste(outdir,"/","cross_validation.",head_im_var,"testset.marker.predict.xls",sep="");
	write.table(train1.pre, outfile , sep="\t",quote=F)


	###############ROC curve #######################
	#important OTU draw all samples' ROC
	if( length(unique(as.character(Y))) ==2){ #只有两个分组时候才画ROC
		realclass = rownames(train1.pre)
		preprob <- train1.pre[,1] #取第一列为，为正概率
		names(preprob)=NULL
		library(pROC)
	    outpdf = paste(outdir,"/","testset.ROC.pdf",sep="")
		pdf(outpdf)
		roc1 = roc(realclass, preprob, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)                    
		roc1 = roc(realclass, preprob, ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=F, plot=T,auc.polygon=T, percent=roc1$percent,col=2,print.thres="best")
		roc_test_list[[num_head]]<-list(num=head_im_var,roc=roc1)

		outroc = paste(outdir,"/","testset.roc.xls",sep="")
	    roc_out = c(roc1$ci[2],roc1$ci[1],roc1$ci[3])
	    write.table(roc_out,outroc,quote = F,sep = "\t",col.names=F)
		sens.ci <- ci.se(roc1, specificities=seq(0, 100, 5)) #横坐标位置
		plot(sens.ci, type="shape", col=rgb(0,1,0,alpha=0.2))
		plot(sens.ci, type="bars")
		plot(roc1,col=2,add=T) 
		legend("bottomright",c(paste("AUC=",round(roc1$ci[2],2),"%"), paste("95% CI:",round(roc1$ci[1],2),"%-",round(roc1$ci[3],2),"%")),inset = 0.05)
		dev.off()
        auc_ma_test[num_head,1]<-head_im_var
        auc_ma_test[num_head,2]<-roc1$auc[1]
	}

	#######box2######
	train1.pre <- predict(train1.rf,type="prob") 

	rownames(train1.pre) = trainset[,1];
	box_data=c(length=length(trainset[,1]))
	for(i in 1:nrow(train1.pre) ){
		box_data[i]=train1.pre[i,rownames(train1.pre)[i]]
	}
	outfile = paste(outdir,"/","trainset.probabilty.xls",sep="")
	write.table(train1.pre, outfile,quote = F,sep="\t")
	#draw_box
	outpdf = paste(outdir,"/","top_",head_im_var,"trainset.var_predict_box_plot.pdf",sep="")
	pdf(outpdf)
	boxplot(box_data ~ trainset[,1], col=c(1:length(as.character(unique(trainset[,1])))  ),  main="Probability predict for the true class")
	dev.off()

	outfile = paste(outdir,"/","cross_validation.",head_im_var,"trainset.marker.predict.xls",sep="");
	write.table(train1.pre, outfile , sep="\t",quote=F)


	################ROC curve #######################
	#important OTU draw all samples' ROC
	if( length(unique(as.character(Y))) ==2){ #只有两个分组时候才画ROC
		realclass = rownames(train1.pre)
		preprob = train1.pre[,1] #取第一列为，为正概率
		names(preprob)=NULL
		library(pROC)
	    outpdf = paste(outdir,"/","trainset.ROC.pdf",sep="")
		pdf(outpdf)
		roc1 = roc(realclass, preprob, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)                    
		roc1 = roc(realclass, preprob, ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=F, plot=T,auc.polygon=T, percent=roc1$percent,col=2,print.thres="best")
		roc_train_list[[num_head]]<-list(num=head_im_var,roc=roc1)
	
		outroc = paste(outdir,"/","trainset.roc.xls",sep="")
	    roc_out = c(roc1$ci[2],roc1$ci[1],roc1$ci[3])
	    write.table(roc_out,outroc,quote = F,sep="\t")
		sens.ci <- ci.se(roc1, specificities=seq(0, 100, 5)) #横坐标位置
		plot(sens.ci, type="shape", col=rgb(0,1,0,alpha=0.2))
		plot(sens.ci, type="bars")
		plot(roc1,col=2,add=T) 
		legend("bottomright",c(paste("AUC=",round(roc1$ci[2],2),"%"), paste("95% CI:",round(roc1$ci[1],2),"%-",round(roc1$ci[3],2),"%")),inset = 0.05)
		dev.off()
    auc_ma_train[num_head,1]<-head_im_var
		auc_ma_train[num_head,2]<-roc1$auc[1]
	}
    num_head=num_head+1
}

#####
max_in_test<-which(auc_ma_test[,2]==max(auc_ma_test[,2]))


name_max_test<-auc_ma_test[max_in_test,1]

value_max_test<-auc_ma_test[max_in_test,2]
auc_test_max<-data.frame(name_max_test,value_max_test)
if (dim(auc_test_max)[1]>1) 
{
    print (paste("the max auc of test have ",dim(auc_test_max)[1],"not only one ."))
}
outfile = paste(ori_outdir,"/","max_auc_test.xls",sep="")
write.table(auc_test_max,outfile,sep="\t",row.names=F,quote = F)
outpdf = paste(ori_outdir,"/","testset.point_auc.pdf",sep="")
#pdf(outpdf)
auc_plot<-ggplot()

auc_plot<-auc_plot+geom_path(aes(auc_ma_test[,1],auc_ma_test[,2]))+geom_point(aes(x=auc_ma_test[,1],y=auc_ma_test[,2]))+geom_point(aes(x=name_max_test,y=value_max_test),color="red")

auc_plot<-auc_plot+theme(panel.background = element_blank(),panel.border = element_rect(colour = "black",fill = NA)
                         ,axis.text = element_text(face="bold",colour = "black"))
auc_plot
#   dev.off()
ggsave(outpdf)


outpdf<-paste(ori_outdir,"/","testset_auc.pdf",sep="")
pdf(outpdf)
leg<-c()
leg_col<-c()
for (i in 1:length(roc_test_list))
{
  if (i == 1)
  {
    plot.roc(roc_test_list[[i]]$roc,print.thres = "best",col=col$V1[i])
    leg[i]<-paste(roc_test_list[[i]]$num,":","AUC=",round(roc_test_list[[i]]$roc$ci[2],2),"%")
    leg_col[i]<-col$V1[i]
  }
  else{
  plot.roc(roc_test_list[[i]]$roc,add=T,print.thres = "best",col=col$V1[i])
  leg[i]<-paste(roc_test_list[[i]]$num,":","AUC=",round(roc_test_list[[i]]$roc$ci[2],2),"%")
  leg_col[i]<-col$V1[i]}
}
legend("bottomright",leg,col=leg_col,inset=0.05,lty=1)

dev.off()


###
max_in_train<-which(auc_ma_train[,2]==max(auc_ma_train[,2]))

name_max_train<-auc_ma_train[max_in_train,1]

value_max_train<-auc_ma_train[max_in_train,2]

auc_train_max<-data.frame(name_max_train,value_max_train)
if (dim(auc_train_max)[1]>1) 
{
    print (paste("the max auc of train have ",dim(auc_train_max)[1],"not only one ."))
}
outfile = paste(ori_outdir,"/","max_auc_train.xls",sep="")
write.table(auc_train_max,outfile,sep="\t",row.names=F,quote = F)
outpdf = paste(ori_outdir,"/","trainset.point_auc.pdf",sep="")
#pdf(outpdf)
auc_plot<-ggplot()
auc_plot<-auc_plot+geom_path(aes(auc_ma_train[,1],auc_ma_train[,2]))+geom_point(aes(x=auc_ma_train[,1],y=auc_ma_train[,2]))+geom_point(aes(x=name_max_train,y=value_max_train),color="red")
auc_plot<-auc_plot+theme(panel.background = element_blank(),panel.border = element_rect(colour = "black",fill = NA)
                         ,axis.text = element_text(face="bold",colour = "black"))
auc_plot
#auc_plot_train
#dev.off()
ggsave(outpdf)

outpdf<-paste(ori_outdir,"/","trainset_auc.pdf",sep="")
pdf(outpdf)
leg<-c()
leg_col<-c()
for (i in 1:length(roc_train_list))
{
  if (i == 1)
  {
    plot.roc(roc_train_list[[i]]$roc,print.thres = "best",col=col$V1[i])
    leg[i]<-paste(roc_train_list[[i]]$num,":","AUC=",round(roc_train_list[[i]]$roc$ci[2],2),"%")
    leg_col[i]<-col$V1[i]
  }
  else{
  plot.roc(roc_train_list[[i]]$roc,add=T,print.thres = "best",col=col$V1[i])
  leg[i]<-paste(roc_train_list[[i]]$num,":","AUC=",round(roc_train_list[[i]]$roc$ci[2],2),"%")
  leg_col[i]<-col$V1[i]}
}
legend("bottomright",leg,col=leg_col,inset=0.05,lty=1)

dev.off()
