#/usr/bin/perl -w
use strict;
@ARGV || die"Usage: perl $0 <file> <recordf|number> [del_ornot]\n";
my ($file,$recol,$del) = @ARGV;
$del ||= 0;
my $num=0;
if($recol!~/\D/){
	$num = $recol;
}elsif(-s $recol){
	chomp($num = ((split/\s+/,`tail -1 $recol`)[-1] || 0));
}
if($num>0){
	my $file2 = "$file.$$";
	open OUT,">$file2";
	my $check = 1;
	foreach(`less $file`){
        if(!$check || /^\s*(cd|export)\s+\S+\s*;?\s*$/){
        }elsif($check && /#(\d+)\s*$/){
			($1 > $num) ? ($check = 0) : ($del ? next : ($_ = "#$_"));
		}
		print OUT;
	}
	close OUT;
	system"rm -rf $file;mv $file2 $file";
}
