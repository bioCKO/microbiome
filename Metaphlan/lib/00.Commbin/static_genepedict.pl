#! /usr/bin/perl
#function: get the statics of gene's stat for each sample's genepredict result
#contact:chenjunru[AT]novogene.con
#date: 2015-06-08

@ARGV == 3 || die "usage: perl $0 <input: genepredict result> <output: stat> <ouput:stat.detail>\n";

my($genepredict,$output,$output_stat)=@ARGV;
my @start=qw(TTG CTG ATT ATC ATA ATG GTG);
my @end=qw(TAA TAG TGA);
open(GENEPREDICT,"$genepredict") || die "error: can't open infile:$genepredict\n";
$/='>';
<GENEPREDICT>;
my($total_len,$total_gc,$total_at,$number,%hash);
open(OUT,">$output_stat");
while (my $seq=<GENEPREDICT>){
    my $id = $1 if($seq=~/^(\S+)/);
    chomp($seq); 
    $seq=~s/^\S+//;
    $seq=~s/\s+//g; 
    $total_len += length($seq); 
    my $GC = ($seq=~tr/GCgc/GCgc/);
    my $AT = ($seq=~tr/ATat/ATat/);
    $total_at += $AT;
    $total_gc += $GC;
    $number++;
    my $start=substr($seq,0,3);
    my $restart=reverse$start;
    $restart=~tr/ATCGatcg/TAGCtagc/;
    my $end=substr($seq,-3,3);
    my $reend=reverse$end;
    $reend=~tr/ATCGatcg/TAGCtagc/;
    print OUT "$id\t$start\t$restart\t$end\t$reend\t";
    if((grep{$start=~/^$_$/i || $reend=~/^$_$/i} @start) && (grep {$end=~/^$_$/i || $restart=~/^$_$/i} @end)){
        $hash{'all'}++;
        print OUT "all\n";
    }elsif( grep {$start=~/^$_$/i || $reend=~/^$_$/i } @start ){
        $hash{'start'}++;
        print OUT "start\n";
    }elsif(grep {$end=~/^$_$/i || $restart=~/^$_$/i} @end){
        $hash{'end'}++;
        print OUT "end\n";
    }else{$hash{'none'}++;print OUT "none\n";}
}
close GENEPREDICT;
close OUT;
$/="\n";

my $gc_len=$total_gc+$total_at;
my $gc_cont = $gc_len ? $total_gc / $gc_len : 0;
my $aver_len = $total_len / $number;
open(OUT,">$output");
$gc_cont *= 100;
$total_len /= 1000000; 
print OUT "ORFs NO.\t".&digitize($number)."\n";
foreach(keys %hash){
    my $precent_intergrity=$hash{$_}/$number;
    my $pre=(sprintf("%.4f",$precent_intergrity))*100;
    print OUT "integrity:$_\t".&digitize($hash{$_})."($pre%)\n";
}
my$total_len_ori=$total_len;
$total_len =~ s/(\.\d\d)\d*/$1/;
$total_len += 0.01 if($total_len_ori=~/(\.\d\d)[56789]\d*/);
my $aver_len_ori=$aver_len;
$aver_len =~ s/(\.\d\d)\d*/$1/;
$aver_len += 0.01 if($aver_len_ori=~/(\.\d\d)[56789]\d*/);
my $gc_cont_ori=$gc_cont;
$gc_cont=~ s/(\.\d\d)\d*/$1/;
$gc_cont += 0.01 if($gc_cont_ori=~/(\.\d\d)[56789]\d*/);
print OUT "Total Len.(Mbp)\t".&digitize($total_len)."\nAverage Len.(bp)\t".&digitize($aver_len)."\nGC percent\t".&digitize($gc_cont)."\n";
close OUT;

sub digitize{
    my $v = shift or return '0';
    $v =~ s/(?<=^\d)(?=(\d\d\d)+$)   #for not contain decimal point
            |
            (?<=^\d\d)(?=(\d\d\d)+$) #for not contain decimal point
            |
            (?<=\d)(?=(\d\d\d)+\.)   #s for integer
            |
            (?<=\.\d\d\d)(?!$)       #s for static after decimal point
            |
            (?<=\G\d\d\d)(?!\.|$)   
            /,/gx;
    return $v;
}
