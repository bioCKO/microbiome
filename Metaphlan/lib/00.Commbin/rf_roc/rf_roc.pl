#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use lib "$Bin/../";
my $lib = "$Bin/../";
use PATHWAY;
my %opt = (outdir=>".",prefix=>"rf","n"=>"15");
    GetOptions(\%opt,"indir:s","outdir:s","shdir:s","rf:s","scale:s","step:s","headvar:s","group:s","prefix:s","notrun","rank:s","n:s");
	##add vs lefse
my($convert,$R,$R_script) = 
get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(CONVERT R7 R5)]);
$opt{indir} || die "Usage perl $0 --indir <dir> --group group.list --rf rf.list --rank 
    *--indir <dir>          input relative table folder,like MicroNR_stat/Relative/heatmap/
    *--group  <file >          input file for all.mf
    *--rf <file>      input vs group list
    *--rank                 set analysis rank,such as f,g,s,ko,level1,og,aro,separation by comma 
    *--outdir 
    --n              the Threshold ,the sample's number of each group ,default 15\n";
#my $R_script="/PUBLIC/software/public/System/R-3.2.1/bin/Rscript";
my $rf_r="$Bin/rf.main_modify.cagv2.R";
my $get_lefse="perl $Bin/get_lefse.pl";
my $tran="perl $Bin/Tran_table.pl";
 my $vs_roc="perl $Bin/plot_vs_group_auc.pl";

######$opt{indir},$opt{outdir},$opt{shdir},$opt{rf},$opt{group},$opt{prefix}

my ($indir,$group)=($opt{indir},$opt{group});
my @rank = split /,/,$opt{rank};
print "rank @rank\n";
my %all_rank=("k"=>"kingdom","p"=>"phylum","c"=>"class","o"=>"order","f"=>"family","g"=>"genus","s"=>"species","ko"=>"ko","level1"=>"level1","level2"=>"level2","level3"=>"level3","og"=>"og","ARO"=>"ARO");
my %vs_group;
foreach($opt{indir},$opt{group},$opt{rf},$opt{outdir}){
    $_ =abs_path($_);
}
my %hash;
foreach (`less $opt{group}`)
{
        chomp ;
        my @line= (/\t/) ? (split /\t/) : split/\s+/;
        if(! $hash{$line[-1]})
        {
            $hash{$line[-1]}=1;
        }elsif($hash{$line[-1]})
         {
             $hash{$line[-1]}++;
         }
                        
}
#print Dumper(\%hash);
if ($opt{rf} && -s $opt{rf})
{
	for (`less $opt{rf}`)
	{
		chomp;
		my @line= (/\t/) ? (split /\t/) : split/\s+/;
		my $vs=join ",",@line;
		$vs_group{$vs}=scalar @line;
	}
}
(-d "$opt{outdir}") || `mkdir -p $opt{outdir}`;
open ALLSH,"> $opt{outdir}/all_rf.sh";
#print "$opt{outdir}\n";
for my $rank(@rank)
{
	my $mat;
	if($rank =~/ARO/)
	{
		$mat = "$opt{indir}/stat.$rank.relative.D.xls";
	}else{
		 $mat = "$opt{indir}/Unigenes.relative.$rank\.xls";
	}
	if ($opt{rf} && -s $opt{rf}) 
	{
		my $i=0;
        LABEL:for my $vs (sort {$vs_group{$a} <=> $vs_group{$b}} keys %vs_group) 
		{
			my @vs_group=split /,/,$vs;
			my $vs_group_filename;
            #print "@vs_group\n";
			for (@vs_group)
			{
                $vs_group_filename.=$_."_vs_";
#    print "$hash{$_}\n";
                if($hash{$_}<$opt{n})
            {
                    warn "the sample's number of $_ is less than $opt{n} \n";next LABEL;
            }

            }
            substr($vs_group_filename,-4,4)="";
            $i++;
			my $rf_outdir="$opt{outdir}/$all_rank{$rank}/$i\_$vs_group_filename";
			(-s "$rf_outdir") ||`mkdir -p $rf_outdir`; 
#            print "$rf_r\t$rf_outdir/$vs_group_filename\_temp_tran.xls\t $rf_outdir \n";			
#print "$opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.sh\n";
			open(SH,">$opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.sh");
			print SH "$get_lefse $mat $opt{group} $rf_outdir/$vs_group_filename\_temp.xls --vs $vs\n";
            print SH "$tran $rf_outdir/$vs_group_filename\_temp.xls >   $rf_outdir/$vs_group_filename\_temp_tran.xls\n";
            print SH "$R_script $rf_r --infile  $rf_outdir/$vs_group_filename\_temp_tran.xls --outdir $rf_outdir \n";
           # "$convert -density 300 $vs_group_filename\_ROC.pdf $vs_group_filename\_ROC.png\n";
		    
			print SH "\n";
			close SH;
			if ($i == scalar keys %vs_group)
            {
                print ALLSH "sh $opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.sh >& $opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.log \n";
            }else
            {
                print ALLSH "sh $opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.sh >& $opt{outdir}/$all_rank{$rank}/$opt{prefix}\_$i\_ROC.log & \n";
            }

		
		}
 
	}
 }
 print ALLSH "wait\n $vs_roc --indir $opt{outdir}\n";
close ALLSH;
 if($opt{notrun})
{ exit ;}
else{`sh $opt{outdir}/all_rf.sh`;}
