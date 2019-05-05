#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my %opt;
GetOptions(\%opt,"ahsnp:s","bhsnp:s");
@ARGV || die"usage: perl $0 <A.hsnp> <B.hsnp> <A_B.axt> > out.list
    -ahsnp <file>   input all A snp depth
    -bhsnp <file>   input all B snp depth\n";
my (%ahsnp,%bhsnp,%all_ahsnp,%all_bhsnp);
get_hsnp(\%all_ahsnp,$opt{ahsnp});#sub1
get_hsnp(\%all_bhsnp,$opt{bhsnp});#sub1
get_hsnp(\%ahsnp,shift);#sub1
get_hsnp(\%bhsnp,shift);#sub1
my $axtf = shift;
if($axtf eq 'same' && ! (-s $axtf)){
    same_hsnp(\%ahsnp,\%bhsnp,\%all_bhsnp);#sub4
    same_hsnp(\%bhsnp,0,\%all_ahsnp,1);#sub4
}else{
open AXT,$axtf || die$!;
$/="\n\n";
while(<AXT>){
    chomp;
    my ($h,$aseq,$bseq) = (split/\n/)[-3,-2,-1];
    my @p = split/\s+/,$h;
    ($ahsnp{$p[1]} || $bhsnp{$p[4]}) || next;
    my (%apos,%bpos,@agap,@bgap);
    get_pos($ahsnp{$p[1]},\%apos,@p[2,3]);#sub4
    get_pos($bhsnp{$p[4]},\%bpos,@p[5,6]);#sub4
    (%apos || %bpos) || next;
    gap_array(\@agap,\$aseq);#sub2
    gap_array(\@bgap,\$bseq);#sub2
    my $end = ($p[7] eq '-') ? $p[6] : 0;
    my $stand = $end ? '-' : '+';
    real_fill_pos(\%apos,$p[2],0,$p[5],$end,\@agap,\@bgap);#sub3
    while (my ($p,$q) = each %apos){
        my $bout = '-';
        if($bpos{$q}){
            $bout = $bhsnp{$p[4]}->{$q};
            delete $bpos{$q};
            delete ${$bhsnp{$p[4]}}{$q};
        }elsif(${$all_bhsnp{$p[4]}}{$q}){
            $bout = ${$all_bhsnp{$p[4]}}{$q};
        }
        print join("\t",$p[1],$p,$ahsnp{$p[1]}->{$p},$p[4],$q,$bout,$stand),"\n";
        delete ${$ahsnp{$p[1]}}{$p};
        delete $apos{$p};
    }
    real_fill_pos(\%bpos,$p[5],$end,$p[2],0,\@agap,\@bgap);#sub4
    while (my ($p,$q) = each %bpos){
        my $aout = '-';
        if($apos{$q}){
            $aout = ${$ahsnp{$p[1]}}{$q};
            delete ${$ahsnp{$p[1]}}{$q};
        }elsif(${$all_ahsnp{$p[1]}}{$q}){
            $aout = ${$all_ahsnp{$p[1]}}{$q};
        }
        print join("\t",$p[1],$q,$aout,$p[4],$p,${$bhsnp{$p[4]}}{$p},$stand),"\n";
        delete ${$bhsnp{$p[4]}}{$p};
    }
}
close AXT;
$/="\n";
}
for my $id (keys %ahsnp){
    while(my ($p,$q) = each %{$ahsnp{$id}}){
        print join("\t",$id,$p,$q,qw(- - -)),"\n";
    }
}
for my $id (keys %bhsnp){
    while(my ($p,$q) = each %{$bhsnp{$id}}){
        print join("\t",qw(- - -),$id,$p,$q),"\n";
    }
}
#sub4
sub same_hsnp{
    my ($ahsnp,$bhsnp,$all_bhsnp,$rev) = @_;
    ($ahsnp && %$ahsnp) || return(0);
    for my $id (keys %{$ahsnp}){
        for my $p (keys %{$ahsnp->{$id}}){
            my $aout = $ahsnp->{$id}->{$p};
            delete ${$ahsnp->{$id}}{$p};
            my $bout = '-';
            if($bhsnp && $bhsnp->{$id} && ${$bhsnp->{$id}}{$p}){
                $bout = ${$bhsnp->{$id}}{$p};
                delete ${$bhsnp->{$id}}{$p};
            }elsif($all_bhsnp->{$id} && ${$all_bhsnp->{$id}}{$p}){
                $bout = ${$all_bhsnp->{$id}}{$p};
            }
            $rev && ( ($aout,$bout) = ($bout,$aout));
            print join("\t",$id,$p,$aout,$id,$p,$bout,"+\n");
        }
    }
}

#sub1
#============
sub get_hsnp{
#============
    my ($hash,$file) = @_;
    ($file && -s $file) || return(0);
    open IN,$file || die$!;
    while(<IN>){
        chomp;
        my @l = (split/\t+/)[0..2];
        $hash->{$l[0]}->{$l[1]} = $l[2];
    }
    close IN;
}
#sub2
#===========
sub get_pos{
#===========
    my ($hash,$pos,$star,$end) = @_;
    ($hash && %{$hash}) || return(0);
    for my $p(keys %{$hash}){
        ($star < $p || $p > $end) && next;
        $pos->{$p} = 0;
    }
}
#sub3
#================
sub real_fill_pos
#================
{
    my ($real_pos,$star,$end,$star2,$end2,$gap1,$gap2) = @_;
    ($real_pos && %$real_pos) || return(0);
    foreach my $p( keys %{$real_pos}){
        my $q = pos_change($gap1,$p,$star,$end);#sub3.1
        $q = pos_change($gap2,$q,$star2,$end2,1);#sub3.1
        $real_pos->{$p}=$q;
    }
}
#sub2
#=============
sub gap_array
#=============
{
    my ($tar_gap,$tar_seq) = @_;
    ($$tar_seq =~/-/) || return(0);
    my ($real,$dis) = (0, 0);
    push @{$tar_gap},[$real,$dis];
    if($$tar_seq =~ /^(-+)/){
        $dis = length $1;
        $$tar_seq =~ s/^-+//g;
        push @{$tar_gap},[$real,$dis];
    }
        ($$tar_seq =~/-/) || return(0);
    my @m = ($$tar_seq =~ m/([^-]+)(-+)/g);
    foreach(0..$#m/2){
        my ($n, $g) = splice(@m,0,2);
        $n = length $n;
        $g = length $g;
        $real += $n;
        $dis += $n+$g;
        push @{$tar_gap},[$real,$dis];
    }
}
#sub3.1
#==============
sub pos_change
#==============
{
    my ($db,$que,$star,$end,$type) = @_;
    $type ||= 0;# 1:fill->real, 0:real->fill
    my ($s, $e, $l, $s2, $e2);
    if($star=~/,/){
        ($s, $e) = split/,/,$star;
        $star = $s;
        $l = $e - $s + 1;
        if($end){
           ($s2, $e2) = split/,/,$end;
           $end = $e2;
        }
    }
    if($type){
        $que++;
    }else{
        if($end){
            $que = ($e2 && $que>$e2) ? $e-$que+$e2+1 : $end - $que+1;
        }else{
            $que = ($s && $que<$s) ? $que+$l : $que-$star+1;
        }
    }
    my $out;
    if($db && @$db){
        my $i = 0;
        foreach(0..$#$db){
            ($db->[$_]->[$type] > $que) && last;
            $i = $_;
        }
        $out = $db->[$i]->[1-$type] + $que - $db->[$i]->[$type];
        if($type && $db->[$i+1] && $out > $db->[$i+1]->[0]){
            $out = $db->[$i+1]->[0] - 1;
        }
    }else{
        $out = $que;
    }
    if($type){
        if($e2 && $out >= $e2){
            $out = $e-($out-$e2+1);
        }elsif($end){
            $out = $end - $out+1;
        }elsif($s && $out > $l){
            $out -= $l;
        }else{
            $out += $star-1;
        }
    }
    $out;
}
