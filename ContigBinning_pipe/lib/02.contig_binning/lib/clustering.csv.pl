my $dir = shift;
my @bins = glob"$dir/*fa";
foreach(@bins){
    my $fa = $_;
    my $index = (split/\//,$fa)[-1];
    $index =~ s/\.fa//g;
    for(`less $fa`){
        chomp;
        if(/>/){
            my $scafid = $_;
            $scafid =~ s/>//g;
            print "$scafid,$index\n";
        }
    }
}
