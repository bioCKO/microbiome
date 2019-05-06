#!/usr/bin/perl -w
use strict;
#use lib "/home/liuwenbin/system/pm";
#use lib "system/pm";
#use COMM qw(abs_path mul_path);
use Getopt::Long;
use PerlIO::gzip;
my ($outdir,$prefix,$suffix,$line,$splitn,$splits,$head,$head2,$middle,$end,$filter,$absway,$absl,$help);
GetOptions(
	"outdir:s"=>\$outdir,
	"prefix:s"=>\$prefix,
	"suffix:s"=>\$suffix,
	"line:i"=>\$line,
	"splitn:i"=>\$splitn,
	"splits:s"=>\$splits,
	"head:s"=>\$head,
	"head2:s"=>\$head2,
	"middle:s"=>\$middle,
	"end:s"=>\$end,
	"filter"=>\$filter,
	"absway"=>\$absway,
	"absl:s"=>\$absl,
	"help"=>\$help
);
(@ARGV != 1 || $help) &&
	die"Name: split_file.pl
Describe: to split a ordinary file into several by specified sign
Author: liuwenbin, liuwenbin\@genomic.org.cn
Version: 1.1, Date: 2011-03-19
Usage: perl split_file.pl <infile>  [-option]
	-outdir <str>       directory to store subfile, default='./'
	-prefix <str>       subfile prefix, default=subfile
	-suffix <srt>       subfile suffix, default not set
	-line <num>         the line of infile put to per subfile, deafault=1
	-splitn <num>       split infile in specific number, default not set
	-splits <str>       split infile with specific sign, default '\\n'
	-head <str>         some words write at the head of subfiles
	-head2 <str>        some words write at the second head of subfiles
	-middle <str>       some words write at eatch line end or -head2
	-end <str>          sorm words write at the end of subfiles
	-filter             filter some solecism wihle split shell file
	-absway             change file or directory into absolutely pathway
	-absl <str>         outfile name of subfile abs_pathway list, default no out
	-help               output help information to screen;
Note: 1 sxxx can fill in subfile number at -head,head2,middle,end
      2 lxxx can fill in line number at -head2,middle
      3 -head,head2,end set can also in a file\n";

my $file = shift;
(-s $file) || die"Error: can't file infile $file or it's empty, please check it\n";
$prefix ||= 'subfile';
$outdir ||= './';
$absl && ($outdir = abs_path($outdir));#COMM.pm
(-d $outdir) || mkdir"$outdir";
$line ||= 1;
$suffix ? ($suffix =~ s/^\.+//,$suffix = ".$suffix") : ($suffix = ' ');
my $j=0;
foreach($head,$head2,$end,$middle){
	$_ || next;
	(-s $_) && ($_ = `less $_`);
	$absway && mul_path($_);
}
$middle && chomp($middle);
my @lines;
if($splits){##option value
	$splits =~ s/\\n/\n/g;
	$splits =~ s/\\t/\t/g;
	$/ = $splits;
}
$splits ||= $/;
if($splitn && $splitn==1){
	my $hold_file = `less $file`;
	@lines = ($hold_file);
}else{
	($file=~/\.gz$/) ? (open(INF,"<:gzip",$file) || die"error:$!") : (open(INF,$file) || die"error:$!");
	@lines = <INF>;
	close INF;
	until($lines[0] !~ /^$splits/){shift @lines;}
}
my ($fn,$fln,$s,$e,$rm);
if($splitn){
 	($splitn > @lines) && ($splitn = @lines);
	$fn = $splitn - 1;
	$fln = int(@lines/$splitn);
	$rm = @lines - ($fln++)*$splitn;
	$s = 0;
}else{
	$fln = $line;
	$fn = int(@lines/$line - 1e-7);
	($s,$rm) = (0,-1);
}
$absl && (open ABSL,">$absl");
my $head_2;
foreach my $i(0..$fn){
	($i==$rm) && ($fln--);
  $e=$s+$fln-1;
	($e>$#lines) && ($e = $#lines);
	my @shell_sub = @lines[$s..$e];
	@lines[$s..$e] = ();
	my $n = 0;
	if($middle || $filter || $absway){
		$head2 && 
		($head_2 = $head2,$head_2=~s/sxxx/$i/g,$head_2=~s/lxxx/$n/g,(unshift @shell_sub,$head_2));
		foreach(@shell_sub){
			/\w/ || next;
			my @line_add = split/\n/;
			foreach(@line_add){
				$_ || next;
				if($middle){
					my $middle0 = $middle;
					$middle0 =~ s/sxxx/$i/g;
					$middle0 =~ s/lxxx/$n/g;
					$_ .= " $middle0";
				}
				$absway && mul_path($_);#COMM.pm
				$filter && (s/&\s*;//g,s/&\s*$//g,s/^\s*;//,s/;\s*;/;/g,s/;\s*$//);
				$n++;
			}
			$_ = join("\n",@line_add) . $splits;
		}
	}
	my $out = join("",@shell_sub);
	my $sub_file_name = "${prefix}${i}$suffix";
	open LLLL,">$outdir/$sub_file_name" || die"$!\n";
	if($head){
		my $head0 = $head;
		$head0 =~ s/sxxx/$i/g;
		print LLLL "$head0\n";##option value
	}
	print LLLL "$out";
	if($end){
		my $end0 = $end;
		$end0 =~ s/sxxx/$i/g;
		$end0 =~ s/lxxx/$n/g;
		print LLLL "$end0\n";##option value
	}
	close LLLL;
	$absl && (print ABSL "$sub_file_name\t$outdir/$sub_file_name\n");
	$s+=$fln;
}
$absl && (close ABSL);
$/="\n";
#sub3.1
#############
sub abs_path
#############
{
  my $file = $_[0];
  chomp(my $current_dir = `pwd`);
  if($file !~/^\//){
        $file = "$current_dir/$file";
        }
        $file;
}
#sub3.3
####################
sub mul_path
####################
{
        my @a = split/\s+/,$_[0];
        foreach(@a){
                (/^\//) && next;
    (/^(\.{1,2}\/)/) && ($_ = abs_path($_), next);
    ($_ eq '.' || $_ eq '..') && next;
    ((-f $_) || (-d $_)) && ($_ = abs_path($_), next);
                (/^([12]?>{1,3}&?)([^>&]+)/) && ($_ = $1 . abs_path($2));
        }
        $_[0] = join(" ",@a);
}
