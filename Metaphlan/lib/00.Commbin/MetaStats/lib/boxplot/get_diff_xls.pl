#!usr/bin/perl -w
use strict;

(@ARGV==4)||die "Usage: perl $0 <group>  <diif_qsig.xls> <vslist> <outdir>\n";

my ($group,$diff,$vs,$outdir)=@ARGV;
(-s $outdir) || `mkdir -p $outdir`;
my %group;
open IN,$group||die$!;
while(<IN>){
    chomp;
    my @tmp=split /\s+/;
    $group{$tmp[0]}=$tmp[1];
 }
close IN;

open(OR,"$vs");
my@vsgroups;
while (<OR>) {
    chomp;
    my@or=split/\s+/;
    foreach my $or(@or){
        push @vsgroups,$or if(!grep{$or eq $_} @vsgroups);
    }
}
close OR;


my %tax2re;
my @tax;
open IN,$diff||die$!;
my $line1=<IN>;
chomp $line1;
my @sample=split /\t/,$line1;
while(<IN>){
    chomp;
    my @tmp=split /\t/;
    push @tax,$tmp[0];
    my @relative=@tmp[1..$#tmp];
   # $tax2max{$tmp[0]}=(sort {$a<=>$b} @relative)[-1];
    for (my $i=1;$i<=$#sample;$i++){
    $tax2re{$tmp[0]}{$sample[$i]}=$tmp[$i];
 }
}
close IN;

#my @tax = sort{$tax2max{$b}<=>$tax2max{$a}} keys %tax2max;

#my @toptax;
#if ($#tax>=$top){
#  @toptax=@tax[0..$top-1];
#}else{
#  @toptax=@tax;
#}

foreach my $tax (@tax){
    my $taxname=$tax;
    $taxname=~s/\s+/_/g;
    $taxname=~s/;/_/g;
    open OUT,">$outdir/$taxname.xls" || die $!;
    print OUT "SampleId\tAbundance\tgroup\n";
    foreach my $sample (sort {$a cmp $b} keys %{$tax2re{$tax}}){
        print OUT "$sample\t$tax2re{$tax}{$sample}\t$group{$sample}\n" if(grep {$group{$sample} eq $_} @vsgroups );
  }
close OUT;
}
