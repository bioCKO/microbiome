#!/usr/bin/perl -w
use strict;
use File::Basename;
use FindBin qw($Bin);
use Getopt::Long;
use Cwd qw(abs_path);

my %opt=(top=>20,outdir=>'.');
GetOptions(\%opt,"dir:s","colour:s","top:n","outdir:s","vs:s","sep");
($opt{dir} && -s $opt{dir} && $opt{vs} && -s $opt{vs})||die "Usage: perl $0
    *-dir       [str]    input directory that contain particles xls information
    *--vs       [str]    input the vs.list
    --outdir    [str]    output directory,default=./
    --top       [num]    combine numbers of boxplot, default=12
    --colour    [str]    choose colour for groups,default='#439dee','#FF6666'
    --sep                if only have 2 group,whether to plot increase and decrease tax separately,default not to set it\n";

use lib "$Bin/../../../";
my $lib = "$Bin/../../../..";
use PATHWAY;
(-s "$Bin/../../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../../bin, $!\n";
my ($rscript,$svg2xxx,$convert,$combine_fig) = get_pathway("$Bin/../../../../../bin/Pathway_cfg.txt",[qw(Rscript SVG2XXX CONVERT COMB_FIG)],$Bin,$lib);

my @color;
if($opt{colour}){
    @color = split /\,/,$opt{colour};
    for(0..$#color){
        $color[$_] = "\"".$color[$_]."\"";
    }
}else{
    @color = ('"#439dee"','"#FF6666"','"#00CC00"','"#ee439d"','"#cb4154"','"#1dacd6"','"#66ff00"','"#bf94e4"','"#c32148"','"#ff007f"','"#08e8de"','"#d19fe8"');
}
my $colors;
foreach my $col (@color){
    $colors .= "$col,";
}
$colors = substr($colors,0,-1);

$opt{dir}=abs_path($opt{dir});
$opt{outdir}=abs_path($opt{outdir});
$opt{vs} = abs_path($opt{vs});

#--------------------------------------------------------------------------------------------------------------------------------
##generate plot file

my @vs;
for(`less $opt{vs}`){
    chomp;
    my @l = (/\t/) ? split /\t/ : split;
    my $l = join("-vs-",@l);
    push @vs,$l;
}

my @sort;
for(`less $opt{outdir}/sorted.list`){
    chomp;
    @sort=split /\,/;
}
(-s "$opt{outdir}/combine_box") || system "mkdir -p $opt{outdir}/combine_box";
my ($limit,$limit1,$limit2);
if ($opt{sep} && @vs==1){
    my (%decrease_tax,%increase_tax,@decrease_tax,@increase_tax);
    my $infile = "$opt{dir}/$vs[0].qsig.xls";
    open IN,$infile;
    <IN>;
    while(<IN>){
        my @line=(/\t/) ? split /\t/ : split;
        $line[0] =~ /^Others/ && next;
        $line[0] =~ s/;/_/;
        $line[0] =~ s/\s+/_/;
        if ($line[1] > $line[4]){
            $decrease_tax{$line[0]}=$line[1];
        }else{
            $increase_tax{$line[0]}=$line[4];
        }
    }
    close IN;
    @decrease_tax = sort{$decrease_tax{$b} <=> $decrease_tax{$a}} keys %decrease_tax;
    @increase_tax = sort{$increase_tax{$b} <=> $increase_tax{$a}} keys %increase_tax;
    $opt{top} ||= 20;
    my $top = $opt{top};
    if(@decrease_tax){
        $limit1=0;
        open OUT1,">$opt{outdir}/combine_box/decrease.xls";
  BLOCK:foreach my $temp(@sort){
            $temp =~ /^Others/ && next;
            if(exists $decrease_tax{$temp}){
                $limit1++;
                open IN,"<$opt{dir}/boxplot/files/$temp\.xls";
                <IN>;
                my $tax1=(split /\_/,$temp)[-1];
                while(<IN>){
                    chomp;
                    my @head = (/\t/) ? split /\t/ : split;
                    print OUT1 "$head[2]\t$tax1\t$head[1]\n";
                }
                close IN;
                last BLOCK if ($limit1 >= $top);
            }
        }
        close OUT1;
    }
    if(@increase_tax){
        $limit2=0;
        open OUT2,">$opt{outdir}/combine_box/increase.xls";
  BLOCK:foreach my $temp(@sort){
            $temp =~ /^Others/ && next;
            if(exists $increase_tax{$temp}){
                $limit2++;
                open IN,"<$opt{dir}/boxplot/files/$temp\.xls";
                <IN>;
                my $tax=(split /\_/,$temp)[-1];
                while(<IN>){
                    chomp;
                    my @head = (/\t/) ? split /\t/ : split;
                    print OUT2 "$head[2]\t$tax\t$head[1]\n";
                }
                close IN;
                last BLOCK if ($limit2 >= $top);
            }
        }
        close OUT2;
    }
    $limit = ($limit1 > $limit2) ? $limit1 : $limit2;
}else{
    $opt{top} ||= 20;
    $limit=0;
    open OUT,">$opt{outdir}/combine_box/combined.xls";
BLOCK:foreach my $temp(@sort){
        $temp =~ /^Others/ && next;
        $limit++;
        my $tax = (split /\_\_/,$temp)[-1];
        open IN,"<$opt{dir}/boxplot/files/$temp\.xls";
        <IN>;
        while(<IN>){
            chomp;
            my @line = (/\t/) ? split /\t/ : split;
            print OUT "$line[2]\t$tax\t$line[1]\n";
        }
        close IN;
        last BLOCK if ($limit >= $opt{top});
      }
      close OUT;
}
my $width = ($limit <= 10) ? 10 :($limit <= 15) ? 15 : (0.8*$limit); 
#--------------------------------------------------------------------------------------------------------------------------------
## plot scripts

my @plot_file = `ls $opt{outdir}/combine_box/*.xls`;
my $outdir = "$opt{outdir}/combine_box";
for my $plot(@plot_file){
    chomp $plot;
    my $id = basename $plot;
    $id = $1 if ($id =~ /^(\S+)\.xls/);
    print $id,"\n";
    open OUT,">$outdir/$id.R";
    print OUT "library(ggplot2)
    data <- read.table(file=\"$plot\",header=F)
    colnames(data) <- c(\"group\",\"tax\",\"abun\")
    data <- data.frame(data)
    tax <- unique(data\$tax)
    tax <- factor(tax,levels=tax)
    level <- unique(data\$group)
    data\$group <- factor(data\$group,levels = level)
#    if(length(levels(tax)) < 10) width=10 else width = 0.5*length(levels(tax))
    pdf(file=\"$outdir/$id.pdf\",width=$width,height=4)
    p <- ggplot(data,aes(x=tax, y=abun,fill=group))
    p + scale_fill_manual(values=c($colors))+geom_boxplot(notchwidth=1,outlier.size=1)+theme(axis.text.x=element_text(color=\"black\",angle=45,size=10,vjust=1,hjust=1),axis.text.y=element_text(color=\"black\",size=10),axis.ticks=element_line(colour = \"black\"),panel.background = element_rect(fill=\"white\",colour=\"black\"),axis.line = element_line(colour = \"black\"),axis.title.y=element_text(colour=\"black\",size=12),legend.position=\"right\",legend.title=element_blank(),legend.text=element_text(size=12,colour=\"black\"),legend.key=element_blank())+xlim(levels(tax))+labs(x='',y='Relative abundance')
    dev.off()";
    close OUT;
    system "$rscript '$outdir/$id.R'";
    system "$convert -density 300 '$outdir/$id.pdf' '$outdir/$id.png'";
}
my @fig=`ls $outdir/*.png`;
my $fig;
if(@fig != 1){
    for my $temp(@fig){
        chomp $temp;
        $fig .= " '$temp' ";
    }
    system "cd $outdir
            $combine_fig $fig -wn 1 -ph 80 > combined.svg
            $svg2xxx -t pdf combined.svg
            $convert -density 300 combined.pdf combined.png";
}

