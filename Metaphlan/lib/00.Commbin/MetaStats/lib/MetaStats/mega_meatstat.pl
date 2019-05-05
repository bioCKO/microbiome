#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
@ARGV==2 || die"usage: perl $0 <indir> <outdir>\n";
my ($indir,$odir) = @ARGV;
(-d $odir) || mkdir($odir);
for (`ls $indir/*/*/test_*`){
    chomp;
    s/\*$//;
    my ($dir,$lev,$group) = (split /\//)[-3,-2,-1];
    (-d "$odir/$dir") || mkdir"$odir/$dir";
    system"perl $Bin/tab2xls.pl $_ > $odir/$dir/$group.$lev.xls";
}
