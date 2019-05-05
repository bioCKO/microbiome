#!/usr/bin/perl
use strict;
use FindBin qw($Bin);

my $binslist = shift;
my $covlist = shift;
my %bin2fa;
open F, $binslist;
while(<F>){
    chomp;
    my ($index, $fa) = split/\s+/,$_;
    $bin2fa{$index} = $fa;
}close F;

my %bin2cov;
open F, $covlist;
my $head = <F>; chomp($head); my @head = split/\s+/,$head; 
while(<F>){
    chomp;
    my ($scafid, $len, @cov) = split/\s+/,$_;
    $scafid =~ s/;size=1;//g;
    push @{$bin2cov{$scafid}}, ($len, @cov);
}
close F;

my %bin2dep;
foreach my $bin(keys %bin2fa){
    my (%sample2totalLen, %sample2totaldep);
    my @avg_dep;
    for(`less $bin2fa{$bin}`){
        if(/>/){
            chomp;
            my $id = $_; $id =~ s/>//g; $id =~ s/;size=1;//g;
            if(exists $bin2cov{$id}){
                my ($len,@cov) = @{$bin2cov{$id}}; 
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
print "BinID\t".join("\t",@head)."\ttotal_avgDepth\tmaxCov_SampleID"."\n";
foreach my $binId(keys %bin2dep){
    my @cov = @{$bin2dep{$binId}};
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
    print "$binId\t".join("\t",@{$bin2dep{$binId}})."\t$maxCov_sample\n";
}


    
        
