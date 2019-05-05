#! /usr/bin/perl -w 
# converting absolute mat to relative mat according to the sum for every sample.
# chen
# 2014-01-21

use File::Basename;
use Getopt::Long;
use strict;

my ($relative_mat, $out_file, $help ,$outdir);
GetOptions(
        "h!"     => \$help,
        "mat=s" => \$relative_mat,
        "out=s"  => \$out_file,
        "outdir=s" => \$outdir,
);
$outdir ||= './';
(-s $outdir) || `mkdir -p $outdir`;
($relative_mat && -s $relative_mat) || &usage();
	open(OR,"$relative_mat");
	my $head=<OR>;
	chomp $head;
	my @head=split/\t/,$head;
	my (%gene,);
	while (my $or=<OR>) {
		chomp $or;
		my @or=split/\t/,$or;
		for (my $i = 1; $i <= $#or; $i++) {
            $gene{$head[$i]} += $or[$i];
		}
	}
	close OR;
	open(OR,"$relative_mat");
	my $delete=<OR>;
	open OUT,">$outdir/$out_file";
	print OUT "$delete";
	while (my $or=<OR>) {
		chomp $or;
		my @or=split/\t/,$or;
		print OUT "$or[0]";
		for (my $i = 1; $i <= $#or; $i++) {
			my $tempcount=$or[$i];
			my $total_count=$gene{$head[$i]};
			my $relative_abun=$tempcount/$total_count;
			print OUT "\t$relative_abun";
		}
        print OUT "\n";
	}
	close OR;
	close OUT;

sub usage() {
        print "Usage:perl $0 -len <len.info> -mat <absolute_mat> -out <out_file>
        -mat   	[str]  absolute mat,
        -out    [str] Output file
        --outdir [str] output directory
        -h      print help info.
        Function: converting absolute mat to relative mat according to the sum for every sample.
        Contacter: chenjunru\@novogene.cn
        Date:2015-01-21\n";
        exit;
}
