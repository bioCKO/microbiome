#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../../../lib/00.Commbin/";
use PATHWAY;
( -s "$Bin/../../../bin/Pathway_cfg.txt" ) || die "error: can't find config at $Bin/../../../bin, $!\n";
##Creat by wangmenghan;
#last Version 20140510 ,last amender: wangxiaohong@novogene.cn;last amend:2014.05.10
#last Notice: 1.Automatically set the image size. 2.Set a specific classification level

my ($R,) = get_pathway( "$Bin/../../../bin/Pathway_cfg.txt", [qw(R4 )] );

@ARGV || die "usage: perl $0 <otu_table.txt> <levelperfix[g__/f__/o__/c__/p__]> [outprefix[cluster]]\n";

my ( $infile,$perfix, $outfile,$abundant_limt ) = @ARGV;
$outfile ||= "cluster";
open IN,  $infile || die "error: can't open $infile $! . Please Check input file .";
open OUT, ">$outfile.txt" || die$!;
my ( $taxon, $fulltaxon, $ra, @sample_id, @abundance, %inf, $title );
my ( %taxon_abundance, %line, @line );
$title = <IN>;
@sample_id = split /\s+/, $title;
pop @sample_id;
$title =~ s/^Taxon\t//;$title =~ s/\tTax_detail$//g;
print OUT $title;

my $sample_num=scalar(split(/\s+/,$title));
if($sample_num<=2){
	die "Can't run $0 command, due to the sample number is less than 2.\n ";
	
}

while (<IN>) {
	chomp;
	@abundance = split /\t/, $_;
    pop @abundance;
    $_ = join("\t",@abundance);
	$taxon     = $abundance[0];
	@line      = split /\t/, $_, 2;
	if ( $taxon =~ /$perfix\w+/ ) {
		$taxon =~ s/(.)*$perfix//;
		$taxon =~ s/\s+/_/;
		if( length($taxon) > 60 || $taxon eq 'Others'){
			next;
		}
		$line{$taxon} = $line[1];
		for ( my $i = 1 ; $i <= $#sample_id ; $i++ ) {
			$ra = $abundance[$i];
			$ra = sprintf "%.15f", $1 / ( 10**$2 ) if ( $ra =~ /(.*)e-(\d+)/ );
			#$inf{ $sample_id[$i] } .= $sample_id[$i] . "\t" . $ra . "\t" . $taxon . "\n";
			if ( exists $taxon_abundance{$taxon} ) {
				$taxon_abundance{$taxon} = $ra if ( $taxon_abundance{$taxon} < $ra );
			}
			else {
				$taxon_abundance{$taxon} = $ra;
			}
		}
	}
}
close IN;

my %top_abundant;
my $abundant_num  = 0;
$abundant_limt ||= 35;

my $pdf_w =$sample_num*45/155+10;
my $pdf_h =$abundant_limt*13/35;

foreach my $tmp_abundant ( sort { $taxon_abundance{$b} <=> $taxon_abundance{$a} } keys %taxon_abundance ) {
	$abundant_num += 1;
	$top_abundant{$tmp_abundant} = $taxon_abundance{$tmp_abundant} if ( $abundant_num <= $abundant_limt );
}

foreach my $key ( keys %top_abundant ) {
	print OUT $key . "\t" . $line{$key} . "\n";
}

close OUT;

open R, ">$outfile.R";
print R
"
library(pheatmap)
x<-read.table(\"$outfile.txt\",sep=\"\\t\",header=T,row.names=1)
#png(filename=\"cluster.png\",type=\"cairo\",height=7200,width=7200,res=600)
#pheatmap(x,scale=\"row\",fontsize=20)";

print R "
#pdf(\"$outfile.pdf\",height=ceiling($pdf_h),width=ceiling($pdf_w))
pheatmap(x,scale=\"row\",filename=\"$outfile.pdf\",cluster_cols = FALSE)
dev.off()";

close R;

`$R -f $outfile.R`;
`/usr/bin/convert -density 200 $outfile.pdf $outfile.png`;
`rm -f Rplots.pdf`;
