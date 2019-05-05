#!/usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use Getopt::Long;
use File::Basename;
my %opt = (outdir=>'.',sig=>'0.05,0.05');
GetOptions(\%opt,"indir:s","outdir:s","sig:s");
$opt{indir} && (-s $opt{indir}) || die "Usage:perl $0 --indir input_dir [--option]
    --indir <dir>       input file dir
    --outdir <dir>      output file dir,default='.'
    --sig <str>         set select significance value,format:psig,qsig,default='0.05,0.05'\n";
my ($indir,$outdir) = map {abs_path($_)} ($opt{indir},$opt{outdir});
my ($psig,$qsig) = split /,/,$opt{sig};
for my $infile(`ls $indir/*.test.xls`){
    chomp $infile;
    my ($base,$path,$suffix) = fileparse($infile,qr{.test.xls});
    open IN,"<$infile" || die $!;
    my $head = <IN>;
    my (@psig_out,@qsig_out);
    while(<IN>){
        my @l = split /\t/;
        ($l[-2] <= $psig) && (push @psig_out,[$l[-2],$_]);
        ($l[-2] <= $psig) && ($l[-1] >= 0) && ($l[-1]<= $qsig) && (push @qsig_out,[$l[-1],$_]);
    }
    close IN;
    open OUT1,">$outdir/$base.psig.xls";
    print OUT1 $head;
    for(sort {$a->[0] <=> $b->[0]} @psig_out){
        print OUT1 $_ ->[1];
    }
    close OUT1;
    open OUT2,">$outdir/$base.qsig.xls";
    print OUT2 $head;
    for(sort {$a->[0] <=> $b->[0]} @qsig_out){
        print OUT2 $_ ->[1];
    }
    close OUT2;
}
