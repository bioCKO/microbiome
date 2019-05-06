#!usr/bin/perl -w	
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);

my ($indir,$group,$outdir,$prefix)=@ARGV;
$indir=abs_path($indir);
$group=abs_path($group);
$outdir ||="./";
(-d $outdir)||`mkdir -p $outdir`;
open IN,"$group";
open OUT,">$outdir/group.xls";
print OUT "sample\tgroup\n";
while (<IN>){
        print OUT $_;
}
close IN;
close OUT;
my @sign = qw(phylum class order family genus species);
my @sign2=qw(p c o f g s);
for my $i(0..$#sign){
	(-d "$outdir/$sign[$i]") || mkdir"$outdir/$sign[$i]";
	`perl $Bin/../Beta_diversity_index.pl $indir/$prefix.$sign2[$i].xls --index --rank --matrix $outdir/$sign[$i]/BCD.$sign2[$i].mat`;
    open IN,"$outdir/$sign[$i]/BCD.$sign2[$i].mat";
    open OUT,">$outdir/$sign[$i]/BCD.$sign2[$i].xls";
    my @arr=split /\t/,<IN>;
    my $first=shift @arr;
    print OUT "\t",join("\t",@arr);
    while(<IN>){
        print OUT $_;
    }
    close IN;
    close OUT;
	`perl lib/04.Diversity/lib/PCoAclust.pl $outdir/$sign[$i]/BCD.$sign2[$i].xls $outdir/group.xls  $outdir/$sign[$i]/`;
}
