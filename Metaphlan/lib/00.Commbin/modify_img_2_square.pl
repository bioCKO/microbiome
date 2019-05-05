#!/usr/bin/perl
use strict;
use Data::Dumper;
use FindBin qw($Bin);
use warnings;
use Getopt::Long;
use Cwd qw(abs_path);
use lib "$Bin";
my $lib = "$Bin/../../";
use PATHWAY;
(-s "$Bin/../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../bin/, $!\n";
my($convert, $identify) = get_pathway("$Bin/../../bin/Pathway_cfg.txt",[qw(CONVERT IDENTIFY)],$Bin,$lib);
 my %opt = ("colour"=>"#FFFFFF");
 GetOptions(\%opt,"colour:s","frame_width:n","frame_height:n","png=s","out:s");
$opt{png} || die "
=head1 Usage
perl modify_img_2_square.pl  --png img.png   [options]
  --png*            <str>   the name of png 
  --colour         <num>   the color of frame 
  --frame_width    <num>   the width of frame 
  --frame_height   <num>   the height of frame
  --out            <num>   the outfile name 
=cut
";
#my $convert="/usr/bin/convert";
#my $identify="/usr/bin/identify";
#print "$opt{png}\n"; 
##get img_name
my $img_name=(split(/\./,$opt{png}))[0];

##trim frame 
my $trim_name = "$img_name"."_trim.png";
`$convert $opt{png} -trim -fuzz 10% $trim_name`;
##get trim_img info
my $trim_info=`$identify $trim_name`;
my @trim_info=split(/\s/,$trim_info);

###name format size(width X height)  size () (The minimum unit for each pixel) colour_format 
 ###tr10cluster.png PNG 1119x1253 4600x3400+1716+1069 16-bit DirectClass 54.5kb 
 
 
###add frame ,make img 2 squre_img

 $opt{out} || ($opt{out}="$img_name"."_square.png");
# print "$opt{out}\n";
 my @w_h=split ("x",$trim_info[2]);
 #print "@w_h\n";
 if ($w_h[0] > $w_h[1] )
 {
	my $cha=sprintf ("%.2f" , abs(($w_h[0]-$w_h[1])/2));
#	print "$cha\n";
	`$convert -mattecolor "$opt{colour}" -frame 10x$cha $trim_name $opt{out}`;
	`rm $trim_name`;
 }
 elsif($w_h[0] < $w_h[1])
 {
	my $cha=sprintf ("%.2f" , abs(($w_h[1]-$w_h[0])/2));
	`$convert -mattecolor "$opt{colour}" -frame $cha\"x10\" $trim_name $opt{out}`;
	`rm $trim_name`;
 }
 elsif($w_h[0] == $w_h[1])
 {
	die "Image had been a square!!!"
 }
 
 
