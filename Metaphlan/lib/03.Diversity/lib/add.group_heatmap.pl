#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
my $abundant_limt=35;
GetOptions("top:i"=>\$abundant_limt);
use lib "$Bin/../../00.Commbin/";
use PATHWAY;
( -s "$Bin/../../../bin/Pathway_cfg.txt" ) || die "error: can't find config at $Bin/../../../bin, $!\n";
##Creat by wangmenghan;
#last Version 20140510 ,last amender: wangxiaohong@novogene.cn;last amend:2014.05.10
#last Notice: 1.Automatically set the image size. 2.Set a specific classification level
#add group and phylum,use R v3.1.0;hanpeng,20150821
my ($R) = get_pathway( "$Bin/../../../bin/Pathway_cfg.txt", [qw(R4)] );
@ARGV || die "usage: perl $0 <otu_table.txt> <levelprefix:[g__/f__/o__/c__/p__]> [outfileprefix:[cluster.g/f/o/c/p]] [outprefix:[L-p/L-c/L-o/L-f]/L-g] <group>
example: perl $0 sorted_otu_table_L6.txt g__ cluster.g p-g group [--option]\n";

my ($infile,$perfix,$outfile,$rank_rank) = @ARGV;
my $rank = $1 if($rank_rank=~/(\w)-(\w)/);
my %rank_level=("p"=>"Phylum","c"=>"Class","o"=>"Order","f"=>"Family");
$outfile ||= "cluster";
my $group;
if($ARGV[4]){
    $group=$ARGV[4];
    $group = abs_path($group);
}
open IN,  $infile || die "error: can't open $infile $! . Please Check input file .";
open OUT, ">$outfile.txt" || die$!;
open LP, ">$rank_rank.list" || die$!;
my ( $taxon, $fulltaxon, %taxon_num,%tax_full,$ra, @sample_id, @abundance, %inf, $title );
my ( %taxon_abundance, %line, @line, %phylum_genus);
$title = <IN>;
@sample_id = split /\s+/, $title;
$title =~ s/^Taxon\t//;
print OUT $title;

my $sample_num=scalar(split(/\s+/,$title));
if($sample_num<=2){
	die "Can't run $0 command, due to the sample number is less than 2.\n ";
	
}

while (<IN>) {
	chomp;
	@abundance = split /\t/, $_;
	$fulltaxon     = $abundance[0];
    $taxon = $fulltaxon;
    @line      = split /\t/, $_, 2;
	if ( $taxon =~ /$perfix[\-\s\w\[\]]+/ ) {
        my $phylum = $1 if($taxon =~ /${rank}__([\-\s\w\[\]]+)/);
        $taxon =~ s/(.)*$perfix//;
		$taxon =~ s/\s+/_/;
        $taxon_num{$taxon}++;
        if($taxon_num{$taxon}<2){
            $tax_full{$fulltaxon} = $taxon;
        }else{
            my @level=split /;/,$fulltaxon;
            $taxon = pop @level;
            foreach (1..$#level){
                ($level[-1]=~ /unidentified/ && pop @level) || last;
            }
            $tax_full{$fulltaxon} = "$level[-1];$taxon";
        }
        $phylum_genus{$fulltaxon} = $phylum;
		$line{$fulltaxon} = $line[1];
		for ( my $i = 1 ; $i <= $#sample_id ; $i++ ) {
			$ra = $abundance[$i];
			$ra = sprintf "%.15f", $1 / ( 10**$2 ) if ( $ra =~ /(.*)e-(\d+)/ );
			#$inf{ $sample_id[$i] } .= $sample_id[$i] . "\t" . $ra . "\t" . $taxon . "\n";
			if ( exists $taxon_abundance{$fulltaxon} ) {
				$taxon_abundance{$fulltaxon} = $ra if ( $taxon_abundance{$fulltaxon} < $ra );
			}
			else {
				$taxon_abundance{$fulltaxon} = $ra;
			}
		}
	}
}
close IN;

my %top_abundant;
my $abundant_num  = 0;
#my $abundant_limt = 35;

my $pdf_w =$sample_num*105/155+16;
#my $pdf_w =24;
my $pdf_h =$abundant_limt*18/35+6;
#my $pdf_h =24;

foreach my $tmp_abundant ( sort { $taxon_abundance{$b} <=> $taxon_abundance{$a} } keys %taxon_abundance ) {
	$abundant_num += 1;
	$top_abundant{$tmp_abundant} = $taxon_abundance{$tmp_abundant} if ( $abundant_num <= $abundant_limt );
}

foreach my $key ( keys %top_abundant ) {
	print OUT $tax_full{$key}. "\t" . $line{$key} . "\n";
    print LP "$tax_full{$key}\t$phylum_genus{$key}\n";
}

close OUT;
close LP;

open R, ">$outfile.R";
if($group){
    if($outfile=~/cluster.p/){
        print R "library(pheatmap)
        x<-read.table(\"$outfile.txt\",sep=\"\\t\",header=T,row.names=1)
        group<-read.table(\"$group\",sep=\"\\t\",header=T)
        annotation_col = data.frame(Group=factor(group\$group))
        rownames(annotation_col) = group\$sample
        pheatmap(x,scale=\"row\",annotation_col = annotation_col,filename=\"$outfile.pdf\",height=ceiling($pdf_h),width=ceiling($pdf_w),fontsize=20)    
        dev.off()";
    }else{ 
        print R "library(pheatmap)
        x<-read.table(\"$outfile.txt\",sep=\"\\t\",header=T,row.names=1)
        group<-read.table(\"$group\",sep=\"\\t\",header=T)
        tax<-read.table(\"$rank_rank.list\",sep=\"\\t\",header=F)
        annotation_col = data.frame(Group=factor(group\$group))
        rownames(annotation_col) = group\$sample
        annotation_row = data.frame($rank_level{$rank}=factor(tax\$V2))
        rownames(annotation_row) = tax\$V1
        pheatmap(x,scale=\"row\",annotation_col = annotation_col, annotation_row = annotation_row,filename=\"$outfile.pdf\",height=ceiling($pdf_h),width=ceiling($pdf_w),fontsize=20)
        dev.off()";
    }
}else{
    if($outfile=~/cluster.p/){
        print R "library(pheatmap)
        x<-read.table(\"$outfile.txt\",sep=\"\\t\",header=T,row.names=1)
        pheatmap(x,scale=\"row\",filename=\"$outfile.pdf\",height=ceiling($pdf_h),width=ceiling($pdf_w),fontsize=20)
        dev.off()";
    }else{
        print R "library(pheatmap)
        x<-read.table(\"$outfile.txt\",sep=\"\\t\",header=T,row.names=1)
        tax<-read.table(\"$rank_rank.list\",sep=\"\\t\",header=F)
        annotation_row = data.frame($rank_level{$rank}=factor(tax\$V2))
        rownames(annotation_row) = tax\$V1
        pheatmap(x,scale=\"row\",annotation_row = annotation_row,filename=\"$outfile.pdf\",,height=ceiling($pdf_h),width=ceiling($pdf_w),fontsize=20)
        dev.off()";
    }
}
close R;

`$R -f $outfile.R`;
`/usr/bin/convert -density 100 $outfile.pdf $outfile.png`;
#`rm -r $rank_rank.list`;
(-s "Rplots.pdf")&&(`rm -r Rplots.pdf`);
