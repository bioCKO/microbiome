#*****************************************************************************************************
#*****************************************************************************************************
#  Last modified: 4/14/2009 
#  
#  Author: james robert white, whitej@umd.edu, Center for Bioinformatics and Computational Biology.
#  University of Maryland - College Park, MD 20740
#
#  This software is designed to identify differentially abundant features between two groups
#  Input is a matrix of frequency data. Several thresholding options are available.
#  See documentation for details.
#*****************************************************************************************************
#*****************************************************************************************************

#*****************************************************************************************************
#  detect_differentially_abundant_features:
#  the major function - inputs an R object "jobj" containing a list of feature names and the 
#  corresponding frequency matrix, the argument g is the first column of the second group. 
#  
#  -> set the pflag to be TRUE or FALSE to threshold by p or q values, respectively
#  -> threshold is the significance level to reject hypotheses by.
#  -> B is the number of bootstrapping permutations to use in estimating the null t-stat distribution.
#*****************************************************************************************************
#*****************************************************************************************************
detect_differentially_abundant_features <- function(infile,group1,group2,g,output,output2,output3, pflag = NULL, threshold = NULL, B = NULL,method=t, name1=NULL, name2=NULL){

  jobj<-load_frequency_matrix(infile,group1,group2)
#head(jobj$matrix)
#**********************************************************************************
# ************************ INITIALIZE COMMAND-LINE ********************************
# ************************        PARAMETERS       ********************************
#**********************************************************************************
  qflag = FALSE;
    if (is.null(B)){
    B = 1000;
  }
  if (is.null(threshold)){
    threshold = 0.05;
  }
  if (is.null(pflag)){
    pflag = TRUE;
    qflag = FALSE;
  }
  if (pflag == TRUE){
    qflag = FALSE;
  }
  if (pflag == FALSE){
    qflag = TRUE;
  }

#threshold = 0.95
#********************************************************************************
# ************************ INITIALIZE PARAMETERS ********************************
#********************************************************************************

#*************************************
Pmatrix <- jobj$matrix;                   # the feature abundance matrix
taxa <- jobj$taxa;                        # the taxa/(feature) labels of the TAM
c=c()
ncols = ncol(Pmatrix)  
for(i in 1:dim(Pmatrix)[1]){
  if( (sum(Pmatrix[i, 1:g-1])==0) & (sum(Pmatrix[i, g:ncols])==0) ){
    c= append(c,-i)
  }
}
Pmatrix=Pmatrix[c,]
taxa=taxa[c]
ncols = ncol(Pmatrix)
nrows = nrow(Pmatrix);                   
confmatrix <- array(0, dim=c(nrows,2));   #stores 95% confident intervals
C1 <- array(0, dim=c(nrows,2));           # statistic profiles for class1 and class 2
C2 <- array(0, dim=c(nrows,2));           # mean[1], variance[2], standard error[3]   
#T_statistics <- array(0, dim=c(nrows,1)); # a place to store the true t-statistics 
pvalues <- array(0, dim=c(nrows,1));      # place to store pvalues
qvalues <- array(0, dim=c(nrows,1));      # stores qvalues
#*************************************


if(method=="t"){
  for (i in 1:nrows){           # for each feature 
#if( (sum(Pmatrix[i, 1:g-1])!=0) | (sum(Pmatrix[i, g:ncols])!=0)  ) {
        ft <- t.test(Pmatrix[i, 1:g-1],Pmatrix[i, g:ncols], alternative = "two.sided", conf.int = T);
        pvalues[i] = ft$p.value;
        confmatrix[i,1]=ft$conf.int[1]
        confmatrix[i,2]=ft$conf.int[2]
        C1[i,]=c(mean(Pmatrix[i, 1:g-1]),sd(Pmatrix[i, 1:g-1]))
        C2[i,]=c(mean(Pmatrix[i, g:ncols]),sd(Pmatrix[i, g:ncols]))
#}
  }
}else if(method=="wilcox"){
    for(i in 1:nrows){
#if( (sum(Pmatrix[i, 1:g-1])!=0) | (sum(Pmatrix[i, g:ncols])!=0)  ) {
            ft <- wilcox.test(Pmatrix[i, 1:g-1],Pmatrix[i, g:ncols], alternative = "two.sided");
            pvalues[i] = ft$p.value;
            C1[i,]=c(mean(Pmatrix[i, 1:g-1]), sd(Pmatrix[i, 1:g-1]))
            C2[i,]=c(mean(Pmatrix[i, g:ncols]), sd(Pmatrix[i, g:ncols]))
#        }
    }
}


qvalues <- calc_qvalues(pvalues); 
#cat(qvalue,"\n")
#*************************************
s1 = sum(pvalues <= threshold, na.rm=T);#add na.omit=T by hanyuqiao
s2 = sum(qvalues <= threshold, na.rm=T);#add na.omit=T by hanyuqiao
if(method=="t"){
    p_Differential_matrix <- array(0, dim=c(s1,9));
    q_Differential_matrix <- array(0, dim=c(s2,9));
}else if(method=="wilcox"){ 
    p_Differential_matrix <- array(0, dim=c(s1,7));   
    q_Differential_matrix <- array(0, dim=c(s2,7));
}

#p <0.05 tax
dex = 1;
dex2 = 1;
for (i in 1:nrows){
  if (isTRUE(pvalues[i] <= threshold)){#by hanyuqiao
    p_Differential_matrix[dex,1]   = taxa[i];
    p_Differential_matrix[dex,2:3] = C1[i,];  
    p_Differential_matrix[dex,4:5] = C2[i,];  
    p_Differential_matrix[dex,6]   = pvalues[i];
    p_Differential_matrix[dex,7]   = qvalues[i];
    if(method=="t"){
        p_Differential_matrix[dex,8:9]   = confmatrix[i,1:2]
    }
    dex = dex+1
  }
}

avggn1 = paste("avg(",name1,")",sep="");
avggn2 = paste("avg(",name2,")",sep="");
sdgn1 = paste("sd(",name1,")",sep="");
sdgn2 = paste("sd(",name2,")",sep="");
if(method=="t"){
    colnames(p_Differential_matrix) = c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value",  "q.values", "interval lower","interval upper")
}else if(method=="wilcox"){
    colnames(p_Differential_matrix) = c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value","q.values")
}
#show(Differential_matrix);
if(method=="t"){
    Total_matrix <- array(0, dim=c(nrows,9));
}else if(method=="wilcox"){ 
   Total_matrix <- array(0, dim=c(nrows,7));;   
}

#all test result 
for (i in 1:nrows){
    Total_matrix[i,1]   = taxa[i];
    Total_matrix[i,2:3] = C1[i,];
    Total_matrix[i,4:5] = C2[i,];
    Total_matrix[i,6]   = pvalues[i];
    Total_matrix[i,7]   = qvalues[i];
    if(method=="t"){
        Total_matrix[i,8:9]   = confmatrix[i,1:2]
    }
}
if(method=="t"){
    colnames(Total_matrix) = c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value","q.values","interval lower","interval upper")
}else if(method=="wilcox"){
    colnames(Total_matrix) =c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value","q.values")
}

dex = 1;
for (i in 1:nrows){
  if (isTRUE(qvalues[i] <= threshold) ){#by hanyuqiao
    q_Differential_matrix[dex,1]   = taxa[i];
    q_Differential_matrix[dex,2:3] = C1[i,];  
    q_Differential_matrix[dex,4:5] = C2[i,];  
    q_Differential_matrix[dex,6]   = pvalues[i];
    q_Differential_matrix[dex,7]   = qvalues[i];
    if(method=="t"){
        q_Differential_matrix[dex,8:9]   = confmatrix[i,1:2]
    }
    dex = dex+1;
  }
}
if(method=="t"){
    colnames(q_Differential_matrix) = c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value","q.values","interval lower","interval upper")
}else if(method=="wilcox"){
    colnames(q_Differential_matrix) =c("Taxa",avggn1,sdgn1,avggn2,sdgn2,"p.value","q.values")
}




#write(t(Total_matrix), output, ncolumns = 8, sep = "\t");
p_Differential_table=as.data.frame(p_Differential_matrix)
Total_table=as.data.frame(Total_matrix)
q_Differential_table=as.data.frame(q_Differential_matrix)
write.table(Total_table,file=output,row.names = F,quote = FALSE,sep = "\t");
write.table(p_Differential_table,file=output2,row.names = F,quote = FALSE,sep = "\t");
write.table(q_Differential_table,file=output3,row.names = F,sep = "\t",quote = FALSE);
}
#************************************************************************
# ************************** SUBROUTINES ********************************
#************************************************************************

#*****************************************************************************************************
# takes a matrix, a permutation vector, and a group division g.
# returns a set of ts based on the permutation.
#*****************************************************************************************************
permute_and_calc_ts <- function(Imatrix, y, g)
{
  nr = nrow(Imatrix);
  nc = ncol(Imatrix);
  # first permute the rows in the matrix
  Pmatrix <- Imatrix[,y[1:length(y)]];
  Ts <- calc_twosample_ts(Pmatrix, g, nr, nc);
  return (Ts);
}


#*****************************************************************************************************
#  load up the frequency matrix from a file
#*****************************************************************************************************
load_frequency_matrix <- function(file,group1,group2){
  dat2 <- read.table(file,skip=1,header=FALSE,sep="\t");
  # load names
  total_group=c(group1,group2)
  taxa <- array(0,dim=c(nrow(dat2)));
  for(i in 1:length(taxa)) {
    taxa[i] <- as.character(dat2[i,1]);
  }

  dat2 <- read.table(file,header=TRUE,sep="\t");
  # load remaining counts
  matrix <- array(0, dim=c(length(taxa),length(total_group)));
  for(i in 1:length(taxa)){
    for(j in 1:length(total_group)){ 
      matrix[i,j] <- as.numeric(dat2[i,total_group[j]]);
    }
  }
  job <- list(matrix=matrix, taxa=taxa)
  return(job);
}

calc_qvalues <- function(pvalues){
  nrows = length(pvalues);

  # create lambda vector
  lambdas <- seq(0,0.95,0.01);
  pi0_hat <- array(0, dim=c(length(lambdas)));

  # calculate pi0_hat
  for (l in 1:length(lambdas)){ # for each lambda value
    count = 0;
    for (i in 1:nrows){ # for each p-value in order
      if ( isTRUE(pvalues[i] > lambdas[l])){
        count = count + 1;  
      }
      pi0_hat[l] = count/(nrows*(1-lambdas[l]));
    }
  }

  f <- unclass(smooth.spline(lambdas,pi0_hat,df=3));
  f_spline <- f$y;
  pi0 = f_spline[length(lambdas)];   # this is the essential pi0_hat value

  # order p-values
  ordered_ps <- order(pvalues);
  pvalues <- pvalues;
  qvalues <- array(0, dim=c(nrows));
  ordered_qs <- array(0, dim=c(nrows));

  ordered_qs[nrows] <- min(pvalues[ordered_ps[nrows]]*pi0, 1);
  for(i in (nrows-1):1) {
    p = pvalues[ordered_ps[i]];
    new = p*nrows*pi0/i;
    ordered_qs[i] <- min(new,ordered_qs[i+1],1);
  }

  # re-distribute calculated qvalues to appropriate rows
  for (i in 1:nrows){
    qvalues[ordered_ps[i]] = ordered_qs[i];
  }

  ################################
  # plotting pi_hat vs. lambda
  ################################
  # plot(lambdas,pi0_hat,xlab=expression(lambda),ylab=expression(hat(pi)[0](lambda)),type="p");
  # lines(f);

  return (qvalues);
}

