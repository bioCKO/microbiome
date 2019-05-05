my @files = glob "/TJPROJ1/MICRO/lindan/DevelopResearch/ContigBinning/Pipeline/Step3.Concoct/reads/*";

my %sample2path;
foreach(@files){
    my $sampleID = (split/\//,$_)[-1];
    $sampleID =~ s/_R[12]\.fa//g;
    push @{$sample2path{$sampleID}}, $_; 
} 
foreach my $key (sort keys %sample2path){
    my @sub_fqs = @{$sample2path{$key}};
    print "$key\t$sub_fqs[0],$sub_fqs[1]\n";
}
