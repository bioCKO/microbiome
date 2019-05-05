#!/usr/bin/perl -w
use strict;
@ARGV || die"usage: perl cover_table.pl coverage.depth [out.table]\n";
my ($inf,$outf) = @ARGV;
open IN,$inf || die$!;
if($outf){
   open OUT,">$outf" || die$!;
   select OUT;
}
print "ChrID\tReferance_size(bp)\tCovered_length(bp)\tCoverage(%)\tDepth\n";
my $depth = 0;
my @scaf;
while(<IN>){
    /^\s/ && last;
	my @l=(split/[:\/\s]+/)[0,2,1,4,6]; # ref_id, ref_len, cov_len, percent, depth
    foreach(@l[2,4]){
        /\d/ || ($_ = 0);
        /(\S+)e\+(\d+)/ && ($_ = $1*10**$2);
    }
	$l[3]=int(10000*$l[2]/$l[1]+0.5)/100;
	my $outl = join("\t",@l)."\n";
    push @scaf,[$l[0],$outl];
	$depth += $l[1]*$l[4];
}
foreach(sort {$a->[0] cmp $b->[0]} @scaf){
    print $_->[1];
}
my @t;
while(<IN>){
	/^[TC].+:(\d+)/ && (push @t,$1);
}
close IN;
@t[2,3]=(int(10000*$t[1]/$t[0]+0.5)/100,int($depth/$t[0]+0.5));
print join("\t","Total",@t),"\n";
$outf && close(OUT);

