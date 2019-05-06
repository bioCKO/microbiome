#!usr/bin/perl -w	
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);

=pod
Description: PCoA script for Meta  edit by zhangjing 2016-11-07
Usage:perl $0 indir group  outdir prefix 
example:perl $0 Relative/ group.xls  PCoA/ Unigenes.relative 
=cut

my ($indir,$group,$outdir,$prefix)=@ARGV;
$indir=abs_path($indir);
$group=abs_path($group);
$outdir ||="./";
$outdir=abs_path($outdir);
(-d $outdir)||`mkdir -p $outdir`;
open IN,"$group";
open OUT,">$outdir/../group.xls";
print OUT "sample\tgroup\n";
while (<IN>){
	print OUT $_;
}
close IN;
close OUT;
my %hash=(p=>"phylum",c=>"class",o=>"order",f=>"family",g=>"genus",s=>"species",k=>"kingdom");
my @sign;
for my $m(`ls $indir`){
	chomp $m;
	if($m=~/xls/){
		push @sign,(split /\./,$m)[2];
	}
}
for my $i(0..$#sign){
	if (exists $hash{$sign[$i]}){
		(-d "$outdir/$hash{$sign[$i]}")||`mkdir $outdir/$hash{$sign[$i]}`;
		`perl $Bin/../Beta_diversity_index.pl $indir/$prefix.$sign[$i].xls --index BCD --rank --matrix $outdir/$hash{$sign[$i]}/BCD.$sign[$i].mat`;
		open IN,"$outdir/$hash{$sign[$i]}/BCD.$sign[$i].mat";
		open OUT,">$outdir/$hash{$sign[$i]}/BCD.xls";
        my @arr=split /\t/,<IN>;
		my $first=shift @arr;
		print OUT "\t",join("\t",@arr);
		while (<IN>){
			print OUT $_;
		}
        close IN;
		close OUT;
#	`perl lib/04.Diversity/lib/PCoAclust.pl $outdir/$hash{$sign[$i]}/BCD.xls $outdir/../group.xls $outdir/$hash{$sign[$i]}/`;
	   `perl $Bin/PCoAclust.pl $outdir/$hash{$sign[$i]}/BCD.xls $outdir/../group.xls  $outdir/$hash{$sign[$i]}/`;
	   }else{
	        (-d "$outdir/$sign[$i]") ||	(`mkdir "$outdir/$sign[$i]"`);
	   `perl $Bin/../Beta_diversity_index.pl $indir/$prefix.$sign[$i].xls --index BCD --rank --matrix $outdir/$sign[$i]/BCD.$sign[$i].mat`;
	    open IN,"$outdir/$sign[$i]/BCD.$sign[$i].mat";
	    open OUT,">$outdir/$sign[$i]/BCD.xls";
	    my @arr=split /\t/,<IN>;
	    my $first=shift @arr;
	    print OUT "\t",join("\t",@arr);
	    while (<IN>){
		   print OUT $_;
	    }
	    close IN;
	    close OUT;
#	   `perl lib/04.Diversity/lib/PCoAclust.pl $outdir/$sign[$i]/BCD.xls $outdir/../group.xls  $outdir/$sign[$i]/`;
	   `perl $Bin/PCoAclust.pl $outdir/$sign[$i]/BCD.xls $outdir/../group.xls  $outdir/$sign[$i]/`;
       }
}
