my $scg_tab = shift;
open O, ">SCG.stat.xls";
print O "BinID\tSCG Number\n";
open F, $scg_tab;
while(<F>){
    chomp;
    if(/COG/){
       print "$_\n";
       next;
    }
    my ($binID, @cogNum) = (split/\s+/,$_)[0,3..38];
    my $cogCount;
    foreach(@cogNum){
        if($_ eq "1"){
            $cogCount += 1;
        }
    }
    if($cogCount >=27){
        print "$_\n";
        print O "$binID\t$cogCount\n";
    }
}
close F;
close O;

