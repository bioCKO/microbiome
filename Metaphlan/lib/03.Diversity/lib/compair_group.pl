#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt=(conf=>0.95);
GetOptions(\%opt,"wilcox","paired","conf:f");
@ARGV==2 || die"usage: perl Combine_table.pl <in.table> <in.group> > out.combine.table.xls
    --wilcox            to do wilcox.test, default use t.test
    --paired            input to be paired data
    --conf <flo>        config leveal, default=0.95\n";
for (@ARGV){
    (-s $_) || die$!;
}
my ($intable,$group) = @ARGV;
my %uniq_group;
my %sample_group;
my @group;
my $num = 0;
for (`less $group`){
    my @l = split;#sample group_anme
    $sample_group{$l[0]} = ($uniq_group{$l[1]}||=++$num);
}
open IN,$intable || die$!;
chomp(my $head = <IN>);
my @head = ($head=~/\t/) ? split/\t/,$head : split/\s+/,$head;
for my $i(0 .. $#head){
    my $group_num;
    ($group_num = $sample_group{$head[$i]} || 0) && (push @{$group[$group_num-1]},$i);
}
my @group_name = sort {$uniq_group{$a}<=>$uniq_group{$b}} keys %uniq_group;
my @pair_name = map {("avg($_)","sd($_)")} @group_name;
for my $i(0..$#group_name-1){
    for my $j($i+1 .. $#group_name){
        push @pair_name,"$group_name[$i]_VS_$group_name[$j]";
    }
}
print join("\t",$head[0],@pair_name),"\n";
while(<IN>){
    chomp;
    my @l = /\t/ ? split /\t/ : split;
    my @out = map avg_sd(@l[@{$group[$_]}]), (0 .. $#group);
    for my $i(0 .. $#group-1){
        for my $j($i+1 .. $#group){
            push @out,T_test([@l[@{$group[$i]}]],[@l[@{$group[$j]}]],$opt{conf},$opt{paired},$opt{wilcox});
        }
    }
    print join("\t",$l[0],@out),"\n";
}
close IN;
#====================================================================================================
sub avg_sd{
    my ($avg,$sd);
    my $num = @_;
    for(@_){
        $avg += $_;
        $sd += $_**2;
    }
    $avg /= $num;
    $sd = sprintf("%.6f",sqrt($sd/$num - $avg**2));
    $avg = sprintf("%.6f",$avg);
    return($avg,$sd);
}
sub T_test{
    my ($arr1,$arr2,$conf,$pair,$wilcox) = @_;
    my $Rscript = "System/R-2.15.3/bin/Rscript";
    my $pair_Ture = $pair ? "TRUE" : "FALSE";
    my $t = $wilcox ? 'wilcox' : 't';
    $conf ||= 0.95;
    my $sign_lev = (1 - $conf) / 2;
    my $c1 = join(",",@$arr1);
    my $c2 = join(",",@$arr2);
    my $Rtest = "$Rscript -e 'x<-c($c1);y<-c($c2); var<-var.test(x,y);" .
                "if (var\$p.value<$sign_lev) pv<-$t.test(x,y,paired=$pair_Ture,var.equal=FALSE,conf.level=$conf) " .
                "else pv<-$t.test(x,y,paired=$pair_Ture,var.equal=TRUE,conf.level=$conf);pv\$p.value;' 2>/dev/null";
    my $pvalue = (split/\s+/,`$Rtest`)[1];
    defined $pvalue ? $pvalue : 1;
}
