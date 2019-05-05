#!/usr/bin/perl
use strict;
use Cwd qw(abs_path);
use Math::Round;

my $checkm = shift;
my $covlist = shift;
my $indir = shift;
(-s $checkm || die"$checkm does not exist or is empty!") || (-s $covlist || die"$covlist does not exist or is empty!") || (-d $indir || die "$indir does not exist!");
my $outdir = shift;
$outdir ||= ".";
(-d $outdir) || `mkdir -p $outdir`;
$indir =~ s/\/$//g; $outdir =~ s/\/$//g;
$indir = abs_path($indir); $outdir = abs_path($outdir);

open F, $checkm;
<F>;
my $head = <F>;
<F>;
my %chooseBins;
while(<F>){
    chomp;
    my @a = split/\s+/,$_;
    my $index = $a[1]; 
    my $completeness = $a[13];#13:Completeness; 14:Contamination
    my $contamination = $a[14];
    if($completeness>=70 && $contamination<=10){
        push @{$chooseBins{$index}},($completeness,$contamination);
    }
}close F;

my %scaf2cov;
open F, $covlist;
my $head = <F>; chomp($head); my @head = split/\s+/,$head; 
while(<F>){
    chomp;
    my ($scafid, $len, @cov) = split/\s+/,$_;
    $scafid =~ s/;size=1;//g;
    push @{$scaf2cov{$scafid}}, ($len, @cov);
}
close F;

my %bin2dep;
foreach my $bin(keys %chooseBins){
    my (%sample2totalLen, %sample2totaldep);
    my @avg_dep;
    for(`less $indir/$bin.fa`){
        if(/>/){
            chomp;
            my $id = $_; $id =~ s/>//g; $id =~ s/;size=1;//g;
            if(exists $scaf2cov{$id}){
                my ($len,@cov) = @{$scaf2cov{$id}}; 
                foreach(2..$#head){
                    $sample2totalLen{$head[$_]} += $len;
                    $sample2totaldep{$head[$_]} += $len*$cov[$_-2];
                }
            }
        }
        else{next;}
    }
    my $total_dep;
    foreach(2..$#head){
        my $avg_dep = $sample2totaldep{$head[$_]}/$sample2totalLen{$head[$_]};
        $total_dep += $avg_dep;
        push @avg_dep, $avg_dep;
    }
    push @avg_dep, $total_dep;
    @{$bin2dep{$bin}} = @avg_dep;
}


shift @head; shift @head;
open STAT, ">$outdir/../CheckM.substantial_bin.stat.xls";
print STAT "BinID\tBinSize(M)\tCompleteness(%)\tContamination(%)\tTotal Coverage\tMaxCoverage Sample\n";
open BIN, ">$outdir/../bins.list";
foreach my $index (keys %chooseBins){
    my @cov = @{$bin2dep{$index}};
    pop @cov;
    my %cov2sample;
    my $num = 0;
    foreach(@cov){
        push @{$cov2sample{$_}}, $head[$num]; 
        $num++;
    }
    my $maxCov_sample;
    my @sortCov = sort{$b <=> $a} keys %cov2sample;
    $maxCov_sample = join(",",@{$cov2sample{$sortCov[0]}});
    $maxCov_sample =~ s/cov_mean_sample_//g;
    my $totalCov = @{$bin2dep{$index}}[-1];
    $totalCov = round($totalCov*10)/10;
    my $binsize = &BinSize("$indir/$index.fa");
    print STAT "$index\t".$binsize."\t".join("\t",@{$chooseBins{$index}})."\t".$totalCov."\t$maxCov_sample\n";
    `mkdir -p $outdir/$index`;
    if(-s "$outdir/$index/$index.fa"){
        `rm $outdir/$index/$index.fa`;
    }
    open O, ">$outdir/$index/$index.fa";
    open F, "$indir/$index.fa";
    $/ = ">";
    <F>;
    while(<F>){
        chomp;
        my ($id, $seq) = split("\n+", $_, 2);
        $seq=~s/\s+//g;
        my $seq = &seqformat($seq);
        print O ">$id\n$seq";
    }
    close O; 
    print BIN "$index\t$outdir/$index/$index.fa\n";
}
close BIN;
close STAT;

sub BinSize{
    my ($fa,) = @_;
    my $fa_len;
    my $seq;
    for(`less $fa`){
        chomp;
        if(!/>/){
            $seq .= $_;
        }
    }
    $fa_len = length $seq;
    $fa_len = add_comm($fa_len);
    return $fa_len;
}

sub add_comm{
    my $str = reverse $_[0];
    $str =~ s/(...)/$1,/g;
    $str =~ s/,$//;
    $_[0] = reverse $str;
}

sub seqformat(){
    my ($seq,) = @_;
    $seq =~ s/(.{1,100})/$1\n/g;
    chomp $seq;
    return $seq;
}
