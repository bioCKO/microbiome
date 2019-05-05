##ramdomforest.crossvalidation.r##
##Begin##
get_max_colname = function(x){
	name_vector = rep("", nrow(x))
	for(i in 1:nrow(x)){
		current_line = x[i,];
		tem_line = current_line;
		tem_line=sort(tem_line,decreasing=T)
		if(tem_line[1]==tem_line[2]){cat(tem_line,"\n")}
		max_value=0;
		max_idx=0
		for(j in 1:length(current_line)){
			if(current_line[j]>max_value){
				max_value=current_line[j];
				max_idx=j;
			}
		}
		name_vector[i]=names(current_line)[max_idx]
	}
	return(name_vector)
}
	
rfcv1 <-function (trainx, trainy, cv.fold = 10, scale = "log", step = 0.5, mtry = function(p) max(1, floor(sqrt(p))), 	recursive = FALSE, ...){
	library(randomForest)
	classRF <- is.factor(trainy)
	n <- nrow(trainx)
	p <- ncol(trainx)
	if (scale == "log") {#cv的x轴
		k <- floor(log(p, base = 1/step)) #将变量分成多少份。
		n.var <- round(p * step^(0:(k - 1))) #4*(1.0, 0.5)，每一份的变量
		same <- diff(n.var) == 0
		if (any(same)) n.var <- n.var[-which(same)]
		if (!1 %in% n.var) n.var <- c(n.var, 1)
	}else{
		n.var <- seq(from = p, to = 1, by = step)
	}
	k <- length(n.var)
	cv.pred <- vector(k, mode = "list")
	for (i in 1:k) cv.pred[[i]] <- rep(0,length(trainy)) #每个x轴点，分类结果
	if (classRF) {
		f <- trainy
	}else {
		f <- factor(rep(1:5, length = length(trainy))[order(order(trainy))])
	}
	nlvl <- table(f)#表格
	idx <- numeric(n)#样品
	for (i in 1:length(nlvl)) {#length(nlvl)分类数目
		idx[which(f == levels(f)[i])] <- sample(rep(1:cv.fold, length = nlvl[i]))#样本随机编号
	}

	res=list()
	for (i in 1:cv.fold) {
		all.rf <- randomForest(trainx[idx != i, , drop = FALSE], trainy[idx != i],importance = TRUE,ntree=10000)#所有变量+样本的4/5
		aa = predict(all.rf,trainx[idx == i, , drop = FALSE],type="prob") 
		#cv.pred[[1]][idx == i] <- as.numeric(apply(aa,1,max))#cv.pred[[1]][idx == i] <- as.numeric(aa[,])#不解
		cv.pred[[1]][idx == i] <- get_max_colname(aa);
		impvar <- (1:p)[order(all.rf$importance[, "MeanDecreaseAccuracy"], decreasing = TRUE)] #不解all.rf$importance[, "MeanDecreaseAccuracy"]
		res[[i]]=impvar
		for (j in 2:k) {#x轴坐标个数k=3
			imp.idx <- impvar[1:n.var[j]]#最重要的前几个变量。3和4,变量数目一次减少。最后只剩，最重要的一个变量n.var=（4 ）2 1
			sub.rf <- randomForest(trainx[idx != i, imp.idx,drop = FALSE], trainy[idx != i],ntree=10000)#用最重要的两个变量+样本的4/5
			bb <- predict(sub.rf,trainx[idx ==i,imp.idx, drop = FALSE],type="prob") 
			#cv.pred[[j]][idx == i] <- as.numeric(bb[,2])
			cv.pred[[j]][idx == i] <- get_max_colname(bb);
			if (recursive) {
				impvar <- (1:length(imp.idx))[order(sub.rf$importance[,3], decreasing = TRUE)]
			} 
			NULL
		} 
		NULL
	}

#	if (classRF) {
		#error.cv <- sapply(cv.pred, function(x) mean(factor(ifelse(x>0.5,1,0))!=trainy))
		error.cv <- sapply(cv.pred, function(x) mean(x!=trainy))
#	}else {
#		error.cv <- sapply(cv.pred, function(x) mean((trainy - x)^2))
#	}
	names(error.cv) <- names(cv.pred) <- n.var
	list(n.var = n.var, error.cv = error.cv, predicted = cv.pred,res=res)
} 
