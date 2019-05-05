my $scg_list = shift;
open F, $scg_list;
<F>;
my %clu2scaf;
while(<F>){
    my ($clu_index,$scaf_list,$scaf_num) = (split/\t/,$_)[0..2]; 
    my @scafids = split/\|/,$scaf_list;
    foreach(@scafids){ 
        $clu2scaf{$clu_index}{$_} = 1;
    }
}close F; 

my @clusters = keys %clu2scaf;
my $outdir = shift;
my $allcontigs = shift;
open O, ">$outdir/bins.list";
foreach(@clusters){
#my @a = keys %{$clu2scaf{$_}};
    my $cluster = $_;
    `mkdir -p $outdir/$cluster`;
    open BIN, ">$outdir/$cluster/$cluster.fa";
    open F, $allcontigs;
    $/ = "\n>";
    while(defined($seq=<F>)){
        chomp $seq;
        $seq=~s/^>//; 
        my $id=$1 if $seq=~/^(\S+)/;
        $seq=~s/^.*//;
        $seq=~s/\s+//g;
        if($clu2scaf{$cluster}{$id}){
            $seq = &seqformat($seq);
            print BIN ">$id\n$seq";
        }
    }
    close F;close BIN;
    print O "$cluster\t$outdir/$cluster/$cluster.fa\n";
}
close O;

sub seqformat() {
    my ($seq) = @_;
    $seq =~ s/(.{1,100})/$1\n/g;
    chomp $seq;
    return $seq;
}
