#!usr/bin/perl -w
use strict;
use File::Basename;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd qw(abs_path);

my %opt=(top=>12,outdir=>'./');
GetOptions(\%opt,"colour:s","dir:s","qsig:s","top:n","mf:s","outdir:s");

($opt{dir} && -s $opt{dir} && $opt{qsig} && -s $opt{qsig} && $opt{mf} && -s $opt{mf})||die "Usage: perl $0 
    *-dir       [str]    input directory that contain particles xls information
    *-qsig      [str]    input the total qsig file 
    *-mf        [str]    input group information for group order
    --outdir    [str]    output directory,default=./
    --top       [num]    input combine numbers, default=12
    --colour    [str]    choose colour for groups,default=#cb4154,#1dacd6,#66ff00(accord to mf)\n";

## get software's path
use lib "$Bin/../../../";
my $lib = "$Bin/../../../..";
use PATHWAY;
(-s "$Bin/../../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../../bin, $!\n";
my ($combine,$rscript,$svg2xxx,$convert) = get_pathway("$Bin/../../../../../bin/Pathway_cfg.txt",[qw(COMB_FIG Rscript SVG2XXX CONVERT)],$Bin,$lib);

#--------------------------------------------------------------------------------------------------------
#set options
my @color;
if($opt{colour}){
  @color = split /\,/, $opt{colour};
  for(0..$#color){
    $color[$_] = "\"".$color[$_]."\"";
  }
}else{
  @color = ('"#cb4154"','"#1dacd6"','"#66ff00"','"#bf94e4"','"#c32148"','"#ff007f"','"#08e8de"','"#d19fe8"','"#f4bbff"','"#ff55a3"','"#fb607f"','"#004225"','"#cd7f32"','"#a52a2a"','"#ffc1cc"','"#e7feff"','"#f0dc82"','"#480607"','"#800020"','"#deb887"','"#cc5500"','"#e97451"','"#8a3324"','"#bd33a4"','"#702963"','"#cc0000"','"#006a4e"','"#873260"','"#0070ff"','"#b5a642"');
}
$opt{mf}=abs_path($opt{mf});
$opt{qsig}=abs_path($opt{qsig});
$opt{dir}=abs_path($opt{dir});
$opt{outdir}=abs_path($opt{outdir});
#--------------------------------------------------------------------------------------------------------
#main script
my @infile=`ls $opt{dir}/*.xls`;
my %groups_max;
my %max2id;
foreach my $file (@infile){
    chomp$file;
    open(OR,"$file");
    my $id=$1 if($file=~/.*\/(.*)\.xls$/);
    <OR>;
    my %group_abun;
    my @groups;
    while (<OR>) {
        chomp;
        my@or=split/\t/;
        push @{$group_abun{$or[2]}},$or[1];
        push @groups,$or[2] if!grep{$or[2] eq $_} @groups;
    }
    my@id_max;
    foreach my $group(@groups){
        my $max = (sort{$a <=> $b} @{$group_abun{$group}})[-1];
        if($max){$groups_max{$id}{$group}=$max;}
        else{$groups_max{$id}{$group}=0;}
        push @id_max,$max;
    }
    my $id_max=(sort{$a <=> $b} @id_max)[-1];
    push @{$max2id{$id_max}},$id;
    close OR;
}

open OR,$opt{qsig};
my $vs=<OR>;
chomp$vs;
my @qsig_vs_groups=split/\s+/,$vs;
shift@qsig_vs_groups;
my @uniq_groups;
foreach my $vs (@qsig_vs_groups){
    my@groups_mid=split/-vs-/,$vs;
    foreach my $group (@groups_mid){
        push @uniq_groups,$group if !grep{$group eq $_} @uniq_groups;
    }
}
open(MF,"$opt{mf}");
my %groups2x;
my %x2group;
my @gname;
my $x=1;
my $color_i=0;
my %group_color;
while (<MF>) {
    chomp;
    my@or=split/\s+/;
    if (!$group_color{$or[1]}) {
        if ($color[$color_i]) {
            $group_color{$or[1]}=$color[$color_i];
        }else{$group_color{$or[1]}='black';}
        $color_i++;
    }
    next if ($groups2x{$or[1]} || !grep{$or[1]  eq $_} @uniq_groups );
    $groups2x{$or[1]}=$x;
    push @gname,"\"$or[1]\"";
    $x2group{$x}=$or[1];
    $x++;
}
close MF;

my%groups2sig;
(-s "$opt{outdir}/vs")||`mkdir -p $opt{outdir}/vs`;
(-s "$opt{outdir}/R")||`mkdir -p $opt{outdir}/R`;
(-s "$opt{outdir}/figures")||`mkdir -p $opt{outdir}/figures`;
my $gname=join ",",@gname;
my $color_cut;
foreach my $groupname(@gname){
    $groupname=~s/^\"//;
    $groupname=~s/\"$//;
    $color_cut.="$group_color{$groupname},";
}
$color_cut = substr($color_cut,0,-1);
while (<OR>) {
    chomp;
    my@or=split/\t/;
    my$id=shift@or;
    $id=~s/\s+/_/g;
    $id=~s/;/_/g;
    open OUT,">$opt{outdir}/vs/$id.vs.txt" || die $!;
    print OUT "x\txend\ty\tyend\tlabel\n";
    my %check_max;
    for (my $i = 0; $i < $#or+1; $i++) {
        next if $or[$i] !~ /\*/;
        my $label=$or[$i];
        my@groups=split/-vs-/,$qsig_vs_groups[$i];
        my@max;
        my($stepa,$stepb);
        if($groups2x{$groups[0]} >= $groups2x{$groups[1]}){$stepa=$groups2x{$groups[1]};$stepb=$groups2x{$groups[0]};}
        else{$stepa=$groups2x{$groups[0]};$stepb=$groups2x{$groups[1]};}
        for my$j($stepa..$stepb){
            push @max,$groups_max{$id}{$x2group{$j}};
        }
        @max ? 1 : ($max[0]=0);
        @max=sort {$a <=> $b} @max;
        my $max;
        $max[-1] ?($max=$max[-1]) : ($max=0);
        $check_max{$max}++;
        my $large;
        if($max < 0.05){ $large=0.2;}
        elsif($max < 0.1){ $large=0.1;}
        elsif($max < 0.5){$large=0.05;}
        elsif($max > 0.7){$large=0.05;}
        else{ $large=0.007;}
        $max += $max*$large*$check_max{$max};
        print OUT "$groups2x{$groups[0]}\t$groups2x{$groups[1]}\t$max\t$max\t$label\n";
    }
    close OUT;

    open OUT,">$opt{outdir}/R/$id.R";
    print OUT "library(ggplot2)
    vs <- read.table(\"$opt{outdir}/vs/$id.vs.txt\",header=T,sep=\"\\t\")
    file <- read.table(\"$opt{dir}/$id.xls\",header=T,sep=\"\\t\") 
    ggplot(data=file,aes(group,Abundance)) +
    geom_boxplot(fill=c($color_cut)) +
    xlim($gname)+
    labs(title=\"$id\")+
    theme(legend.title=element_blank(),axis.text.x=element_text(colour = \"black\"), axis.text.y=element_text(colour = \"black\"))+
    geom_segment(data = vs, aes(x = x, xend = xend, y = y, yend = yend),lwd=1.2) +
    geom_text(data = vs, aes(x = (x + xend)\/2, y = y + y*0.001, label = label),size=8)
    ggsave(\"$opt{outdir}/figures/$id.pdf\")";
    close OUT;
    system "$rscript '$opt{outdir}/R/$id.R'";
    system "$convert -density 200  '$opt{outdir}/figures/$id.pdf' '$opt{outdir}/figures/$id.png'";
}
close OR;

my $top_num;
my $toppics;
BLOCK:foreach my $key (sort{$b <=> $a} keys %max2id){
    foreach my $id(@{$max2id{$key}}){
        $toppics .= "  '$opt{outdir}/figures/$id.png' ";
        $top_num++;
        last BLOCK if ($top_num >= $opt{top});
    }
}
system  "$combine $toppics >$opt{outdir}/top.$opt{top}.svg";
system "$svg2xxx -t pdf $opt{outdir}/top.$opt{top}.svg";
system "$convert -density 300 $opt{outdir}/top.$opt{top}.pdf $opt{outdir}/top.$opt{top}.png";
