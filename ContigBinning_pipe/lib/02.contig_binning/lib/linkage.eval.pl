my $prelinkage = shift;
my $postlinkage = shift;
my $length_threshhold = shift;
my $outdir = shift;

$outdir ||= ".";
(-d "$outdir") || `mkdir -p $outdir`;

my ($AdjRand1, $AdjRand2);
open F, $prelinkage;
<F>;
my $AdjRand1 = (split/\s+/,<F>)[-1];
close F;

open F, $postlinkage;
<F>;
my $AdjRand2 = (split/\s+/,<F>)[-1];
close F;

my $cmd;
($AdjRand1 >= $AdjRand2) ? 
($cmd .= "ln -s $prelinkage $outdir/TaxValidate.eval.xls\nln -s $outdir/step1.concoct_binning/clustering_gt$length_threshhold.csv $outdir/clustering_gt$length_threshhold.csv\nln -s $outdir/step2.concoct.taxAnno_eval/clustering_gt$length_threshhold\_conf.csv $outdir/clustering_gt$length_threshhold\_conf.csv\n") : 
($cmd .= "ln -s $postlinkage $outdir/TaxValidate.eval.xls\nln -s $outdir/step3.concoct.clusterLinkage_eval/clustering_gt$length_threshhold\_l.csv $outdir/clustering_gt$length_threshhold.csv\nln -s $outdir/step3.concoct.clusterLinkage_eval/clustering_gt$length_threshhold\_conf.csv $outdir/clustering_gt$length_threshhold\_conf.csv\n");
system("$cmd");
