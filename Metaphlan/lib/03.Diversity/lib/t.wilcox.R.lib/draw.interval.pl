#!/usr/bin/perl -w
use strict;
use SVG;
use Getopt::Long;
use List::Util qw(max min);
use lib "/PUBLIC/software/MICRO/share/16S_pipeline/16S_pipeline_V3.1/software/svg/bin";
use DRAW;
my $Rscript = "/PUBLIC/software/public/System/R-2.15.3/bin/Rscript";
my ($infile) =  @ARGV;
my $min_mean;
my $outfile;
GetOptions("min_mean:f"=>\$min_mean, "outfile:s"=>\$outfile);
(-s $infile) || die"usage:perl $0 <infile: psig.xls> [min_mean:default0.00001] > out.svg
    infile format:  mean1 sv1 mean2 sv2 p_value interval_lower interval_upper
    min_mean:       if one group's tax mean < min_mean, the tax will not drawed in the picture            
\n";
#if(undef($min_mean)){ $min_mean=0.001};
my(@species,@group1_means,@group2_means,@pvalues,$intervals);#可以这么定义？
open PSIG,"<$infile" or die $!;
my $group1_name ;
my $group2_name ;
while(<PSIG>){
    if(/avg\((\S+)\).*?avg\((\S+)\)/){ ($group1_name,$group2_name)=($1,$2);next}
    my @fields = /\t/ ? split/\t/ : split;
    ($fields[0] =~ /Others/) && next;
    if( ($fields[5]<=0.05) && (($fields[1]>$min_mean) || ($fields[3]>$min_mean))){#p values < 0.05
        my $spe = (split/;/,$fields[0])[-1];
        $spe =~ s/\S+__//g;
        push @species, $spe;

        push @group1_means,$fields[1];
        push @group2_means,$fields[3];
        push @pvalues, sprintf("%.3f",$fields[5]); 
        push @{$intervals},[$fields[7],$fields[8],$fields[1]-$fields[3]];#lower, upper, mean diff 
    }
}
close PSIG;
if(@species==0){die"Warning: There is no tax pvalue <0.05 and both groups' mean >$min_mean in $infile"}
my @lowers;
my @uppers;
for my $in(@{$intervals}){push @lowers, $in->[0];push @uppers, $in->[1]}
my($interval_min,$interval_max)=(min(@lowers), max(@uppers));#所有置信区间的最小值，与最大值,需要修改


my @species_name_len = map{length($_)}@species;
my $spe_name_max_len = max(@species_name_len);
my $tax_num = scalar(@species);
my $max_mean= max(@group1_means,@group2_means);


my $width = 450;#两块画图区域
my $height = 300;#纯画图部分。
#my $flank_x = 150;#留出来写物种名称
my $flank_y = 100;#留出上面写字的
my $x_text_scale=20;
my $fontsize = 10;#max(0.04 * $height,15);
my $tax_len = $spe_name_max_len*$fontsize*0.55+2*$fontsize;#物种宽度
#my $flank_x = $tax_len > 120 ? $tax_len + 30 : 150; #防止字长超出原始flank_x大小
my $flank_x = $tax_len +  $spe_name_max_len;
my $h_unit = $height/$tax_num;#
if($h_unit<20){
    $h_unit=20;$height=$h_unit*$tax_num
}elsif($h_unit>50){
    $h_unit=50;$height=$h_unit*$tax_num
}#防止条形太细

my $pwidth  = $width + $flank_x+$tax_len+50;     # Calculate the width of the paper，100留给右空白
my $pheight = $height + $flank_y*2;    # Calculate the height of the paper


my $group1_color="sandybrown";
my $group2_color="cornflowerblue";

my $w1=140;
my $w2=250;
my $middle_blank = $width-$w1-$w2;#30
my $size_x = 5;#x轴须长度
#my $size_scale=5;#x轴刻度值

##======   Creat A New drawing paper  ======##

my $svg = SVG->new(width=> $pwidth,height=> $pheight);

#均值坐标轴
my $X0 = $flank_x;
my $Y0 = $flank_y+$height+$size_x*2;

$svg->line('x1',$X0,'y1',$Y0, 'x2',$X0+$w1,'y2',$Y0,'stroke', 'black', 'stroke-width', 2);#均值的x坐标轴横线
$svg->line('x1',$X0,'y1',$Y0, 'x2',$X0,'y2',$Y0-$size_x,'stroke', 'black', 'stroke-width', 1);#左边x轴，左刻度
$svg->line('x1',$X0+$w1,'y1',$Y0, 'x2',$X0+$w1,'y2',$Y0-$size_x,'stroke', 'black', 'stroke-width', 1);#左边x轴，右刻度
my $mean_x_fonsize= $fontsize;
$svg->text('x',$X0,'y',$Y0 + 1.5*$fontsize,'-cdata',0.0,'font-family','Arial', 'font-size',$mean_x_fonsize,'text-anchor','middle');#x轴起始坐标,刻度值0.0

my ($left_axis_min, $left_axis_unit, $left_axis_num, $left_axis_leng)=mul_axis(0,$max_mean);

#$max_mean=sprintf("%.5f",$max_mean);
my $left_axis_scale = $left_axis_min+$left_axis_unit*$left_axis_num;
my $x_mean_rate = $w1/$left_axis_scale;
$svg->text('x',$X0+$w1,'y',$Y0+1.5*$fontsize,'-cdata',$left_axis_scale,'font-family','Arial', 'font-size',$mean_x_fonsize,'text-anchor','middle');#x轴终止坐标刻度值
$svg->text('x',$X0+$w1/2,'y',$Y0+ 3* $fontsize,'-cdata','Means in groups','font-family','Arial', 'font-size',1.5*$fontsize,'text-anchor','middle');#means in groups
#图例，分组说明
my $group1_rect_x = $X0-$tax_len;
$svg->rect('x',$group1_rect_x,'y',$flank_y-20-$fontsize,'width', $w1*0.2,'height',$fontsize,,'fill',$group1_color,'stroke','black');#分组图例
my $group1_legend=$group1_rect_x+$w1*0.2+0.5* $fontsize;
$svg->text('x',$group1_legend,'y',$flank_y-20,'-cdata',$group1_name,'font-family','Arial', 'font-size',$fontsize,'text-anchor','start');#x轴终止坐标刻度值，需要改
my $goup2_rect_start=$group1_legend+length($group1_name)*$fontsize;
$svg->rect('x',$goup2_rect_start,'y',$flank_y-20-$fontsize,'width', $w1*0.2,'height',$fontsize,'fill',$group2_color,'stroke','black');#分组图例
my $group2_legend = $goup2_rect_start+$w1*0.2+0.5*$fontsize;
$svg->text('x',$group2_legend,'y',$flank_y-20,'-cdata',$group2_name,'font-family','Arial', 'font-size',$fontsize,'text-anchor','start');#x轴终止坐标刻度值，需要改



#置信区间坐标轴
my $dash_line;
my ($right_axis_min, $right_axis_unit, $right_axis_num, $right_axis_leng)=mul_axis($interval_min,$interval_max);
#$right_axis_num区间个数，$right_axis_leng=$right_axis_unit*$right_axis_num
my $interval_x_rate=$w2/ $right_axis_unit/ $right_axis_num;
my $X00 = $X0+$w1+$middle_blank;
$svg->line('x1',$X00,'y1',$Y0, 'x2',$X00+$w2,'y2',$Y0,'stroke', 'black', 'stroke-width', 2);#置信区间x轴线横线
for my $i(0..$right_axis_num){#刻度线+刻度值
    my $text_interval = $X00+$i*$right_axis_unit*$interval_x_rate;
    $svg->line('x1',$text_interval,'y1',$Y0, 'x2',$text_interval,'y2',$Y0-$size_x,'stroke', 'black', 'stroke-width', 1);#右边x轴，左刻度
    my $interval_value = $right_axis_min+$i*$right_axis_unit;
    my $xx=$text_interval;
    my $yy = $Y0+1.5 * $fontsize;
    #my $group3 = $svg->group("transform"=>"rotate(-45,$xx,$yy)");
    #$group3->text('x',$xx,'y',$yy,'-cdata',$interval_value, 'font-size',$mean_x_fonsize ,'text-anchor', 'end','font-family','Arial');
    $svg->text('x',$xx,'y',$yy,'-cdata',$interval_value, 'font-size',$mean_x_fonsize ,'text-anchor', 'end','font-family','Arial');
    if($interval_value ==0){$dash_line=$text_interval}#记录0在图上的位置
}
$svg->line('x1',$dash_line,'y1',$flank_y+$height,  'x2',$dash_line,'y2',$flank_y,'stroke', 'black', 'stroke-width', 1,'stroke-dasharray','3 2');#0虚线
$svg->text('x',$X00+$w2/2,'y',$Y0+ 3*$fontsize,'-cdata','Difference between groups','font-family','Arial', 'font-size',1.5*$fontsize,'text-anchor','middle');#x轴终止坐标刻度值，需要改
$svg->text('x',$X00+$w2/2,'y',$flank_y-20,'-cdata','95% confidence intervals','font-family','Arial', 'font-size',$fontsize,'text-anchor','middle');#onfidence intervals





#均值坐标轴的柱形
my $pvalues_x=$X0+$width+0.5*$fontsize;
for my $i(1..$tax_num){#total gray opacity bar
    my $tax_y_corrd = $flank_y+($i-0.5)*$h_unit+0.5*$fontsize;
    $svg->text('x',$X0-0.5*$fontsize,'y',$tax_y_corrd,'-cdata',$species[$i-1], 'font-size',$fontsize ,'text-anchor', 'end','font-family','Arial');#tax_names left 
    if($pvalues[$i-1]<0.001){
        $svg->text('x',$pvalues_x,'y',$tax_y_corrd,'-cdata',"<0.001", 'font-size',$fontsize ,'text-anchor', 'start','font-family','Arial');#pvalues right ,空白两个字体  
    }else{
        $svg->text('x',$pvalues_x,'y',$tax_y_corrd,'-cdata',$pvalues[$i-1], 'font-size',$fontsize ,'text-anchor', 'start','font-family','Arial');#pvalues right ,空白两个字体  
}
    ($i%2) || next;
    my $gray_y = $flank_y+($i-1)*$h_unit;
    $svg->rect('x',$X0,'y',$gray_y,'width', $w1,'height',$h_unit,'fill-opacity',0.1);
    $svg->rect('x',$X00,'y',$gray_y,'width', $w2,'height',$h_unit,'fill-opacity',0.1,);

}
for my $j(1..$tax_num){ #every group bar 
    my $y_step = $flank_y+($j-1)*$h_unit;
    my $group1_width = $group1_means[$j-1]*$x_mean_rate;
    my $group2_width = $group2_means[$j-1]*$x_mean_rate;
    $svg->rect('x',$X0,'y',$y_step+0.1*$h_unit,'width', $group1_width,'height',$h_unit*0.4,'fill',$group1_color,'stroke','black','stroke-width',1);#
    $svg->rect('x',$X0,'y',$y_step+$h_unit/2,'width', $group2_width,'height',$h_unit*0.4,'fill',$group2_color,stroke=>'black');#group2 mean bar 

}


#置信区间的图形
my $r= $h_unit/6;

for my $j(1..$tax_num){
    my @inter_X0;
    my $inter_lower =   $X00+($intervals->[$j-1]->[0]-$right_axis_min)*$interval_x_rate;
    my $inter_upper =   $X00+($intervals->[$j-1]->[1]-$right_axis_min)*$interval_x_rate;
    my $mean_diff   =   $X00+($intervals->[$j-1]->[2]-$right_axis_min)*$interval_x_rate;
    my $y_start = $flank_y+($j-0.5)*$h_unit;
    $svg->line('x1',$inter_lower,'y1',$y_start, 'x2',$mean_diff-$r,'y2',$y_start,'stroke', 'black', 'stroke-width', 1);#置信区间，左线
    my $color ;
    ($intervals->[$j-1]->[2]>0) ? ($color= $group1_color) : ($color= $group2_color);
    $svg->circle(cx => $mean_diff, cy => $y_start, r => $r, fill => "$color",stroke=>'black', );
    $svg->line('x1',$mean_diff+$r,'y1',$y_start, 'x2',$inter_upper,'y2',$y_start,'stroke', 'black', 'stroke-width', 1);#置信区间，右线
    $svg->line('x1',$inter_lower,'y1',$y_start-$r / 2, 'x2',$inter_lower ,'y2',$y_start+$r/2,'stroke', 'black', 'stroke-width', 1);#置信区间，左线,竖线  
    $svg->line('x1',$inter_upper,'y1',$y_start-$r/ 2, 'x2',$inter_upper,'y2',$y_start+$r/2,'stroke', 'black', 'stroke-width', 1);
    
}

my @pvalues_len = map{length}@pvalues;
my $pvalue_x = $pvalues_x+max(@pvalues_len)*$fontsize*0.55+1.5*$fontsize;#
my $pvalue_y = $flank_y+$tax_num/2*$h_unit;
my $svg_group  = $svg->group("transform"=>"rotate(90,$pvalue_x,$pvalue_y)");
$svg_group->text('x',$pvalue_x,'y',$pvalue_y,'-cdata','p_value', 'font-size',$fontsize ,'text-anchor', 'middle','font-family','Arial',);



open OUT, ">$outfile" || die $!;
print OUT $svg->xmlify;
close OUT;

