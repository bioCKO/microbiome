#!/usr/bin/perl -w
use strict;
use FindBin qw/$Bin/;
use Cwd qw/abs_path/;
use Getopt::Long;
use lib "$Bin/../../00.Commbin/";
use PATHWAY;
my $cfg = "$Bin/../../../bin/Pathway_cfg.txt";
(-s $cfg) || die"error: can't find config file: $cfg, $!\n";
my ($R0,$convert)=get_pathway($cfg,[qw(Rscript CONVERT)]);

unless (@ARGV >= 2){
    die"Name: anosim_analysis.pl
        Usage: perl anosim_analysis.pl <otu_table.even.txt> <input_group.list> [Rscript.R] [anosim_group]
        Author:Huaibo Sun;  sunhuaibo\@novogene.cn
        Versoin:1.0     2014.06.11\n" 
}
my ($otu,$group,$Rscript,$anosim_group) = @ARGV;
$Rscript ||= 'Rscript.R';
$anosim_group ||= 'anosim_group';
my $dir_otu = abs_path($otu);
my $dir_anosim_group = abs_path($anosim_group);
open IN,$group || die "Can't open file:$group";
open OUT,">$Rscript" || die $!;
###########################################################################################
#make anosim analysis Rscript
my %hash;
print OUT "library(vegan)\n",
      "library(permute)\n",
      "library(lattice)\n",
      "data=read.table(\"anosim_table.txt\",header=T)\n",
      "data=t(data)\n";
my %group_num;
while(<IN>){
    chomp;
    my @id = split;
    for(@id){$_ = "\"$_\"";}
    push @{$hash{$id[1]}},$id[0];
    $group_num{$id[1]}++;
}
open OUT2,">$anosim_group" || die "$!";
my @key = keys %hash;
for my $i(0..$#key){
    for my $j(0..$#key){
        ($i <= $j) && next;
        if ($group_num{$key[$i]} && $group_num{$key[$j]}){
            (($group_num{$key[$i]} < 3) || ($group_num{$key[$j]} < 3 )) && next;  #filter pair-group if any group number less than 3
        }
        my @group;
        push @group,( ($key[$i]) x @{$hash{$key[$i]}});
        push @group,( ($key[$j]) x @{$hash{$key[$j]}});
        print OUT "anosim_table=data[c(",join(",",@{$hash{$key[$i]}},@{$hash{$key[$j]}}),"),]\n",
              "group=c(",join(",",@group),")\n",
              "plot_id = paste($key[$i],\"-\",$key[$j],\".pdf\",sep=\"\")\n",
              "distance = vegdist(anosim_table)\n",
              "stat.anosim=anosim(distance,group)\n",
              "summary(stat.anosim)\n",
              "pdf(plot_id)\n",
              "plot(stat.anosim,col=c('#00CC00','#FF6666','#439dee'))\n",
              "dev.off()\n\n";
               
        print OUT2 "$key[$i]-$key[$j]\n";
    }
}
###########################################################################################
close IN;
close OUT;
close OUT2;
system "perl $Bin/get_table2anosim.pl $otu anosim_table.txt
$R0 $Rscript > anosim_significance.txt
perl $Bin/capture_anosim_val.pl anosim_significance.txt $anosim_group stat_anosim.txt";
for(`ls *.pdf`){
    chomp;
    my $id =$1 if ($_ =~ /^(\S+)\.pdf$/);
   system "$convert $_ $id\.png";
}

