use File::Basename;
use Math::Round;

my $cov_table = shift;
my $bin_dir = shift;
(-s $cov_table && -d $bin_dir) || die"<coverage table> and <bins dir> must be input!\n";

my %contig2info;
open F, "$cov_table";
<F>;
while(<F>){
    chomp;
    my ($contigID, $contigLen,@cov) = split/\s+/,$_;
    $contigID =~ s/;size=1;//g;
    my $cov = sum(@cov);
    push @{$contig2info{$contigID}}, ($contigLen, $cov);
}close F;

my @bins = glob"$bin_dir/*/*fa";
my %bin2seq;
foreach my $bin(@bins){
    my $binID = basename($bin); $binID =~ s/\.fa//g;
    my $contigID;
    for(`less $bin`){
        chomp;
        if(/>/){
            $contigID = $_;
            $contigID =~ s/>//g; $contigID =~ s/;size=1;//g;
        }
        else{
            $bin2seq{$binID}{$contigID} .= $_;
        }
    }
}

print "BinID\tContigID\tDepth(X)\tGC(%)\tContigLen(bp)\n";
foreach my $binID(keys %bin2seq){
    foreach my $contigID(keys $bin2seq{$binID}){
        my $gc = gc($bin2seq{$binID}{$contigID});
        print "$binID\t$contigID\t${$contig2info{$contigID}}[1]\t$gc\t${$contig2info{$contigID}}[0]\n"; 
    }
}

sub sum{
    my $s;
    foreach(@_){
        $s += $_;
    }
    $s = round($s);
    return $s;
}

sub gc{
    my $seq = shift;
    $seq =~ s/N//ig;
    $seq || return(0);
    my $len = length $seq;
    my $gc = ($seq =~ s/[GC]//ig);
    my $gc = int($gc/$len*10000)/100;
    return $gc;
}

