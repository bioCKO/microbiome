#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt = (tax_cover=>"Tax_cover.stat.xls");
GetOptions(\%opt,"organism:s","spe_cover:s","scaff:s","main:s","samp_name:s","len:s","tax_cover:s");
@ARGV || die"usage: perl $0 blast.m8.tax > scaffold_best_cover.stat.xls
    --organism <str>    the main original main species name
    --scaff <str>       the scaffold beyond to main
    --samp_name <str>   set the sample name, default not set
    --main  <str>       output the main original main tax_id and species name
    --tax_cover <file>  set tax-organism cover stat result file name, default=Tax_cover.stat.xls
    --spe_cover <file>  set file name and output species cover stat result, defalt not output
    --len <file>        input scaffold length file to add coverage(%) at eatch stat table\n";
#scaffold20      gi|7243313|gb|AF133308.1|AF133308       99.66   596     2       0       1       596     53      648     0.0 1166     141904  Vibrio phage
my (%scaff,%count,%cover,%lenh);
my $gsize = get_len($opt{len},\%lenh);
while(<>){
    chomp;
    my @l = split/\t/;
    my $tax = "$l[-2]\t$l[-1]";
    ($l[6] > $l[7]) && (@l[6,7] = @l[7,6]);
    push @{$scaff{$l[0]}{$tax}},[@l[6,7]];
}
my $organism;
if($opt{scaff}){
    my %scov;
    my @scaf = (-f $opt{scaff}) ? 
        split/\s+/,`less $opt{scaff}` :  split/,/,$opt{scaff};
    foreach my $i(@scaf){
        my @c  = max_cover($scaff{$i});
        @c || next;
        $scov{$c[3]} += $c[2];
        delete $scaff{$i};
    }
    my $len = 0;
    foreach(keys %scov){
        ($scov{$_} > $len) && (($len,$organism) = ($scov{$_}, $_));
    }
    $organism && ($opt{organism} = (split/\t/,$organism)[1]);
}
my $head = "Scaffold_ID\tStart\tEnd\tCover_Len";
($opt{len} && -s $opt{len}) && ($head .= "\tScaffold_Len\tCoverage(%)");
$head .= "\tTax_ID\tOrganism\n";
$opt{samp_name} && ($head = "Sample_Name\t" . $head);
print $head;
my %tax_lenh;
foreach my $i(sort keys %scaff){
    my @cov = max_cover($scaff{$i});
    if($opt{organism}){
        my $spe = (split/\t/,$cov[3])[1];
        ($opt{organism} eq $spe) && next;
    }
    push @{$count{$cov[3]}},$i;
    $cover{$cov[3]} += $cov[2];
    if($lenh{$i}){
        splice(@cov,3,0, sprintf("%d\t%.2f",$lenh{$i},100*$cov[2]/$lenh{$i}));
        $tax_lenh{$cov[-1]} += $lenh{$i};
    }
    unshift @cov,$i;
    $opt{samp_name} && (unshift @cov,$opt{samp_name});
    print join("\t",@cov),"\n";
}
open OUT,">$opt{tax_cover}" || die$!;
$head = "TaxID\tOrganism\tCover_Len(bp)";
($opt{len} && -s $opt{len}) && ($head .= "\tScaffolds_Len\tCoverage(%)\tGenomics(%)");
$head .= "\tScaffold_Num\tScaffolds_Name\n";
$opt{samp_name} && ($head = "Sample_Name\t" . $head);
print OUT $head;
my (%spe_lenh, %spe_count);
foreach my $k (sort {$cover{$b} <=> $cover{$a}} keys %cover){
    $organism ||= $k;
    my @out = ($k, $cover{$k});
    my $spe = (split/\t/,$k)[1];
    if($tax_lenh{$k}){
       push @out, sprintf("%d\t%.2f\t%.2f",$tax_lenh{$k},100*$cover{$k}/$tax_lenh{$k},100*$tax_lenh{$k}/$gsize);
       $opt{spe_cover} && ($spe_lenh{$spe} += $tax_lenh{$k});
    }
    if($opt{spe_cover}){
        $cover{$spe} += $cover{$k};
        push @{$spe_count{$spe}},@{$count{$k}};
    }
    push @out,( $#{$count{$k}}+1, join(",",@{$count{$k}}));
    $opt{samp_name} && (unshift @out,$opt{samp_name});
    print OUT join("\t",@out),"\n";
    delete $cover{$k};
}
close OUT;
$opt{main} && `echo $organism > $opt{main}`;
$opt{spe_cover} || exit;
open OUT, ">$opt{spe_cover}" || die$!;
$head =~ s/TaxID\t//;
print OUT $head;
foreach my $k (sort {$cover{$b} <=> $cover{$a}} keys %cover){
    my @out = ($k, $cover{$k});
    $spe_lenh{$k} && (push @out, sprintf("%d\t%.2f\t%.2f",$spe_lenh{$k},100*$cover{$k}/$spe_lenh{$k},100*$spe_lenh{$k}/$gsize));
    push @out,( $#{$spe_count{$k}}+1, join(",",@{$spe_count{$k}}));
    $opt{samp_name} && (unshift @out,$opt{samp_name});
    print OUT join("\t",@out),"\n";
}
close OUT;
#=================================================================================
sub max_cover{
    my $scaffh = shift;
    my @cov;
    foreach my $j(keys %{$scaffh}){
        my @c  = cover($scaffh->{$j},$j);
        (!$cov[2] || $c[2] > $cov[2]) && (@cov = @c);
    }
    @cov;
}
sub cover{
    my ($arr,$spe) = @_;
    my @in = sort {$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]} @{$arr};
    my ($len, $s, $e) = (-1, 0, 0);
    my $max = 0;
    foreach(@in){
        if(!$e || $_->[0]>$e+1){
            $len += $e - $s + 1;
            ($s, $e) = @{$_};
        }else{
            ($_->[1] > $e) && ($e = $_->[1]);
        }
        ($e > $max) && ($max = $e);
    }
    $len += $e - $s + 1;
    ($in[0]->[0],$max,$len,$spe);
}
sub get_len{
    my ($lenf,$lenh) = @_;
    ($lenf && -s $lenf) || return(0);
    my $gsize = 0;
    if(`head -1 $lenf` =~ />\S+/){
        open FA,$lenf || die$!;
        $/=">";<FA>;
        while(<FA>){
            /(\S+)/ || next;
            my $id = $1;
            s/^.+?\n|\s|>//g;
            $gsize += ($lenh->{$id} = length);
        }
        $/="\n";
        close FA;
    }else{
        foreach(`less $lenf`){
            my @l = split;
            $lenh->{$l[0]} = $l[1];
            $gsize += $l[1];
        }
#        %{$lenh} = split/\s+/,`awk '{print \$1,\$2}' $lenf`;
    }
    $gsize;
}
