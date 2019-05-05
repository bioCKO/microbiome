#!/usr/bin/perl -w
use strict;
my ($user,$prefix,$vmem,$help,$cycle,$sleept);
use Getopt::Long;
GetOptions("u:s"=>\$user,"p:s"=>\$prefix,"v"=>\$vmem,"h"=>\$help,"c:i"=>\$cycle,"t:f"=>\$sleept);
$help && die"Name: qstat.pl
Description: to get qsub task running stat incrod vf
Version: 1.0, date: 2010-9-11
Version: 2.0, date: 2011-4-30
Usage: perl qstat.pl [job_ids] [-options]
job_ids   job_ids you want to qstat, it must beyond to user
-u        user, default ARGV[0] or whoami result
-p        shell file prefix to qstat
-v        only the r or t stat job output: job_id job_name vf vmem maxvmem io cup
-h        output help imformation to screen
-c        set cycle number to re-stat, default only stat once
-t        set cycle time(s), default=100\n";
my %job; 
(@ARGV && $ARGV[0]=~/^\D/) && ($user = shift @ARGV);
chomp($user ||= `whoami`);
foreach(@ARGV){$job{$_} = 1;}
my $get_qstat = "qstat -u $user | awk '(NR>2";
$get_qstat .= $prefix ? " && \$3~/$prefix/)" : ")";
$get_qstat .= '{$7=$6"/"$7;print $1,$3,$5,$7,$8}\'';#job_id name stat star_rime queue
CY:{;}
chomp(my @qstat = `$get_qstat`);
@qstat || exit;
my $output = "";
foreach(@qstat){
	my @l = split/\s+/;
	%job && !$job{$l[0]} && next;
	if($l[2]!~/r/){
		$vmem && next;
		@l[4..9] = qw(- - - - - -);
	}else{
		$l[9] = $l[4];
        for(`qstat -j $l[0]`){
            if(/script_file:\s+(\S+)/){
                $l[1] = $1;
            }elsif(/virtual_free=(\S+)/){
                $l[6] = $1;
            }elsif(/usage\s+\d:\s+(.+)/){
                my %nh = split /=|,\s+/, $1;
                @l[4,5,7,8] = ($nh{cpu},$nh{io},$nh{vmem},$nh{maxvmem});
                for(@l[4,5,7,8]){$_||=0;s/\s//g;}
            }
        }
#   @l[1,4..8]  #name cpu io vf vmem maxveme
	}
	$vmem && (@l = @l[0,1,6,7,8,5,4]);
	$output .= join("\t",@l) . "\n" if($l[3] && $l[4] && $l[5]); ##2015-03-07, for Use of uninitialized value $l[3],$l[4],$l[5],chen
}
$output || exit;
print $vmem ? ("#job_id\tname\tvf\tvmem\tmaxmem\tio\tcpu\n" . ('-'x 80) . "\n") : 
("job_id\tname\tstat\tstar_time\tcpu\tio\tvf\tvmem\tmaxvmem\tqueue\n" . ('-' x 120) ."\n");
print $output;
if($cycle && $cycle>1){
    $sleept ||= 100;
    sleep($sleept);
    $cycle--;
    goto(CY);
}
