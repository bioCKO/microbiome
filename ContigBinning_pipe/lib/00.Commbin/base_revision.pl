#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my ($max_insert,$maxjob,$num,$size,$exact) = (4000, 4, 1.96);
GetOptions("m:i"=>\$max_insert,"s:s"=>\$size,"p:i"=>\$maxjob,"c:f"=>\$num,"e"=>\$exact);
@ARGV || die"Name: base_revision.pl
Descirption: script to correct assembly base according to reads mapping result.
Version: 1.0,  Date: 2011-12-27
Usage: perl base_revision.pl <referance.fa> <soap.coverage> > outfasta.revi
    soapl <file>      all soap result pathway
    psoapl <file>     PE soap reasult pathway list
    ssoapl <file>     SE soap reasult pathway list
    -m <num>          base revise mode, revise with 1-pe, 2-se, 3-all, default=3
    -s <file>         input old insert size file: lane_name insert_size, no default
    -p <num>          thread number, default=4
    -e                use soap2_insert.pl to caculate, it maybe more exact and Rsd != Lsd
    -c <flo>          default=1.96, out.stat be: lane_name avg_ins avg_ins-c*sd avg_ins+c*sd
Note: 
    1 default method use statistics mean as avg_ins, while -e use statistics mode
    2 output form: lane_name\tavg_ins\tmin_ins\tmax_ins\torig_ins\n";
$SIG{CHLD} = "IGNORE";
if(@ARGV==1){
    (-s $ARGV[0]) || die"error: can't find able file $ARGV[0], $!";
    chomp(my $head = `head -1 $ARGV[0]`);
#    (-s $head) && chomp(@ARGV = `less $ARGV[0]`);
    (-s $head) && chomp(@ARGV = `cat $ARGV[0]`);
}
my %sizeh;
#($size && -s $size) && (%sizeh = split/\s+/,`less $size`);
($size && -s $size) && (%sizeh = split/\s+/,`cat $size`);
my @stat;
my $i = 0;
my $fp = $$;
foreach my $f(@ARGV){
    $i++;
    my ($min_insert0,$max_insert0) = (0,$max_insert);
    my $lib;
	if (($f=~/L\d+_([^_]+)\.notCombined/ || $f=~/L\d+_([^_]+)_[12]\.fq/) && $sizeh{$1}) {
        $lib = $1;
        $max_insert0 = 2 * $sizeh{$1};
        $min_insert0 = 0.2 * $sizeh{$1};
    }
    if(fork()){
        ($i>$maxjob) && wait;
    }else{
        $exact ? exec"perl $Bin/soap2_insert.pl $f -nodraw > $fp.$i" :
        &insert_caculate($f,$min_insert0,$max_insert0,$lib,"$fp.$i");#sub1
        exit;
    }
}
while (wait != -1) { sleep 5; }
my %mege;
foreach my $a(1..$i){
    (-s "$fp.$a") || next;
    my @l = split/\s+/,`cat "$fp.$a"`;
#my @l = split/\s+/,`less "$fp.$a"`;
    if($exact){
        push @{$mege{$l[0]}},[@l[1..$#l]];
    }else{
        foreach(0..2){$mege{$l[3]}->[$_] += $l[$_];}
    }
}
foreach(keys %mege){
    my ($avg_ins,$sd1,$sd2);
    if($exact){
        $mege{$_} || next;
        my @l = @{$mege{$_}};
        if(@l == 1){
            ($avg_ins,$sd1,$sd2) = @{$l[0]}[0,-2,-1];
        }else{
            my ($r_num,$l_num) = ($l[0]->[2]+$l[0]->[4], $l[1]->[2]+$l[1]->[4]);
            $avg_ins = ($l[0]->[0]*$r_num + $l[1]->[0]*$l_num)/($r_num + $l_num);
            $sd1 = sqrt(($l[0]->[1]+$l[1]->[1])/($l[0]->[2]+$l[1]->[2]));
            $sd2 = sqrt(($l[0]->[3]+$l[1]->[3])/($l[0]->[4]+$l[1]->[4]));
        }
    }else{
        $avg_ins = $mege{$_}->[0]/$mege{$_}->[2];
        $sd1 = ($sd2 = sqrt($mege{$_}->[1]/$mege{$_}->[2] - $avg_ins**2));
    }
    my ($min_ins,$max_ins) = ($avg_ins-$num*$sd1,$avg_ins+$num*$sd2);
    foreach($avg_ins,$min_ins,$max_ins){$_ = int($_+0.5);}
    ($min_ins < 0) && ($min_ins = 0);
    print join("\t",$_,$avg_ins,$min_ins,$max_ins,$sizeh{$_})."\n";
}
`rm $fp.*`;
#sub1
####################
sub insert_caculate
####################
{
    my ($f,$min_insert,$max_insert,$lib,$fp) = @_;
    (-s $f) || return(0);
    my ($avg,$sd,$se_num,$pe_num,$rp_num) = (0, 0, 0, 0, 0);
    my @k;
#    (-s $f) || ((print STDERR "note: $f isn't able file, $!\n"),return(0));
    my $hend;
    ($f=~/\.gz$/) ? (open($hend,"<:gzip",$f) || die$!) : (open $hend,$f || die$!);
    while(<$hend>){
        my @l = (split)[0,3,6,8,5];
        $l[0] =~ s/\/[12]$//;
        &stat_insert(\@l,\@k,\$avg,\$sd,\$pe_num,\$se_num,\$rp_num,$min_insert,$max_insert);#sub1.1
    }
    close $hend;
    $lib ||= 'all';
    open OUT,">$fp" || die$!;
    print OUT join("\t",$avg,$sd,$pe_num,$lib);
    close OUT;
}

#sub1.1
################
sub stat_insert
################
{
    my ($l,$k,$avg,$sd,$pe_num,$se_num,$rp_num,$min_insert,$max_insert) = @_;
    @{$k} || (@{$k}=@{$l},return(0));
    if($l->[0] ne $k->[0]){
        @{$k} = @{$l};
        $$se_num++;
    }else{
        if($k->[1]==1 && $l->[1]==1){
            my $insert;
            my $type = ($k->[2] eq '+' && $l->[2] eq '-') ? 0 :
                ($k->[2] eq '-' && $l->[2] eq '+') ? 1 : 2;
            ($max_insert > 2000) && ($type = 1-$type);
            if($type==0){
                $insert = $l->[3] - $k->[3] + $l->[4];
            }elsif($type==1){
                $insert = $k->[3] - $l->[3] + $k->[4];
#            if($k->[2] ne $l->[2]){
#                $insert = $l->[3] - $k->[3];
#                ($insert > 0) ? ($insert += $l->[4]) : ($insert = $k->[4] - $insert);
            }else{
#                $$se_num += 1;
                @{$k} = @{$l};
                return(0);
            }
            ($insert < $min_insert || $insert > $max_insert) && (@{$k}=@{$l},return(0));
            $$avg += $insert;
            $$sd += $insert**2;
            $$pe_num++;
        }else{
#            $$rp_num++;
        }
        @{$k} = ();
    }
}
