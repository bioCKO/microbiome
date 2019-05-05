#!/usr/bin/perl -w
use strict;
@ARGV==2 || die"usage: perl $0 <indir/> <outdir/>\n";
my ($idir,$odir) = @ARGV;
(-d $odir) || mkdir($odir);
for(`find $idir -type f`){
    chomp;
    my ($dir,$file) = (split /\//)[-2,-1];
    my @out;
    open IN,$_ || die$!;
    my $head = <IN>;
    while(<IN>){
        my @l = split /\t/;
        ($l[-2] <= 0.05) && (push @out,[$l[-2],$_]);
    }
    close IN;
    if(@out){
        (-d "$odir/$dir") || mkdir"$odir/$dir";
        open OUT,">$odir/$dir/$file" || die$!;
        print OUT $head;
        for (sort {$a->[0] <=> $b->[0]} @out){
            print OUT $_->[1];
        }
        close OUT;
    }
}
