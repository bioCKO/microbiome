#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
my ($dep_cut,$rank,$gc_range,$xtitle,$ytitle,$width,$cluster,$grey) = 
(-1, '3:4','-1:-1','GC%','Sequencing Depth(X)',300,5);
my ($dep_clu,$heigh,$clustf);
GetOptions(
        "dep_cut:i"=>\$dep_cut,"dep_clu:i"=>\$dep_clu,"rank:s"=>\$rank,"cluster:i"=>\$cluster,
        "width:i"=>\$width,"heigh:i"=>\$heigh,"xtitle:s"=>\$xtitle,"ytitle:s"=>\$ytitle,
        "clustf:s"=>\$clustf,"gc_range:s"=>\$gc_range,"grey"=>\$grey
);
$dep_clu ||= $dep_cut;
$heigh ||= $width;
#################################################################################
@ARGV || die"Name: draw_gedepth_R.pl
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
my ($infile,$outfile) = @ARGV;
#my $r_script = "/usr/bin/R";
my $r_script = "System/R-2.15.3/bin/R";
$clustf ||= (split/\//,$infile)[-1] . ".cluster";
#my $kmean = "$Bin/kmeans.R";
my @rank = split/:|,/,$rank;
my @gc_cut = split/:|,/,$gc_range;
my $kmean_R = "kmer$$.R";
open KR,">$kmean_R" || die$!;
my $rfile=&make_kmean($width,$heigh,$xtitle,$ytitle,$cluster,$infile,$clustf,$outfile,$dep_cut,$dep_clu,@rank,@gc_cut,$grey);#sub1
print KR $rfile;
close KR;
system "$r_script -f $kmean_R >/dev/null;rm $kmean_R";
#################################################################################
sub make_kmean{
   my ($width,$heigh,$xtitle,$ytitle,$cluster,$inflie,$clustf,$outfile,$dep_cut,
           $dep_clu,$rank1,$rank2,$gc_cut1,$gc_cut2,$grey) = @_;
   $grey ||= 0;
   my $strs = "#get limit cut
data <- read.table('$infile',head=F)
min.gc <- floor(min(data[,$rank1])/5) * 5
max.gc <- floor(max(data[,$rank1])/5) * 5
max.depth <- floor(max(data[,$rank2])/50+1) * 50
if(max.gc * 5 < max(data[,$rank1])) max.gc <- max.gc + 5
if(max.depth * 5 < max(data[,$rank2])) max.depth <- max.depth + 5

depth.cutoff <- max.depth
if($gc_cut1 >= 0) min.gc <- $gc_cut1
if($gc_cut2 >= 0) max.gc <- $gc_cut2
if($dep_cut >= 0) max.depth <- $dep_cut
if($dep_clu >= 0) depth.cutoff <- $dep_clu
#do cluster with kmeans
data.f <- data[data[,$rank2] <= depth.cutoff,]
data.f.km <- kmeans(scale(data.f[,$rank1:$rank2]), $cluster)
len <- length(data.f[,1])

data.f[,5] <- data.f.km\$cluster
write.table(data.f, file='$clustf',sep='\t',quote=F, append=F)

depth.break <- 1
data.gc <- data[,$rank1:$rank2]
data.gc <- data.gc[data.gc[,1] >= min.gc & data.gc[,1] <= max.gc, ] 
data.gc <- data.gc[data.gc[,2] <= max.depth, ]
data.gcdep.max <- max(data.gc[,2])
data.gc[,2] <- data.gc[,2]/depth.break 
data.gc <- as.matrix(data.gc)

x <- nrow(data.gc)
data.gcc <- matrix(0,nrow=x+2,ncol=2)
data.gcc[1:x,] <- data.gc
data.gcc[x+1,] <- c(min.gc,0)
data.gcc[x+2,] <- c(max.gc,max.depth)
data.gc <- as.matrix(data.gcc)

numbr <- max.gc - min.gc
data.numb <- matrix(0,nrow=numbr,ncol=max.depth)
data.col <- c(1:nrow(data.gc));
data.col[] <- 0
num.db <- matrix(0,nrow=nrow(data.gc),ncol=2);
for(i in 1:nrow(data.gc)) {
	k = floor(data.gc[i,1]-min.gc) + 1
	m = floor(data.gc[i,2]) + 1
	if(k > numbr) k <- numbr
	if(m > max.depth) m <- max.depth
	data.numb[k,m] = data.numb[k,m] + 1
    num.db[i,1] <- k
    num.db[i,2] <- m
}
max.dp <- max(max(data.numb))
for(i in 1:x) {
    k <- num.db[i,1]
    m <- num.db[i,2]\n" .
(    !$grey ? 
"    data.col[i] = data.numb[k,m] * data.numb[k,m]/2\n" :
"    data.col[i] = 0.7 * ((max.dp - data.numb[k,m]) / max.dp)^2\n" ).
"}
data.col[x+1] <- $grey
data.col[x+2] <- $grey

pdf('$outfile')
nf <- layout(matrix(c(0,2,0,0,1,3),2,3,byrow=T),c(0.5,3,1),c(1,3,0.5),TRUE)
par(mar=c(5,5,0.5,0.5))\n" .
( !$grey ? "plot(data.gc,xlab='$xtitle',ylab='$ytitle',pch=20,cex=0.25,col=hcl(h=0,c=data.col,l=70),xlim=c(min.gc,max.gc),ylim=c(0,max.depth))\n" :
"plot(data.gc,xlab='$xtitle',ylab='$ytitle',cex.lab=1.5,pch=20,cex=0.25,col=grey(data.col),xlim=c(min.gc,max.gc),ylim=c(0,max.depth))\n" ) .
"#plot(data.gc,xlab='$xtitle',ylab='$ytitle',pch=16,col=hcl(h=0,c=data.col,l=70),xlim=c(min.gc,max.gc),ylim=c(0,max.depth))


xhist <- hist(data.gc[,1],breaks=numbr,plot=FALSE)
yhist <- hist(data.gc[,2],breaks=numbr,plot=FALSE)
par(mar=c(0,5,1,0.5))
barplot(xhist\$counts,space=0,col=\"lightcyan\")
par(mar=c(5,0,0.5,1))
barplot(yhist\$counts,space=0,col=\"lightcyan\",horiz=TRUE)

dev.off()
";
    $strs;
}
