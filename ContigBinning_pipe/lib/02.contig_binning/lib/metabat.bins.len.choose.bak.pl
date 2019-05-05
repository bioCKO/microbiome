my $minSize = shift;
my $maxSize = shift;
my $indir = shift;
my $outdir = shift;
for(`ls -lh $indir/*fa`){
    chomp;
    my $fa = (split/\s+/,$_)[-1];
    my $fa_len;
    my %id2len; my $id;
    for(`less $fa`){
        chomp;
        if(/>(.+)/){
            $id=$1;
        }else{
            $id2len{$id} .= $_;
        }
    }
    foreach $id (keys %id2len){
        my $len = length $id2len{$id};
        $fa_len += $len;
    }
    if($fa_len >= $minSize && $fa_len <= $maxSize){
        `ln -s $fa $outdir`;
    }
}

