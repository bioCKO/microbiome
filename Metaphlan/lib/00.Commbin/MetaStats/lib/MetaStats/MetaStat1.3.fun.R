suppressPackageStartupMessages(library("optparse"))
option_list <- list(
		make_option("--infilepath", action="store",default=NULL, help="The input files path"),
        make_option("--output", action="store",default='output', help="The output files name, default= output"),
		make_option("--group", action="store",default=NULL, help="The file contain group infomation ,without header"),
		make_option("--vs", action="store", default=NULL, help="The Comparison group info,look like: Contrast,Case;Contrast,Case;Contrast,Case..."),
		make_option("--outdir", action="store",,default="./", help="The output dirctory,  [default %default]"),
		make_option("--threshold", type="double",default=0.05, help="The cutoff value or sig [default %default]"),
		make_option("--Vslist", action="store",default=NULL, help="The Comparison group info,look like: a\tb\nc\tb")
#make_option("--correlation", type="integer",default=1, help="Correlation to use: 1=pearson, 2=spearman, 3=kendall [default %default]"),
#make_option("--rmode", action="store_true",default=FALSE, help="Mode: TRUE=R mode, FALSE=Q mode [default %default]")
)

#get command line options
opt<-parse_args(OptionParser(usage="%prog [options] file\n", option_list=option_list))
if(is.null(opt$infilepath)||(is.null(opt$vs)&&is.null(opt$Vslist))){
	cat ("Use  %prog -h for more help info\nThe author: wangxiaohong@novogene.cn\n")
	quit("no")
}

#args<-commandArgs(T)
#if(length(args)<3){
#	cat("[usage:] <Dir:/otu97/Evenabs/> <greoup.info> <Contral_GroupAname,Case_GroupBname;Contral_GroupAname,Case_GroupCname;...> <Dir:outdir> \n")
#	cat ("Example:  plot_aplhaindex.R Report01/03.Make_OTU/otu97/Evenabs/ group.info GroupAname,GroupBname... outdir\n")
#	quit("no")
#}
infilepath <- opt$infilepath
matfiles<-opt$infilepath
group.file<-opt$group
outdir<-opt$outdir

if(!is.null(opt$Vslist)&&file.exists(opt$Vslist)){
	vslistdata<-read.table(opt$Vslist,sep="\t")
	vslistdata<-as.matrix(vslistdata)
	pnu<-dim(vslistdata)[1]
	for(i in 1:pnu){
		if(is.null(opt$vs)){
			opt$vs<-paste(as.vector(vslistdata[i,]),collapse=",")
		}else{
			opt$vs<-paste(opt$vs,paste(as.vector(vslistdata[i,]),collapse=","),sep=";")
		}
	}
}
if(!file.exists(outdir)){
	dir.create(outdir)
}

groupnames<-unlist (strsplit(opt$vs,",|;",fixed=F))
Pairs<-unlist(strsplit(opt$vs,";",fixed=T))
source ("/PUBLIC/software/MICRO/share/MetaGenome_pipeline/MetaGenome_pipeline_V3.1/lib/00.Commbin/MetaStats/lib/MetaStats/ddaf3.R") ##
group<-read.table(group.file,sep="\t",header=F)
#group.all<-group[,which(group[,2] %in% unlist(groupnames))==T]
group.all<-group[which(group[,2] %in% groupnames),][,1]
temp.outdir<-outdir

	cfgops<-opt$output
	if (!file.exists(outdir)){
		dir.create(outdir)
	}
	T.level<-read.table(infilepath,head=T,sep="\t")
	row.names(T.level)<-T.level[,1]
	T.level[,1]<-NULL
#T.level[,dim(T.level)[2]]<-NULL
	#data<-T.level[,1:(dim(T.level)[2]-1)]
	data<-T.level
	#colnames(data)<-colnames(T.level)[2:length(T.level[1,])]
	select.data<-colnames(data) %in% group.all
	select.name<-colnames(data)[select.data]
	#cat (select.name,"\n")
	#group<-group[which(group[,1] %in% colnames(data)),]
	#group.all<-group[which(group[,1] %in% groupnames),][,1]
	select.data.file<-paste(outdir,"/",opt$output,".xls",sep="")
	write.table(data[,select.data],select.data.file,quote = FALSE,sep="\t")
	data<-data[,select.data]
	#cat(length(Pairs),"\n")
	for(p in 1:length(Pairs)){
		pair<-unlist (strsplit(Pairs[p],",|;",fixed=F))
		#cat(pair[1],"\t",pair[2])
		#pair.data.file<-paste(outdir,"/",pair.file.name,".mat",sep="")
		
		##group1<-which(group[which(group[,1] %in% select.name),2]==pair[1])
		group1.dat<-which(group[,1] %in% select.name)[which(group[which(group[,1] %in% select.name),2]==pair[1])]
    group1<-which(select.name %in% group[group1.dat,1])
		#cat (group1,"\n")
		##group2<-which(group[which(group[,1] %in% select.name),2]==pair[2])
		group2.dat<-which(group[,1] %in% select.name)[which(group[which(group[,1] %in% select.name),2]==pair[2])]
		group2<-which(select.name %in% group[group2.dat,1])
		#cat (group2,"\n")
		mark.group2<-length(group1)+1
		#group.pair<-group[,which(group[,2] %in% pair)==T]
		group.pair<-c(group1,group2)
		#q("no")
			
		perfix<-paste(pair,collapse="-vs-")
		pair.file.name<-paste(outdir,"/",perfix,sep="")
		test.file.name<-paste(pair.file.name,".test.xls",sep="")
		p.file.name<-paste(pair.file.name,".psig.xls",sep="")
		q.file.name<-paste(pair.file.name,".qsig.xls",sep="")
		write.table(data[,group.pair],paste(pair.file.name,".",cfgops,".mat",sep=""),quote = FALSE,sep="\t",col.names = NA)
		#cat (mark_group2,"\n")
		detect_differentially_abundant_features(select.data.file,group1,group2,mark.group2,test.file.name,p.file.name,q.file.name,pflag = NULL, threshold = 0.05, B = NULL)
		#cat (select.data.file,group1,group2,mark_group2,test.file.name,p.file.name,q.file.name,"\n\n")
	}
#detect_differentially_abundant_features("./phylum/otu_table.p.absolute.mat",c(91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120),c(31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60),31, "./phylum/test_HC.A_GC.B","./phylum/psig_HC.A_GC.B","./phylum/qsig_HC.A_GC.B",pflag = NULL, threshold = 0.05, B = NULL)
