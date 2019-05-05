#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt=(pw=>300,ph=>300,wd=>0,hd=>0,fsize=>10);
GetOptions(\%opt,"pw:i","ph:i","width:i","height:i","wn:i","hn","sufix:s","wd:f","hd:f","nh","nw",
    "ltext:s","ftext:s","fsize:s","xhead:f","xend:f","yhead:f","yend:f");
@ARGV || die"Name: combine_fig.pl
Descritpion: scription to cmbine figure
Usage: perl combine_fig.pl <fig1> <fig2> ... <fign> [-options] > out.fig
Usage: perl combine_fig.pl <fig_dir1/> ... <fig_dirn/> [-options] > out.fig
    -pw <num>       per-figure width, default=300
    -ph <num>       per-figure height, default=300
    -width <num>    total width limit, default not set
    -height <num>   total height limit, default not set
    -wn <num>       figure number per row, default auto
    -hn <num>       figure number per rank, default auto
    -wd <flo>       width delete percent, default=0
    -hd <flo>       height delete percent, default=0
    -ltext <str>    text for each line
    -ftext <str>    text for each figure
    -txy <str>      text star x,y, default=0,0
    -fsize <flo>    text font size, default=10
    -xhead <flo>    add x head size, default=0
    -xend <flo>     add x end size ,defualt=0
    -yhead <flo>    add y head size default=0
    -yend <flo>     add y end size default=0
    -sufix <str>    set figure sufix while input directory
Example:
    perl combine_fig.pl  A.png B.png C.png D.png -ftext 'A,B,C,D' > combine.svg
    convert combine.svg combine.png\n";
#===================================================================================
my @fig;
for(@ARGV){
    if(-d $_){
        my $f = $opt{sufix} ? "*$opt{sufix}" : "*";
        chomp(my @tem_fig = `ls $_/$f`);
        push @fig,@tem_fig;
    }else{
        push @fig,$_;
    }
}
for(@fig){s/\*$//;}
my $fig_num = @fig;
if($opt{wn}){
    $opt{hn} = int($fig_num / $opt{wn});
    ($opt{hn} * $opt{wn} < $fig_num) && ($opt{hn}++);
}elsif($opt{hn}){
    $opt{wn} = int($fig_num / $opt{hn});
    ($opt{wn} * $opt{wn} < $fig_num) && ($opt{wn}++);
}else{
    $opt{hn} = sqrt($fig_num);
    $opt{wn} = int($opt{hn});
    ($opt{hn} > $opt{wn}) && ($opt{wn}++);
    $opt{hn} = int($fig_num / $opt{wn});
    ($opt{hn} * $opt{wn} < $fig_num) && ($opt{hn}++);
}
my ($pw,$ph);
if($opt{width}){
    $opt{width} /= (1-$opt{wd});
    $pw = sprintf("%.2f",$opt{width}/$opt{wn});
    $opt{ph} = sprintf("%.2f",$opt{ph}*$opt{pw}/$pw);
    $opt{pw} = $pw;
}elsif($opt{height}){
    $opt{height} /= (1-$opt{hd});
    $ph = sprintf("%.2f",$opt{height}/$opt{hn});
    $opt{pw} = sprintf("%.2f",$opt{ph}*$opt{pw}/$ph);
    $opt{ph} = $ph;
}
($pw,$ph) = ($opt{pw},$opt{ph});
my ($x,$y) = (0, 0);
for(qw(xhead xend)){
    $opt{$_} ||= 0;
    ($opt{$_} < 1) && ($opt{$_} *= $opt{pw});
}
for(qw(yhead yend)){
    $opt{$_} ||= 0;
    ($opt{$_} < 1) && ($opt{$_} *= $opt{pw});
}
if($opt{wd}){
    $opt{nw} || ($x -= $opt{pw}*$opt{wd});
    $pw *= (1-$opt{wd});
    $opt{width} = $pw * $opt{wn} - $opt{pw}*$opt{wd};
}else{
    $opt{width} = $pw * $opt{wn};
}
$opt{nw} && ($opt{width} += $opt{pw}*$opt{wd}*2);
if($opt{hd}){
    $opt{nh} || ($y -= $opt{ph}*$opt{hd});
    $ph *= (1-$opt{hd});
    $opt{height} = $ph * $opt{hn} - $opt{ph}*$opt{hd};
}else{
    $opt{height} = $ph * $opt{hn};
}
$opt{nh} && ($opt{height} += $opt{ph}*$opt{hd}*2);
$opt{width} += $opt{xhead}+$opt{xend};
$opt{height} += $opt{yhead}+$opt{yend};
$opt{xhead} && ($x += $opt{xhead});
$opt{yhead} && ($y += $opt{yhead});
print '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">',
"\n<svg height=\"$opt{height}\" width=\"$opt{width}\" ",
'xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',"\n";
my @ltext = $opt{ltext} ? split/,/,$opt{ltext} : ();
my @ftext = $opt{ftext} ? split/,/,$opt{ftext} : ();
my ($tx,$ty) = $opt{txy} ? split/,/,$opt{txy} : (0, 0);
$tx += $opt{fsize};
$ty += $opt{fsize};
my $x0 = $x;
my $n = 0;
for my $image(@fig){
    print "\t <image x=\"$x\" y=\"$y\" width=\"$opt{pw}\" height=\"$opt{ph}\" xlink:href=\"$image\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" />\n";
    if(@ltext && $x==$x0){
        my $ltext = shift @ltext;
        print "\t<text fill=\"black\" font-family=\"Arial\" font-size=\"$opt{fsize}\" stroke=\"none\" x=\"$tx\" y=\"$ty\">$ltext</text>\n";
    }
    if(@ftext){
        my $ftext = shift @ftext;
        print "\t<text fill=\"black\" font-family=\"Arial\" font-size=\"$opt{fsize}\" stroke=\"none\" x=\"$tx\" y=\"$ty\">$ftext</text>\n";
        $tx += $pw;
    }
    $x += $pw;
    $n++;
    if($n == $opt{wn}){
        ($n,$x) = (0,$x0);
        $y += $ph;
        $ty += $ph;
    }
}
print "</svg>\n";
