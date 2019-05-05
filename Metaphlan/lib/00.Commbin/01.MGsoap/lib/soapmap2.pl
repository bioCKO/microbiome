#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
use PerlIO::gzip;
my %opt = (outdir=>".",out=>"tol-se-pe-rp-inv",qual=>15,prefix=>'soap');
GetOptions(\%opt,"max_ins:i","min_ins:i","prefix:s","outdir:s","R","size:s","rank:s","plot:s","RD",
    "out:s","qual:i","onlysnp","uniq");
(@ARGV && (($opt{size} && -s $opt{size}) || ($opt{plot} && -s $opt{plot}))) || die"Name: soapmap.pl
Descirption: script to show PE insert dis, SE/INV/TOL depth dis, SNP depth dis with SOAP2 result.
Version: 1.0,  Date: 2012-08-26
Author: lwb, liuwenbin\@genomics.org.cn
Usage: perl soapmap.pl <soap.lst | soap1,2...>
    soap1,2... <file>       soap result pathway
    soap.lst <file>         soap reasult pathway list
    -outdir <dir>           set outfile directory, default=./
    -prefix <num>           outfile prefix, defuaut=soap
    -out <str>              depth outfile selected, default=tol-se-pe-rp-inv
    -size <file>            input sequence size file or be fasta file, must set for -out
    -max_ins <num>          maximul insertSize, default not set
    -min_ins <num>          minimul insertSize, default not set
    -R                      Lib to be large Lib(>1Kb), default not set
    -RD                     the depth outfile is reads depth, not sequencing depth
    -uniq                   only caculate uniq reads for TOL.depth, default all reads
    -plot <file>            infile list for check SNP: scaf_id pos, default not set
    -rank <str>             the rank of scaf_id pos at plot set, default=0,1
    -qual <num>             quality cutoff for plot snp stat, default=15
Note: 
    1 The input soap result should have the same InsertSize.
    2 Either -size or -plot must be set.\n";
#==============================================================================================
if(@ARGV==1){
    (-s $ARGV[0]) || die"error: can't find able file $ARGV[0], $!";
    chomp(my $head = `head -1 $ARGV[0]`);
    (-f $head) && chomp(@ARGV = `less $ARGV[0]`);
}
#$opt{prefix} ||= (split/\//,$ARGV[0])[-1];
(-d $opt{outdir}) || mkdir($opt{outdir});
my %sizeh;
get_size($opt{size},\%sizeh);
%sizeh || ($opt{out} = 0);
my $Rlen;
my (%pe_depth,%se_depth,%rp_depth,%inv_depth,%tol_depth,%pe_insert,%ploth,%snp);
get_plot($opt{plot},$opt{rank},\%ploth);#sub4
foreach my $f(@ARGV){
    ($f=~/\.gz$/) ? (open(IN,"<:gzip",$f) || die$!) : (open IN,$f || die$!);
    my (@pre,@temp);
    while(<IN>){
        @temp = split;
        (@temp < 12) && next;
        $Rlen ||= length($temp[1]);
        get_snp(@temp[1..3,6..8],$Rlen,$opt{qual},\%ploth,\%snp);#sub5
        $opt{onlysnp} && next;
        @temp = @temp[0,3,5..8];#reads_id rep_num Rlen +/- chr pos
        ($opt{out} =~ m/tol/i && (!$opt{uniq} || $temp[1]==1)) && (${$tol_depth{$temp[4]}}[$temp[5]-1]++);
        ($opt{out} =~ m/se|ps|rp|inv/i) || next;
        $temp[0] =~ s/\/[12]$//;
        if(@pre){
            if($temp[0] ne $pre[0] || $temp[4] ne $pre[4]){
                ($opt{out} =~ m/se/i) && (${$se_depth{$pre[4]}}[$pre[5]-1]++);
                @pre = @temp;
            }else{
                if($temp[1]==1 && $pre[1]==1 && $opt{out} =~ m/pe|inv/i){
                    my $type = ($pre[3] eq '+' && $temp[3] eq '-') ? 0 :
                    ($pre[3] eq '-' && $temp[3] eq '+') ? 1 : 2;
                    $opt{R} && ($type = 1-$type);
                    my ($s, $e, $len) =
                        ($type == 0) ? ($pre[5],$temp[5],$pre[2]) :
                        ($type == 1) ? ($temp[5],$pre[5],$temp[2]) :
                        ($temp[5] < $pre[5]) ? ($temp[5],$pre[5],$temp[2]) : ($pre[5],$temp[5],$pre[2]);
                    my $insert = $e - $s;
                    ($insert < 0) ? ($insert -= $len) : ($insert += $len);
                    if(($opt{min_ins} && $insert < $opt{min_ins}) || ($opt{max_ins} && $insert > $opt{max_ins})){
                        @pre = ();
                        next;
                    }elsif($temp[3] ne $pre[3] && $opt{out} =~ m/pe/i){
                        ${$pe_depth{$pre[4]}}[$s-1]->[0]++;
                        ${$pe_depth{$pre[4]}}[$e-1]->[1]++;
                        ${$pe_insert{$pre[4]}}[$s-1]->[0] += $insert;
                        ${$pe_insert{$pre[4]}}[$e-1]->[1] += $insert;
                    }elsif($opt{out} =~ m/inv/i){
                        ${$inv_depth{$pre[4]}}[$s-1]++;
                        ${$inv_depth{$pre[4]}}[$e-1]++;
                    }
                }elsif($opt{out} =~ m/rp/i){
                    ($temp[1] > 1) && (${$rp_depth{$pre[4]}}[$temp[5]-1]++);
                    ($pre[1] > 1) && (${$rp_depth{$pre[4]}}[$pre[5]-1]++);
                }
                @pre = ();
            }
        }else{
            @pre = @temp;
        }
    }
    close IN;
}
if(%snp){
    my $snp_out;
    foreach my $chr( sort keys %snp){
        foreach my $pos (sort {$a<=>$b} keys %{$snp{$chr}}){
            @{$snp{$chr}->{$pos}} || next;
            foreach my $n(qw(A T C G)){
                foreach my $i(0..3){
                    ($snp{$chr}->{$pos}->[$i]->{$n} ||= 0);
                    $snp{$chr}->{$pos}->[$i]->{N} += $snp{$chr}->{$pos}->[$i]->{$n};
                    ($i%2 && $snp{$chr}->{$pos}->[$i-1]->{$n}) &&
                    ($snp{$chr}->{$pos}->[$i]->{$n} = 
                     int($snp{$chr}->{$pos}->[$i]->{$n}/$snp{$chr}->{$pos}->[$i-1]->{$n}+0.5))
                }
            }
            $snp{$chr}->{$pos}->[0]->{N} && 
                ($snp{$chr}->{$pos}->[1]->{N} = int($snp{$chr}->{$pos}->[1]->{N}/$snp{$chr}->{$pos}->[0]->{N}+0.5));
            $snp{$chr}->{$pos}->[2]->{N} && 
                ($snp{$chr}->{$pos}->[3]->{N} = int($snp{$chr}->{$pos}->[3]->{N}/$snp{$chr}->{$pos}->[2]->{N}+0.5));
            $snp_out .= join("\t",$chr,$pos);
            foreach my $i(0..3){
                $snp_out .= "\t".$snp{$chr}->{$pos}->[$i]->{N};
                foreach my $n(qw(A T C G)){
                    $snp_out .= " ".$snp{$chr}->{$pos}->[$i]->{$n};
                }
            }
            $snp_out .= "\n";
            @{$snp{$chr}->{$pos}} = ();
            delete $snp{$chr}->{$pos};
        }
    }
    if($snp_out){
        open SNP,">$opt{outdir}/$opt{prefix}.SNP.depth" || die$!;
        print SNP "#ChrID\tPos\tN A T C G\tN A T C G\tN A T C G\tN A T C G\n",
              $snp_out;
        close SNP;
        $snp_out = "";
    }
}
$opt{onlysnp} && exit;
($opt{out} =~ m/pe/i) || exit;
foreach(["TOL",\%tol_depth],["SE",\%se_depth],["RP",\%rp_depth],["INV",\%inv_depth]){
    ($opt{out} =~ m/$_->[0]/i) &&
    out_depth("$opt{outdir}/$opt{prefix}.$_->[0].depth",$_->[1],\%sizeh,$opt{RD} ? 0 : $Rlen);#sub2
}
open PE,">$opt{outdir}/$opt{prefix}.PE.depth" || die$!;
open PEI,">$opt{outdir}/$opt{prefix}.PE.insert" || die$!;
foreach my $id(sort {$a cmp $b} keys %sizeh){
    my (@pe,@pei,@inv);
    foreach my $i(0..$sizeh{$id}-1){
        my $pe1 = hash_value(\%pe_depth,$id,$i,0);#sub3
        my $pe2 = hash_value(\%pe_depth,$id,$i,1);#sub3
        my $pei1 = $pe1 ? int(hash_value(\%pe_insert,$id,$i,0)/$pe1+0.5) : 0;#sub3
        my $pei2 = $pe2 ? int(hash_value(\%pe_insert,$id,$i,1)/$pe2+0.5) : 0;#sub3
        push @pe,"$pe1/$pe2";
        push @pei,"$pei1/$pei2";
    }
    print PE ">$id\n";print_array(\@pe,60,*PE);#sub2.1
    print PEI ">$id\n";print_array(\@pei,60,*PEI);#sub2.1
    foreach(\%pe_depth,\%inv_depth,\%pe_insert){
        $_->{$id} || next;
        @{$_->{$id}} = ();
        delete $_->{$id};
    }
}
close PE;
close PEI;

#============================================================================================
#sub1
sub get_size{
    my ($size,$sizeh) = @_;
    open IN,$size || die$!;
    my $head = <IN>;
    my $is_fa = ($head =~ />\S+/) ? 1 : 0;
    seek(IN,0,0);
    if($is_fa){
        $/=">";<IN>;
        while(<IN>){
            /^(\S+)/ || next;
            my $id = $1;
            s/^.+?\n//;
            s/\s|>//g;
            $sizeh->{$id} = length;
        }
        $/="\n";
    }else{
        while(<IN>){
            my @l = split;
            $sizeh->{$l[0]} = $l[1];
        }
    }
    close IN;
}
#sub2
sub out_depth{
    my ($outfile,$depth,$sizeh,$Rlen,$nodel) = @_;
    open OUT,">$outfile" || die$!;
    foreach (sort {$a cmp $b} keys %{$sizeh}){
        my @seq = $depth->{$_} ? @{$depth->{$_}} : ();
        foreach my $i(0..$sizeh->{$_}-1){
            $seq[$i] ||= 0;
            ($Rlen && $depth->{$_} && $depth->{$_}->[$i] && $i <$sizeh->{$_}-1) || next;
            my ($s,$e) = ($i+1,$i+$Rlen-1);
            ($e > $sizeh->{$_}-1) && ($e = $sizeh->{$_}-1);
            foreach my $j($s .. $e){
                $seq[$j] += $depth->{$_}->[$i];
            }
        }
        if(!$nodel && $depth->{$_}){
            @{$depth->{$_}} = ();
            delete $depth->{$_};
        }
        print OUT ">$_\n";
        print_array(\@seq,60,*OUT);#sub2.1
    }
    close OUT;
}
#sub2.1
sub print_array{
    my ($array,$pln,$handel) = @_;
    while(@{$array}){
        my @temp = splice(@{$array},0,$pln);
        print $handel "@temp\n";
    }
}
#sub3
sub hash_value{
    my ($hash,$value,$pos,$sub_pos) = @_;
    ($hash->{$value} && $hash->{$value}->[$pos] && $hash->{$value}->[$pos]->[$sub_pos]) ?
        $hash->{$value}->[$pos]->[$sub_pos] : 0;
}
#sub4
sub get_plot{
    my ($inf,$rank,$ploth) = @_;
    $inf || return(0);
    my @sel = $rank ? split/,/,$rank : (0,1);
    foreach my $f(split/,/,$inf){
        (-s $f) || next;
        open IN,$f || die"$!";
        while(<IN>){
            my @l = (split)[@sel];
            @{$ploth->{$l[0]}->{$l[1]}} = 1;
        }
        close IN;
    }
}
#sub5
sub get_snp{
    my ($seq,$qual,$rpn,$stand,$chr,$pos,$Rlen,$qcut,$hash,$snp) = @_;
    $hash->{$chr} || return(0);
    my @in_reads;
    foreach($pos..$pos+$Rlen-1){
        $hash->{$chr}->{$_} && (push @in_reads,$_);
    }
    @in_reads || return(0);
    if($stand eq '-'){
        $seq = reverse $seq;
        $seq =~ tr/ATCG/TAGC/;
        $qual = reverse $qual;
    }
    my $is_rp = ($rpn > 1) ? 1 : 0;
    foreach(@in_reads){
        my $qt = ord(substr($qual,$_-$pos,1)) - 64;
        ($qt < $qcut) && next;
        my $nt = substr($seq,$_-$pos,1);
        ${$snp->{$chr}->{$_}->[2*$is_rp]}{$nt}++;
        ${$snp->{$chr}->{$_}->[2*$is_rp+1]}{$nt} += $qt;
    }
}

