#!/usr/bin/perl
# Copyright 2010 Lizhi Xu <xulz@genomics.cn>
use strict;
use warnings;
use PerlIO::gzip;
use FindBin qw($Bin);
use Getopt::Long;
my %opt = (windl=> 500, movel => 500);
GetOptions(\%opt, "outdir:s", "windl:i", "movel:i", "gc_range:s","prefix:s","cluster:i");
##=========================================================================================
(@ARGV==2) || die"Name: GC_depth_dis.pl
Description: script to draw GC-depth with sequence file and soap.coverage result.
Version: 1.0,  Date: 2011-12-20
Connect: liuwenbin\@genomics.org
Usage: perl GC_depth_dis.pl <ref.fa> <cover_depf>
    ref.fa              referance fatat file, gzip is allowed
    cover_depf          soap.coveage -depthsingle outfile, gzip is allowed
    --outdir <dir>      outfile directoty, default=./
    --prefix <str>      outfile prefix, default not set
    --windl <num>       windows length, default=500
    --movel <num>       windows move length, default= --windl set
    --gc_range <str>    GC% range show, min:max(e.g 0:100), negative means auto, default='-1,-1'
    --dep_cut <num>     maxdepth to show at the figure, negative means auto, default='-1'
    --cluster <num>     dot clusert number, default=5\n\n";
##=========================================================================================
(-s "$Bin/draw_gedepth_R.pl") || die"error can't find draw_gedepth_R.pl at $Bin, $!\n";
foreach(@ARGV){
    (-s $_ || -s "$_.gz") || die"error: can't find valid file $_, $!\n";
    !(-s $_) && (-s "$_.gz") && ($_ .= ".gz");
}
my ($ref,$covf) = @ARGV;
my @outf = ("GC_depth.pos","GC_depth.pos.pdf","GC_depth.pos.cluster");
$opt{outdir} ||= '.';
(-d $opt{outdir}) || mkdir($opt{outdir});
foreach(@outf){
    $opt{prefix} && ($_ = $opt{prefix} . '.' . $_);
    $_ = $opt{outdir} . '/' . $_;
}
my %gc_hash;
&get_gc_list($ref,$opt{windl},$opt{movel},\%gc_hash);#sub1
my $avg_depth = &get_depth($covf,$opt{windl},$opt{movel},\%gc_hash,$outf[0]);#sub2
my $draw_opt = " ";
$opt{dep_cut}=int($avg_depth*3);
($opt{dep_cut} && $avg_depth > $opt{dep_cut}) && ($opt{dep_cut} = "");
foreach(qw(gc_range dep_cut cluster)){$opt{$_} && ($draw_opt .= " --$_ $opt{$_}");}
system "perl $Bin/draw_gedepth_R.pl @outf[0,1] --clustf $outf[2] $draw_opt";

##=========================================================================================
#sub1
#===============
sub get_gc_list{
#===============
    my ($fasta,$windl,$movel,$gc_hash) = @_;
    ($fasta=~/\.gz$/) ? (open IN,"<:gzip",$fasta || die$!) : (open IN,$fasta || die$!);
    $/=">";<IN>;$/="\n";
    while(<IN>){
        /^(\S+)/ || next;
        my $id = $1;
        $/=">";chomp(my $seq = <IN>);$/="\n";
        $seq =~ s/\s+//g;
        my $len = length($seq);
        ($len < $windl) && next;
        my $j = -1;
        for (my $i = 0; $i <= $len - $windl; $i += $movel){
            $j++;
            my $subseq = substr($seq,$i,$windl);
            my @gl = &get_gc($subseq);#sub1.1
            $gl[1] || next;
            $gc_hash->{"$id $j"} = [@gl];
        }
    }
    close IN;
}
#sub1.1
#==========
sub get_gc{
#==========
	my $seq = shift;
	$seq =~ s/N//ig;
    $seq || return(0,0);
	my $len = length $seq;
	my $gc = ($seq =~ s/[GC]//ig);
    (int($gc/$len*10000)/100, $len);
}
#sub2
#=============
sub get_depth{
#=============
    my ($covf,$windl,$movel,$gc_hash,$outf) = @_;
    my ($ln, $outl) = (0);
    my ($avg_depth, $win_num) = (0, 0);
    open OUT,">$outf" || die $!;
    ($covf=~/\.gz$/) ? (open IN,"<:gzip",$covf || die$!) : (open IN,$covf || die$!);
    $/=">";<IN>;$/="\n";
    while(<IN>){
        /^(\S+)/ || next;
        my $id = $1;
        $/=">";chomp(my $seq_str = <IN>);$/="\n";
        my @seq = split/\s+/,$seq_str;
        my $j = -1;
        for (my $i = 0; $i < $#seq - $windl + 2; $i += $movel){
            $j++;
            $gc_hash->{"$id $j"} || next;
            my @gl = @{$gc_hash->{"$id $j"}};
            my $depth = &sum(@seq[$i..$i+$windl-1]);
            $depth = int(100*$depth/$gl[1])/100;
            $avg_depth += $depth;
            $win_num++;
            $outl .= join("\t",$id,$j,$gl[0],$depth)."\n";
            $ln++;
            ($ln>=30) && ($ln=0,(print OUT $outl),$outl="");
        }
    }
    close IN;
    $ln && (print OUT $outl);
    close OUT;
    $win_num ? int($avg_depth/$win_num+0.5) : 0;
}
#sub2.1
#=======
sub sum{
#=======
    my $sum = 0;
    foreach(@_){$sum+=$_;}
    $sum;
}
