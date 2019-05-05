#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt= (rank=>"1,3,4,5",cluster_range=>"0.001,0.05",cover_cut=>0.5,outfile=>"referance.nt.fa",
        outdir=>".",prefix=>"seq",add_num=>0);
GetOptions(\%opt,"rank:s","cluster_range:s","cover_cut:f","prefix:s","select:s","outfile:s",
        "cut_num:i","outdir:s","cov_info:s","add_num:i","seq_lim:f");
(@ARGV==2) || die "Name: extract_seq.pl
Description: script to extract enthetic sequence from assembly result wiht GC-depth info
Connect: liuwenbin, liuwenbin\@genomics.org.cn
Version: 1.0  Data: 2011-12-28
Usage: perl extract_seq.pl <GC_depth.node.cluster> <refreance.fa> [-options]
    --rank <str>           the ranks of: seq_id GC% Depth [cluster_num], star form 0, defalt=1,3,4,5
    --select <str>         conditions to select enthetic sequence write in awk form, e.g: --select '\$4>60 && \$5>300'
                           means select GC%>60% and Depth>300X region, default select according to cluster_num.
    --cluster_range <str>  cluster_num frequence range see the cluster as enthetic, default=0.001,0,01
    --cover_cut <flo>      sequence enthetic coverage cutoff to selected out, defaut=0.5
    --outfile <file>       set name of output sequence file, default=sequence.nt.fa
    --cut_num <num>        cut the outfile into cut_num subfile, default not cut
    --prefix <str>         set subfile prefix, defualt=seq
    --outdir <dir>         subfile output directory, default=./
    --cov_info <file>      output cover information to set file
    --add_num <num>        add num main scaffold to outseq file
    --seq_lim <flo>        limit the size of add scaffold(Kb), default the whold sequence\n\n";
#=====================================================================================================================
my ($node,$ref) = @ARGV;
my @sel = split/,/,$opt{rank};
my (%toal,%wind,%seq_sel,%clu);
my @clu_range = split/,/,$opt{cluster_range};
$opt{cov_info} && (open COV,">$opt{cov_info}" || die"$!");
if($opt{select}){
    open IN,"awk '($opt{select})' $node |" || die"$!\n";
    while(<IN>){
        my $l = (split)[$sel[0]];
        $wind{$l}++;
    }
    close IN;
    open IN, $node || die"$!\n";
    while(<IN>){
        my $l = (split)[$sel[0]];
        $toal{$l}++;
    }
    close IN;
    foreach(sort keys %wind){
        my $seq_cover = $wind{$_} / $toal{$_};
        $opt{cov_info} && (print COV join("\t",$_,$wind{$_},$toal{$_},$seq_cover)."\n");
        ($seq_cover > $opt{cover_cut}) && ($seq_sel{$_} = 1);
    }
}else{
    my $windn = 0;
    open IN,$node || die$!;
    my $head = <IN>;
    ($head =~ /^V1\s+V2/) || seek(IN,0,0);
    while(<IN>){
        my @l = (split)[@sel];
        $toal{$l[0]}++;
        ${$wind{$l[0]}}{$l[3]}++;
        $clu{$l[3]}++;
        $windn++;
    }
    close IN;
    my @sel_clu;
    foreach(sort {$a<=>$b} keys %clu){
        my $clu_rate = $clu{$_}/$windn;
        $opt{cov_info} && (print COV join("\t",$_,$clu{$_},$windn,$clu_rate)."\n");
        ($clu_rate > $clu_range[0] && $clu_rate < $clu_range[1]) && (push @sel_clu,$_);
    }
    if(!@sel_clu && !$opt{add_num}){
       die "Note: can't find enthetic sequence\n";
    }
    foreach my $i( sort {$a<=>$b} @sel_clu){
        foreach my $id( sort keys %toal){
            ${$wind{$id}}{$i} || next;
            $seq_sel{$id} && next;
            my $seq_cover = ${$wind{$id}}{$i} / $toal{$id};
            $opt{cov_info} && (print COV join("\t",$i,$id,${$wind{$id}}{$i},$toal{$id},$seq_cover)."\n");
            ($seq_cover > $opt{cover_cut}) && ($seq_sel{$id} = 1);
        }
    }
}
$opt{cov_info} && close(COV);
if(!%seq_sel && !$opt{add_num}){
    die "Note: can't find enthetic sequence\n";
}
#=====================================================================================================================
open FA,$ref || die"$!\n";
open OUT,">$opt{outfile}" || die"$!\n";
$/=">";<FA>;$/="\n";
my ($seq_num,$add_num) = (0, 0);
$opt{seq_lim} && ($opt{seq_lim} *= 1000);
while(<FA>){
    my $id = (split)[0];
    $/=">";
    chomp(my $seq = <FA>);
    $/="\n";
    if(!$seq_sel{$id}){
        $add_num++;
        ($add_num > $opt{add_num}) && next;
        print STDERR "$id\n";
        if($opt{seq_lim}){
            $seq =~ s/\s//g;
            (length($seq) > $opt{seq_lim}) && ($seq = substr($seq,0,$opt{seq_lim}));
            $seq .= "\n";
        }
    }
    print OUT ">$id\n",$seq;
    $seq_num++;
}
close OUT;
if($opt{cut_num} && $seq_num){
    my $cut_num = ($seq_num > $opt{cut_num}) ? $opt{cut_num} : $seq_num;
    (-d $opt{outdir}) || mkdir($opt{outdir});
    if($cut_num == 1){
        `ln -s $opt{outfile} $opt{outdir}`;
        exit;
    }
    my @out;
    my ($n,$m) = (0,0);
    open IN,$opt{outfile} || die"$!\n";
    $/=">";<IN>;
    while(<IN>){
        chomp;
        $out[$n] .= ">".$_;
        $m ? ($n--) : ($n++);
        ($n==$cut_num) && ($n = $cut_num-1,$m=1);
        ($n<0) && ($m = 0, $n=0)
    }
    $/="\n";
    close IN;
    foreach(1..$cut_num){
        open OUT,">$opt{outdir}/$opt{prefix}\_$_.fa";
        print OUT $out[$_-1];
        close OUT;
    }
}
#=====================================================================================================================
