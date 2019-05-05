#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my %opt = (cpu=>3,lisdir=>'.');
GetOptions(
    \%opt,"Ngapl:i","scafl:i","contl:i","linel:i","random","scaftig:s","ass_stat",
    "organism:s","tax_id:i","assembly_name:s","tax_list:s","cpu:i","lisdir:s","id_prefix:s"
);
(@ARGV==3) || die"Name: WGS_uplod_Seq.pl
Version: 1.0	date: 2011-7-7
Description: script to deal the barbarism assemble fasta to fit NCBI criterion
Author:
  Wenbin Liu, liuwenbin\@genomics.org.cn
Version: 1.1
Last modify: 2012-4-12 (to fit agp-version 2.0)
Usage: perl WGS_uplod_Seq.pl <infa.lst>  <out.ncbi.fa.lst> <out.agp.lst> [-options]
  infa.lst <file>    input assembly fasta file, gz s allowed, form: sample_name pathway
  -Ngapl <num>       Ngap length cutoff, default=10
  -contl <num>       contig within scaffold leng cutoff, default=50
  -scafl <num>       alone contig or scaffold leng cutoff, default=200
  -linel <num>       sequence leng per line, default=60
  -scaftig <file>    outfile scaftig, default not out
  -random            output sequence in random turn, default natural ordering
  -id_prefix <str>   set id prefix and rename scaffold name, default not set
  -ass_stat          to stat assembly result, default not stat.
  -lisdir <dir>      set lisdir to output assembly stat result, default=./
  -cpu <num>         default=3
  About AGP head info:
  -organism <str>       species name, default=' '
  -tax_id <num>         TAX_ID, default=' '
  -assembly_name <str>  ASSEMBLY NAME, default=' '
  -tax_list <file>      file list: sample_name\ttax_id\torganism
  \n";
#==========================================================================================
foreach('WGS_uplod_Seq.pl','ass_stat.pl'){(-s "$Bin/$_") || die"error: can't find file $_, at $Bin,$!";}
my $wgs_up = "$Bin/WGS_uplod_Seq.pl";
my $ass_stat = "$Bin/ass_stat.pl";
foreach(@ARGV){(-s $_) || die"error: can't find file $_, $!";}
my ($infa,$out_ncbi,$out_agp) = @ARGV;
my $opts = $opt{random} ? " --random" : " ";
foreach(qw(Ngapl contl scafl linel organism tax_id assembly_name id_prefix)){
    $opt{$_} && ($opts .= " --$_ $opt{$_}");
}
my %out_ncbih = split/[\s=]+/,`less $out_ncbi`;
my %out_agph = split/[\s=]+/,`less $out_agp`;
my (%taxh,%scaftigh);
($opt{scaftig} && -s $opt{scaftig}) && (%scaftigh = split/[\s=]+/,`less $opt{scaftig}`);
if($opt{tax_list} && -s $opt{tax_list}){
    open IN,$opt{tax_list} || die$!;
    foreach(<IN>){
        chomp;
        my @l = (split/\s+/,$_,3);
        $taxh{$l[0]} = [@l[1,2]];
    }
    close IN;
}
#$SIG{CHLD} = "IGNORE";
my $i = 0;
my @ass;
open IN,$infa || die$!;
foreach(<IN>){
    $i++;
    chomp;
    my @l = split/[\s=]+/;
    ($l[1]=~/^(.+)\//) || next;
    my $dir = $1;
    if(fork()){
        push @ass,[$l[0],"$dir/ass_stat.tab.ncbi"];
        ($i>$opt{cpu}) && ($i=0, wait);
    }else{
        my $opt0 = " -assembly_name $l[0]";
        $scaftigh{$l[0]} && ($opt0 .= " -scaftig $scaftigh{$l[0]}");
        $taxh{$l[0]} && ($opt0 .= " -tax_id $taxh{$l[0]}->[0] -organism \"$taxh{$l[0]}->[1]\"");
        system"perl $wgs_up $l[1] > $out_ncbih{$l[0]} 2> $out_agph{$l[0]} $opt0 $opts";
        $opt{ass_stat} && system"perl $ass_stat $out_ncbih{$l[0]} -m > $dir/ass_stat.tab.ncbi";
        exit;
    }
}
close IN;
while (wait != -1) { sleep 1; }
$opt{ass_stat} || exit;
(-d $opt{lisdir}) || mkdir($opt{lisdir});
mege_stat(\@ass,"$opt{lisdir}/scaff_stat.ncbi.tab","$opt{lisdir}/contig_stat.ncbi.tab");
#sub5
#=============
sub mege_stat{
    my ($dir,$soutf,$coutf) = @_;
    my @outf;
    my @title = ("Sample_name\tTotal Num\tTotal Length(bp)\tN50 Length(bp)\tN90 Length(bp)\tMax Length(bp)\tMin Length(bp)\tSequence GC%\n",
            "Sample_name\tTotal Num(>500bp)\tTotal Length(bp)\tN50 Length(bp)\tN90 Length(bp)\tMax Length(bp)\tMin Length(bp)\tSequence GC%\n");
    my @sample;
    foreach my $d(@$dir){
        my ($name,$stat_file) = @{$d};
        if(!(-s $stat_file)){
            print STDERR "have no stat result at $stat_file, $!\n";
            next;
        }
        open ST,$stat_file || die$!;
        my @out = ($name, $name, $name, $name);
        push @sample,$name;
        my $start = 0;
        while(<ST>){
            /^\s/ && next;
            /Total Num\(>500bp\)/ && ($start = 1);
            chomp;
            my @l = split/\t/;
            if($start){
                foreach my $i(2,3){$out[$i] .= "\t".$l[$i-1];}
            }else{
                foreach my $i(0,1){$out[$i] .= "\t".$l[$i+1];}
            }
        }
        close ST;
        foreach(0..3){$outf[$_] .= $out[$_] . "\n";}
    }
    open SF,">$soutf" || die$!;
    print SF $title[0],$outf[0],"\n",$title[1],$outf[2];
    close SF;
    open CF,">$coutf" || die$!;
    print CF $title[0],$outf[1],"\n",$title[1],$outf[3];
    close CF;
    @sample;
}
