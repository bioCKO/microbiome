use strict;
use warnings;

die "usage: perl $0 <lca.tax.xls> <concoct_s.lca.xls>\n" unless  @ARGV == 2;
open O, ">$ARGV[1]";
open F, "$ARGV[0]";
while(<F>){
    chomp;
    my ($id, $lev) = (split /\t/, $_);  
    my $last_lev = (split /;/, $_)[-1];
    my $s_anno;
    if($last_lev =~ /s__/){
        $last_lev =~ s/s__//g;
        my @tem = split /\s+/, $last_lev;
        $s_anno = "_".join("_", @tem); 
    }
    else{
        $s_anno = "NA";
    }
    print O "$id,$s_anno\n";
}
close F; close O;
