@ARGV >=3 || die"
Usage: <bin list> <all sample assembly list> <single sample assembly list> must be input in the right order, and with the same format: binID\tpath for the sequence 
         ...
NOTE: the binID for each sequence shoule be identical.

#script to choose the Final Assemlby according to the max Scaffold Length of each Bins, each bin assembly from reads mapping from all samples, and each bin assembly from reads mapping from each sample. 
1) If the assembly from the single ‘highest-coverage’ sample was improved or equivalent to the initial assembly (that is, the longest contig in the new assembly representing ≥95% of the longest contig in the initial assembly), this set of contigs was selected as the sequence for this bin.  
2) Otherwise, the ‘all samples’ bin re-assembly was selected if it was equivalent to or better than the initial assembly (longest contig representing ≥95% of the longest initial contig. 
3) Finally, if both re-assemblies yielded a longest contig smaller (<95%) than the one in the initial assembly, the bin was considered to be a false-positive (that is, binning of contigs from multiple genomes, n = 1,356), and contigs from the initial assembly were considered as ‘unbinned’.\n 
";

my $binList = shift;
my $allAssList = shift;
my $singleAssList = shift;
my $outdir = shift; 
$outdir ||= ".";
(-d "$outdir") || (`mkdir $outdir` || die"cannot make $outdir!\n");

my (%bin2MaxScaf, %allAss2MaxScaf, %singleAss2MaxScaf);

%bin2MaxScaf = &getMaxScafInfo($binList);
%allAss2MaxScaf = &getMaxScafInfo($allAssList);
%singleAss2MaxScaf = &getMaxScafInfo($singleAssList);

my $cmd;
(-s "$outdir/draft.assembly.list") && (`rm $outdir/draft.assembly.list`);
(-s "$outdir/deletebin.list") && (`rm $outdir/deletebin.list`);
(-s "$outdir/deletebin.list") && (`rm $outdir/deletebin.list`);
my @keys = keys %bin2MaxScaf;
foreach my $index(keys %bin2MaxScaf){
     my $binScafLen = ${$bin2MaxScaf{$index}}[0];
     if($singleAss2MaxScaf{$index}){ 
       if(${$singleAss2MaxScaf{$index}}[0] >= 0.95*$binScafLen){
       $cmd .= "echo \"$index\t${$singleAss2MaxScaf{$index}}[2]\tOneSample\" >>$outdir/draft.assembly.list;\nmkdir $outdir/$index;ln -s ${$singleAss2MaxScaf{$index}}[2] $outdir/$index;\n";}
       elsif(${$allAss2MaxScaf{$index}}[0] >= 0.95*$binScafLen){ 
       $cmd .= "echo \"$index\t${$allAss2MaxScaf{$index}}[2]\tAllSample\" >>$outdir/draft.assembly.list;\nmkdir $outdir/$index;ln -s ${$allAss2MaxScaf{$index}}[2] $outdir/$index\n";} 
       else{$cmd .= "echo \"$index\t-\tdelete\" >>$outdir/list;\n";}
     }
     else{
       if(${$allAss2MaxScaf{$index}}[0] >= 0.95*$binScafLen){ 
       $cmd .= "echo \"$index\t${$allAss2MaxScaf{$index}}[2]\tAllSample\" >>$outdir/draft.assembly.list;\nmkdir $outdir/$index;ln -s ${$allAss2MaxScaf{$index}}[2] $outdir/$index\n";}
       else
       {$cmd .= "echo \"$index\t-\tdelete\" >>$outdir/list;\n";}
     }
}
print $cmd;
system($cmd);

sub getMaxScafInfo{
    my ($Flist,) = @_;
    my %hash;
    open F, $Flist;
    while(<F>){
        chomp;
        my ($index, $seq) = split/\s+/,$_;
        my ($MaxScaf, $MaxLen) = &getMaxScaf($seq);
        push @{$hash{$index}}, ($MaxLen,$MaxScaf,$seq);
    }
    close F;
    return %hash; 
}

sub getMaxScaf{
    my $maxID;
    my $maxLen = 0;
    my $file = shift;
    open IN,$file or die "Can not open $file $!.";
    $/ = '>';
    <IN>;
    while ( my $seq = <IN> ) {
        my $id = $1 if($seq =~ /^(\S+)/);
        chomp $seq;
        $seq =~ s/^.+?\n//;
        $seq =~ s/\s//g;
        my $len = length($seq);
        if($len >= $maxLen){
            $maxID = $id;
            $maxLen = $len;
        }
    }
    $/="\n";
    close IN;
    return ($maxID,$maxLen);
}
