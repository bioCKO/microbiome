#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd qw(abs_path);
use FindBin qw($Bin);
my %opt = (outdir => ".",prefix => "diff_heatmap");
GetOptions(\%opt,"lda:s","table:s","mf:s","prefix:s","vs:s","outdir:s","top:i","group_col:s");
($opt{lda} && -s $opt{lda}) && ($opt{table} && -s $opt{table}) && ($opt{mf} && -s $opt{mf}) && $opt{vs} || die "Usage:perl $0 --lda input.res --table input.table --mf all.mf --vs vs_group[group1,group2]
        --lda <file>        input .res file from LDA analysis
        --table <file>      input tax or function relative table
        --mf <file>         input all.mf group file
        --prefix <str>      set the output file prefix default='diff_heatmap'
        --vs <str>          set the VS groups ,separation by comma
        --top <num>         set top num biomarkers to plot heatmap,default plot all biomarkers
        --group_col <str>   set group label colour of heatmap\n";
my($res,$infile,$mf) = ($opt{lda},$opt{table},$opt{mf});
for($res,$infile,$mf,$opt{outdir}){
    $_ =abs_path($_);
}
my $heatmap = "perl $Bin/LDA_heatmap.pl";
$opt{group_col} && ($heatmap .= " --group_col $opt{group_col}");
my (%tax,@vs_sample);
for(`less $res`){
    chomp;
    my @line = split /\t+/;
    @line == 5 && ($tax{$line[0]}=$line[2]);
}
my @vs_group=split /,/,$opt{vs};
open OUT,">$opt{outdir}/group.list";
for my $temp(`less $mf`){
    chomp $temp;
    my @line =($temp =~/\t/) ? (split /\t/,$temp) : (split /\s+/,$temp);
    foreach(@vs_group){
        if($line[1] eq $_){
            print OUT $temp,"\n";
            push @vs_sample,$line[0];
        }
    }
}
close OUT;
my %tax2mat;
open IN,"<$infile";
my $head=<IN>;
chomp $head;
my @sample=split/\t/,$head;
while(my $line=<IN>){
    chomp $line;
    my @temp=split /\t/,$line;
    next if($temp[0] =~ /Others/);
    my $id;
    my @id= (split /;/,$temp[0]);
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
    for my $i(1..$#temp-1){
        $tax2mat{$id}{$sample[$i]}=$temp[$i];
    }
}
close IN;

open OUT,">$opt{outdir}/$opt{prefix}\.xls";
print OUT "Class\t",join("\t",@vs_sample),"\n";
for my $key(keys %tax2mat){
    if(exists $tax{$key}){
        print OUT "$key\t";
        for my $id(@vs_sample){
            print OUT "$tax2mat{$key}->{$id}\t";
        }
        print OUT "level__$key\n";
    }
}
close OUT;

###plot heatmap####
my $heat = "$opt{outdir}/$opt{prefix}\.xls";
my $group = "$opt{outdir}/group.list";
my @colour = ('"#EE0000"','"#008B00"','"#0000EE"','"#CD00CD"','"#00CDCD"','"#CDCD00"','"#000000"','"#F5F5F5"');
my (%count,@group,@uniq_group,$col);
for(`less $group`){
    chomp;
    my @line = (/\t/) ? split /\t/ : split;
    push @group,$line[1];
}
@uniq_group=grep { ++$count{$_} < 2 } @group;
my %group_col;
my $i=0;
for(sort{$a cmp $b} @uniq_group){
    $group_col{$_} = $colour[$i];
    $i++;
}
foreach(@uniq_group){
    $col .= "$group_col{$_},";
}
$col = substr($col,0,-1);
my $limt=`less $heat | wc -l`;
$opt{top} ||= $limt;
if($limt >3){
    system"$heatmap $heat --level level__ --group $group --group_col $col --top $opt{top}";
}else{
    print "The biomarkers are less of 3!!\n";
}
