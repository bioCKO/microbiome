use strict;
use warnings;


(@ARGV==2) || die"perl $0 <merge.table> <outdir>\n";
my %order = qw(k metaphlan.k.relative.xls p metaphlan.p.relative.xls c metaphlan.c.relative.xls o metaphlan.o.relative.xls f metaphlan.f.relative.xls g metaphlan.g.relative.xls s metaphlan.s.relative.xls);
my $f = shift;
my $outdir = shift;
#`rm $outdir/*`;
-s $outdir || `mkdir -p $outdir`;
-s "$outdir/heatmap" || `mkdir -p $outdir/heatmap`;

open F, $f;
#my $head = <F>; $head =~ s/\n//g; $head = $head."\tTax_detail\n";
my $head = <F>;my @head = split/\s+/, $head;
my %rank2table;
my %rank2total;
while(<F>){
    chomp;
    my($id, @cov) = split /\t/, $_;
    my @cov_rel=map{ $_/100;} @cov;
    my @subid = split /\|/, $id;
    if($subid[-1] =~ /([kpcofgs])__(.*)/){
        my $rank=$1;
        my $tax=$2;
        my $detail_tax=join(";",@subid);
        my $max_cov;
        foreach my $c (@cov){$max_cov= $c if !$max_cov || $c > $max_cov;}
        push @{$rank2table{$rank}{$max_cov}},"$tax\t".join("\t",@cov_rel)."\t$detail_tax";
        for my $i (0..$#cov){
            ${$rank2total{$rank}}[$i] += $cov[$i];
        }
    }
}
close F;

foreach my $rank (keys %order){
    open(OUT,">$outdir/$order{$rank}");
    open(OUT2,">$outdir/heatmap/$order{$rank}");
    my $rank_total=$rank2total{$rank};
    my @rank_total=map {my $i=(100-$_)/100;$i < 0 ? '0' : $i;} @$rank_total;
    print OUT join("\t",@head)."\tTax_detail\n";
    print OUT2 join("\t",@head)."\n";
    foreach my $cov (sort {$b <=> $a} keys %{$rank2table{$rank}}){
        print OUT join("\n",@{$rank2table{$rank}{$cov}})."\n";
        print OUT2 "$rank\__".join("\n",@{$rank2table{$rank}{$cov}})."\n";
    }
    print OUT "Others\t".join("\t",@rank_total)."\tOthers\n";
    print OUT2 "Others\t".join("\t",@rank_total)."\tOthers\n";
    close OUT;
    close OUT2;
}
