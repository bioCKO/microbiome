#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use lib "$Bin/../";
my $lib = "$Bin/../";
use PATHWAY;
use Data::Dumper;

my($convert,$R) = 
get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(CONVERT R6)]);
my %opt;
    GetOptions(\%opt,"indir:s","outdir:s","notrun");
	##add vs lefse
$opt{indir} || die "perl Usage $0 --indir rf_roc  \n
--indir rf_roc 
Dscription plot trainset_vs_group_max_auc.pdf \n
authot zhanghao by 20180512\n";
#print "$opt{indir}\n";
$opt{indir}=abs_path($opt{indir});
#print "indir\t$opt{indir}\n";
my $m=0;
for my $rank (`ls $opt{indir}`)
{
	my %vs;
	chomp $rank;
	#print "rank\t$rank\n";
	if (-d "$opt{indir}/$rank")
	{
		for my $vs_dir (`ls $opt{indir}/$rank`)
		{
			chomp $vs_dir;
			#print "vsdir\t$vs_dir\n";
			if ((-d "$opt{indir}/$rank/$vs_dir") && $vs_dir =~ /^(\d+)_/)
			{
				for my $file (`ls $opt{indir}/$rank/$vs_dir`)
				{
					
					chomp $file;
					
					if ($file =~ /max_auc_train\.xls/)
					{
						#print "file\t$file\n";
						open MAX ,"< $opt{indir}/$rank/$vs_dir/$file";
						<MAX>;
						my $line =<MAX>;
						chomp $line;
						my @max=split(/\t/,$line);
						#my $max{$vs_dir}=$max[0];
						close MAX;
						#$max=$max[0];
						
					#}
					#print "max\t$max[0]\n";
					for my $cross (`ls $opt{indir}/$rank/$vs_dir/$max[0]`)
					{
						#print ""
						chomp $cross;
					#	print "cc\t$cross\t$opt{indir}/$rank/$vs_dir/$max[0]\n";
						if ($cross =~ /\S+trainset\.marker\.predict\.xls/)
						{
							#print "cross\t$cross\n";
							open CRO ,"< $opt{indir}/$rank/$vs_dir/$max[0]/$cross";
							my $head=<CRO>;
							chomp $head;
							my @head=split(/\t/,$head);
							my $vs_group=join("-vs-",@head);
							while (<CRO>)
							{
								chomp;
								my @cross=split/\t/;
								
								push @{$vs{$vs_group}{name}},$cross[0];
								push @{$vs{$vs_group}{value}},$cross[1];

							}
						}
					
					}
				   
				   }
				
				}
			
			}
			
		}
			#print "rak $opt{indir}/$rank/\n";
			#print Dumper(\%vs);
			open R, "> $opt{indir}/$rank/vs_group.R";
			print R "library(pROC)\nlibrary(RColorBrewer)\n";
			print R "setwd(\"$opt{indir}/$rank\")\ncol<-read.table(\"$Bin/group.colorx.xls\",sep=\"\,\")\nleg<-c()\nleg_col<-c()\n";
			print R "outpdf=\"trainset_group_max_roc.pdf\"\npdf(outpdf)\n";
			my $n=0;
			foreach my $vs_group( sort keys %vs)
			{
				#print "vs_group $vs_group\n";
				$n++;
				my $realclass="realclass_$n";
				my $preprob="preprob_$n";
				my $name="c(\"".join ("\",\"",@{$vs{$vs_group}{name}})."\")";
				my $value="c(".join ("\,",@{$vs{$vs_group}{value}}).")";
				my $roc="roc_$n";
				print R "$realclass<-$name\n$preprob<-$value\n";
				print R " $roc = roc($realclass, $preprob, percent=TRUE, partial.auc.correct=TRUE,ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=FALSE,plot=F, auc.polygon=TRUE, max.auc.polygon=TRUE, grid=TRUE)\n";
				print R "$roc  = roc($realclass, $preprob, ci=TRUE, boot.n=100, ci.alpha=0.9, stratified=F, plot=F,auc.polygon=T, percent=$roc\$percent,col=2)\n";
				if($n == 1)
				{
					
					print R "plot.roc($roc,col=brewer.pal(12,\"Set3\")[$n])\n leg[$n]<-paste(\"$vs_group\", \"AUC=\",round($roc\$ci[2],2),\"%\")\nleg_col[$n]<-brewer.pal(12,\"Set3\")[$n]\n";
						
				}elsif($n>1)
				{
					print R "plot.roc($roc,col=brewer.pal(12,\"Set3\")[$n],add=T)\n leg[$n]<-paste(\"$vs_group\", \"AUC=\",round($roc\$ci[2],2),\"%\")\nleg_col[$n]<-brewer.pal(12,\"Set3\")[$n]\n";
				}
				
				print "realclass\t$realclass\n";
				print "preprob_\t $preprob\n";
			}
#print "b\t$n\n";			
			print R "legend(\"bottomright\",leg,col=leg_col,inset=0.05,lty=1)\n";
			print R "dev.off()\n";
			 print R " outpng<-\"trainset_group_max_roc.png\"\nsystem(paste(\"convert -density 200 \",outpdf,outpng),intern=F)\n";
            close R;
			$m++;
			
	}
}
open SH, "> $opt{indir}/all_rf_auc.sh";
	for my $rank (`ls $opt{indir}`)
	{
		chomp $rank;
		if(-d "$opt{indir}/$rank")
		{
			if($m==1)
			{
			print SH "$R -f $opt{indir}/$rank/vs_group.R > log\n";
			}elsif($m>1)
			{
			print SH "$R -f $opt{indir}/$rank/vs_group.R > log \n\n";
			}
		}
	}
close SH;
 if($opt{notrun})
{ exit ;}
else{
`sh $opt{indir}/all_rf_auc.sh > all_rf_auc.log`;
}
