#! /usr/bin/perl -w
# Function: transfer input_table to the file lefse can accepted
# Date: 2016-05-03, input is Relative tax or function mats folder
# Contact: yelei@novogene.cn

use strict;
use Getopt::Long;
my %opt;
GetOptions(\%opt,"vs:s");
(@ARGV >= 3) && ($opt{vs}) || 
	die "usage: perl $0 <input relative mats> <input:all.mf> <output> --vs vs.list [--option]
    --vs [str]          input vs.list,format:group1,group2\n";
#===============================================Main=====================================================================================
my($relative,$mf,$output)=@ARGV;
my (@vs_group,@vs_sample,%mf);
if($opt{vs}){
    @vs_group = split /,/,$opt{vs};
}

open(MF,"<$mf");
while (my $or=<MF>) {
	chomp $or;
	my @or=split(/\s+/,$or);
	$mf{$or[0]}=$or[1];
	if(@vs_group){
	    for my $j(@vs_group){
			if ($or[1] eq $j){
				push @vs_sample,$or[0];
            }
        }
    }
}
close MF;
my %tax2mat;
open IN,"<$relative";
my $head=<IN>;
chomp $head;
my @samples=split /\t/,$head;
LOOP:while(my $or=<IN>){
    chomp $or;
    my @or=split /\t/,$or;
    next LOOP if($or[0] =~ /Others/);
    my $id;
    my @id=(split /;/,$or[0]);
    if($id[-1] =~ /[\[\]]/g){
        $id = $id[0]."_".$id[-1];
        $id =~ s/[\[\]]//g;
    }else{
        $id=$id[-1];
    }
    $id=~s/^level__//g;
    $id=~s/^\s+//;
    foreach('\$','\@','\%','\^','\&','\"','\'','\.'){
        $id=~s/$_//g;
    }
    foreach('\(','\)','\-','\+','\=','\{','\}','\,','\:','\?','\<','\>'){
        $id=~s/$_/_/g;
    }
    $id=~s/\s+/_/g;
    $id=~s/\_$//;
    $id=~s/[kpcofgs]__//g;
    for (my $i = 1;$i < $#or;$i++){
        $tax2mat{$id}{$samples[$i]}=$or[$i];
    }
}
close IN;
open OUT,">$output";
print OUT "Class";
for (my $i = 0;$i <= $#vs_sample;$i++){
    print OUT "\t$mf{$vs_sample[$i]}";
}
print OUT "\n";
    foreach my $tax(sort{$a cmp $b} keys %tax2mat){
        my $sum_abundance=0;
        for (my $i = 0;$i <= $#vs_sample;$i++){
            $sum_abundance += $tax2mat{$tax}{$vs_sample[$i]};
        }
        next if($sum_abundance==0);
        print  OUT "$tax";
        for (my $i = 0;$i <= $#vs_sample;$i++){
            print OUT "\t$tax2mat{$tax}{$vs_sample[$i]}";
        }
        print OUT "\n";
}
close OUT;
