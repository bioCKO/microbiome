my $checkm = shift;
my $indir = shift;
my $outdir = shift;
open F, $checkm;
<F>;
my $head = <F>;
<F>;
open O,">substantial.CheckM.txt";
print O "$head";
my %chooseBins;
while(<F>){
    chomp;
    my @a = split/\s+/,$_;
    my $index = $a[0];
    $chooseBins{$index} = 1;
    my $completeness = $a[13];#13:Completeness; 14:Contamination
    my $contamination = $a[14];
    if($completeness>=70 && $contamination<=10){
        print O "$_\n";
    }
}close F;close O;

mkdir "$outdir";
foreach my $index(keys %chooseBins){ 
    `ln -s $indir/$index.fa $outdir/`;
}
