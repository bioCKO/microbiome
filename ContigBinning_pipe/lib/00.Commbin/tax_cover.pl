#!/usr/bin/perl -w
@ARGV || die"usage: perl $0 <blast.m8.tax> [in.fa] > out.stat\n";
my ($tax,$fa) = @ARGV;
my %cover;
my $size = gsize($fa);
open IN,$tax || die$!;
while(<IN>){
    chomp;
    my @l = (split /\t/,$_,13)[0,6,7,-1];
    push @{$cover{$l[-1]}{$l[0]}},[@l[1,2]];
}
close IN;
my @out;
foreach my $i(keys %cover){
    my $scaf_num = 0;
    my $cover_len = 0;
    foreach my $j (keys %{$cover{$i}}){
        $scaf_num++;
        my ($s, $e);
        foreach my $p( sort {$a->[0]<=>$b->[1]} @{$cover{$i}{$j}} ){
            if(!$e){
                ($s, $e) = @{$p};
            }elsif($e < $p->[0]-1){
                $cover_len += $e - $s +1;
                ($s, $e) = @{$p};
            }elsif($p->[1] > $e){
                $e = $p->[1];
            }
        }
        delete $cover{$i}{$j};
        $cover_len += $e - $s + 1;
    }
    my @cov = ($i,$scaf_num,$cover_len);
    $size && (push @cov,sprintf("%.2f",100*$cover_len/$size));
    push @out,[@cov];
}
@out || exit;
print "TaxID\tOrganism\t#CoverScaf\tCover_Len(bp)",($size ? "\tGenomics(%)\n" : "\n");
foreach (sort {$b->[2] <=> $a->[2]} @out){
    print join("\t",@{$_}),"\n";
}
sub gsize{
    my $fa = shift;
    ($fa && -s $fa) || return(0);
    my $gsize = 0;
    open FA,$fa || die$!;
    $/=">";<FA>;
    while(<FA>){
        s/^.+?\n|\s|>//g;
        $gsize += length;
    }
    close FA;
    $/="\n";
    $gsize;
}

