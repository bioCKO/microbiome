#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my ($max_insert,$maxjob,$num,$range,$size,$exact,$dir,$spf) = (4000, 4, 1.96, '0,0;1000,3i');
GetOptions("m:i"=>\$max_insert,"s:s"=>\$size,"p:i"=>\$maxjob,"c:f"=>\$num,"e"=>\$exact,
    "d:s"=>\$dir,"r:s"=>\$range,"spf:s"=>\$spf);
@ARGV || die"Name: calculate_insert.pl
Descirption: script to caculate insert size with SOAP2 result.
Version: 1.0,  Date: 2011-12-7
Usage: perl calculate_insert.pl <soap.lst | soap1,2...> >out.stat
    soap1,2... <file> soap result pathway
    soap.lst <file>   soap reasult pathway list
    -m <num>          maximul insert insert, default=4000 or 2*avg_ins
    -s <file>         input old insert size file: lane_name insert_size, no default
    -p <num>          thread number, default=4
    -e                use soap2_insert.pl to caculate, it maybe more exact and Rsd != Lsd
    -d <dir>          set directory to output unselect PE, default not output
    -r <str>          set the range to identity normal insert range, while -d set, default=0,0/1000,3i
    -c <flo>          default=1.96, out.stat be: lane_name avg_ins avg_ins-c*sd avg_ins+c*sd
Note: 
    1 default method use statistics mean as avg_ins, while -e use statistics mode
    2 -r set is small_lib_min,max;big_lib_min,max, i can means avg_ins, e.g: if avg_ins=2000 then 3i=6000
    3 output form: lane_name\tavg_ins\tmin_ins\tmax_ins\torig_ins\n";
$SIG{CHLD} = "IGNORE";
if(@ARGV==1){
    (-s $ARGV[0]) || die"error: can't find able file $ARGV[0], $!";
    chomp(my $head = `head -1 $ARGV[0]`);
    (-f $head) && chomp(@ARGV = `cat $ARGV[0]`);
}
my %sizeh;
($size && -s $size) && (%sizeh = split/\s+/,`awk '{print \$1,\$2}' $size`);
my @stat;
my $i = 0;
my $fp = $spf || $$;
if($dir){
    (-d $dir) || mkdir($dir);
    $exact = 0;
}
my @rag = split/[;\/]/,$range;
$spf && goto(AA);
foreach my $f(@ARGV){
    my ($min_insert0,$max_insert0) = (0,$max_insert);
    my $lib;
    my $lib_len = 0;
    my $bf = (split/\//,$f)[-1];
    if($bf =~ /L\d+_([^_]+)\.notCombined_[12]\.f[aq]/ || $bf =~ /L\d+_([^_]+)_[12]\.fq/){
        $lib = $1;
        $sizeh{$lib} && ($max_insert0 = 2 * $sizeh{$lib}, $min_insert0 = 0.2 * $sizeh{$lib}, $lib_len = $sizeh{$lib});
    }
	elsif ($bf =~ /L\d+_(\S+)\.extendedFrags\.f[aq]/) {
		next;
	}
    $lib_len ||= $max_insert0;
    my $lib_type = ($lib_len >= 2000) ? 1 : 0;
    my @r;
    foreach(split/,/,$rag[$lib_type]){
        /(\S+)i/ && ($_ = $1 * $lib_len);
        push @r,$_;
    }
    ($r[0] || $r[1]) || (@r = ());
    my $bname = (split/\//,$f)[-1];
    $i++;
    if(fork()){
        ($i>$maxjob) && ($i++,wait);
    }else{
        $exact ? exec"perl $Bin/soap2_insert.pl $f -nodraw -large $lib_type > $fp.$i" :
        &insert_caculate($f,$min_insert0,$max_insert0,$lib,"$fp.$i",$lib_type,$dir ? "$dir/$bname.dd" : 0,\@r);#sub1
        exit;
    }
}
while (wait != -1) { sleep 5; }
AA:{;}
$i = @ARGV;
my %mege;
foreach my $a(1..$i){
    (-s "$fp.$a") || next;
    my @l = split/\s+/,`cat "$fp.$a"`;
    if($exact){
        push @{$mege{$l[0]}},[@l[1..$#l]];
    }else{
#        $avg,$sd,$pe_num,$lib
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
        if($mege{$_}->[2]){
            $avg_ins = $mege{$_}->[0]/$mege{$_}->[2];
            $sd1 = ($sd2 = sqrt($mege{$_}->[1]/$mege{$_}->[2] - $avg_ins**2));
        }else{
            $avg_ins = $sizeh{$_};
            $sd1 = ($sd2 = 0.2 * $avg_ins);
        }
    }
    my ($min_ins,$max_ins) = ($avg_ins-$num*$sd1,$avg_ins+$num*$sd2);
    foreach($avg_ins,$min_ins,$max_ins){$_ = int($_+0.5);}
    ($min_ins < 0) && ($min_ins = 0);
    print join("\t",$_,$avg_ins,$min_ins,$max_ins,$sizeh{$_})."\n";
}
#`rm $fp.*`;
#sub1
####################
sub insert_caculate
####################
{
    my ($f,$min_insert,$max_insert,$lib,$fp,$lib_type,$del_name,$r) = @_;
    (-s $f) || return(0);
    my ($avg,$sd,$se_num,$pe_num,$rp_num) = (0, 0, 0, 0, 0);
    my @k;
#    (-s $f) || ((print STDERR "note: $f isn't able file, $!\n"),return(0));
    my $hend;
    ($f=~/\.gz$/) ? (open($hend,"<:gzip",$f) || die$!) : (open $hend,$f || die$!);
    my $del_pe;
    ($r && @{$r}) || ($del_name = 0);
    $del_name && (open($del_pe,">",$del_name) || die$!);
    while(<$hend>){
        my @l = split;
        (@l < 12) && next;
        @l = @l[0,3,6,8,5];
        $l[0] =~ s/\/[12]$//;
        &stat_insert(\@l,\@k,\$avg,\$sd,\$pe_num,\$se_num,\$rp_num,$min_insert,$max_insert,$lib_type,$del_pe,$r);#sub1.1
    }
    close $hend;
    $del_name && close($del_pe);
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
    my ($l,$k,$avg,$sd,$pe_num,$se_num,$rp_num,$min_insert,$max_insert,$lib_type,$del_pe,$r) = @_;
    @{$k} || (@{$k}=@{$l},return(0));
    if($l->[0] ne $k->[0]){
        @{$k} = @{$l};
        $$se_num++;
    }else{
        if($k->[1]==1 && $l->[1]==1){
            my $insert;
            my $type = ($k->[2] eq '+' && $l->[2] eq '-') ? 0 :
                ($k->[2] eq '-' && $l->[2] eq '+') ? 1 : 2;
            $lib_type && ($type = 1-$type);
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
            if($del_pe && ($insert < $r->[0] || $insert > $r->[1])){
                print $del_pe "$l->[0]\n";
            }
            if($insert < $min_insert || $insert > $max_insert){
                @{$k}=@{$l};
                return(0);
            }
            $$avg += $insert;
            $$sd += $insert**2;
            $$pe_num++;
        }else{
#            $$rp_num++;
        }
        @{$k} = ();
    }
}
