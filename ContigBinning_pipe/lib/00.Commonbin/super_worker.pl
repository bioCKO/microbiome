#!/usr/bin/perl

=head1 Name

 super_worker.pl

=head1 Description

 To split tasks and control processes running on linux SGE or local system.
 The scrript combine the excellence of qsub-sge.pl(V8.2 Fan Wei, Hu Yujie)
 and do_job.pl(V4.1 Wenbin Liu). Use the name super_worker.pl becaus it not
 only use qsub to throw tasks, and labor date is coming.

=head1 Version

 Author: Fan Wei, fanw@genomics.org.cn
 Author: Hu Yujie, huyj@genomics.org.cn
 Author: Wenbin Liu, liuwenbin@genomics.org.cn
 Version: 5.0   Date: 2011.4.30
 Version: 5.1,  sparate some package to script function and sub-function to Bin/qsub/script, Date: 2011.7.26
 Version: 5.2,  add -endsh, Date: 2012.1.29
 Version: 5.3,  add the function of qsub_factory.pl, Date:2015.12.14
 Version: 5.4,  to update qsub_comm at each check cycle by .equ file, Date: 2016.1.26

=head1 Usage

 perl super_worker.pl <inshell> [--options]
 <inshell>          input shell file you want to run
 1.qsub options:
 --mutil            throw the tasks in local system, not use qsub.
 --workdir <str>    directory for tasks running, default inshell.$$.{qsub|mutil}/
 --resource <str>   resource for qsub, default='1g'
 --queue <str>      queue for qsub, default not set.
 --node <str>       compute node for qsub, more nodes split by ',', default not set.
 --nodesel <num>    select node form node record file:0-not use, 1-use small node,
                    2-use big node, 3-use all nodes, default 0
 --nodetxt <str>    file record node, form: user = small-node-lst big-node-lst,
                    default="/home/liuwenbin/share/compute-node.txt".
 --qopts <str>      other qsub options, default not set.

 2.shell file optins:
 --splits <str>     specify singn as the end of a line, default='\n'.
 --line <num>       the row number of inshell to write in sub_shell, default 1
 --splitn <num>     split inshell average into specify number, then -line not work.
 --absway           change pathway in shfile into absolutely pathway.
 --prefix <str>     sub_shell prefix, default qsub:work, mutil:mutil.
 --suffix <str>     sub_shell suffix, default sh.
 --head <str>       commend export at the head of eatch sub_shell, default not set.
 --middle <str>     words add at eatch commend line end, default not set.
 --end <str>        commend put at end of eatch sub_shell, default nothing.
 --focus <str>      prefix of file to get STDOUT of eatch sub_shell, default not set.
 --focus2 <str>     prefix of file to get STDERR of eatch sub_shell, default not set.
 --fsuffix <str>    suffix of focus file, default not set.
 --fsuffix2 <str>   suffix of focus2 file, default not set.
 --filter <str>     filter commend add before -focus, default not set.
 --fend <str>       commend put at end of eatch sub_shell, while use --filter.
 --endsh <file|str> shell file or commend to run after all tasks finish.
 
 3.contral options:
 --maxjob <num>     max job number running at a same time, default qusb:100, mutil:5
 --tasklim <num>    tasks number limit for qsub per user, default=400
 --sleept <num>     interval(second) to check running state, default qsub 300, mutil 100
 --reqsub <num>     restar err_tasks when scouting: 0 restar every check time, 1 restar
                    every cycle, 2 no restar just kill, 3 no restar no kill, default 0
 --reqtime <num>    the max time for reqsub, default=30
 --cycle <num>      the max cycle for reqsub, cycle end is not task running, default=5
 --reqline          reqsub error job from current commend, default all the shell reqsub
 --delwrite         del the shell commend have run, when rewrite it for reqsub.
 --reqcol <str>     file for -reqline contral, default creat by the process.
 --checke           to check .e file at the end of a cycle, default not check
 --sure <str>       set the user defined job completition mark at .e file, default no net.
 --wrong <str>      the user definded job not completition mark at .e file, default not set.
 --osure <str>      set the user defined job completition mark at .o file, default no need.
 --owrong <str>     the user definded job not completition mark at .o file, default not set.
 --clean            delete workdir and other middle file, fater all the tasks finished.
 --logtxt <str>     file for recording log information, default STDERR out.
 --verb             output verbose log information
 --qstat <str>      file for recording vmem and io of eatch subshell, default not use.
 --qalter           to change vf=maxvmem, while vmem - vf > vf_cutoff or when reqsub
                    if reqsub<2, -qstat default will set to be inshell.$$.qstat
 --dvf <srt>        vf cutoff, while --qalter, deault not set
 --cyqt <num>       interval to output finish or qstat imformation of tasks, default=3,
                    means every 3 sleept; only r or T stat jobs can be recorded at -qstat.
 --equipment        use equpment file to rerun jobs, then inshell should be equpment file
 --equprefix <srt>  main equipment file prefix, default=inshell.$$
 --help             out put help information to screen.
 
=head1 Note

 1 Line empty or '^#' in shfile will ignore, when some pathway was not absway --absway must set.
 2 When use -node, -nodesel will no use, also death node will delete form your set.
 3 X and Z will see as error state when -mutil, /T/ /s/i /E/ /d/ will see as error state when qsub.
 4 When -delwrite, commend line have run will be deleted, or '#' will add to line head at key file.
 5 -absway change worlds into absolutely when: A. head with ./ ../ > >> 1> 2> >& 1>> 2>> >>&, 
   B. be file or directory except '.' or '..', so directory . and .. should write as ./ and ../,
   uncreated file abc.txt at ./ should write as ./abc.txt.
 6 At -head -middle -end -fend, sxxx can fill in subfile number; at -middle, lxxx fill in line number,
   but '\n' was not allowed; -end -fend set can also be a file.
 7 After all the tasks thrown, shfile $$.kill.sh for killing tasks, $$.clean.sh for cleaning and $$.equ
   for rerun the process will appear.
 8 While main process was killed, perl super_worker.pl -equpment *.$$.equ can restat it, the commend also
   can use to check weather all the tasks finish successfully.
 9 While use -end with -focus, and -end commend have screan output, the ouput will go into focus set
   file, if you want it goto .o file, please use --fend set
 
=head1 Example
  
  1 use qsub
  1.1 ordinary used
   nohup perl super_worker.pl work.sh -resource vf=2g -verb &
  1.2 used --splits --splitn --reqline --node
   nohup perl super_worker.pl work.sh -node compute-0-23,computer-0-193 -splits "\n\n" -reqline -absway &
  1.3 used --qopts to select other qsub options, and use --end
   perl super_worker.pl work.sh -line 4 --qopts="-S /bin/sh -q all.q" -end "echo 'my work finish'"
  1.4 used --head to do EXPORT in special emvironment
   perl super_worker.pl genewise.sh  -line 20 -head 'EXPORT WISECONFIGDIR=/share/xxx'
  1.5 used --focus may reduce small file, lastz.sh is stdout, do as follow, result will in out/lastz0~19
   perl super_worker.pl lastz.sh  -absway -splitn 20  -focus 'out/lastz' -filter "awk '(!/^#/)'"
  1.6 restar work.sh with work.sh.$$.equ, if all jobs finish, "Successfully finished!!" will output.
   perl super_worker.pl -equpment work.sh.34229.equ
	
 2 use -mutil (PS: it can also call -bgrun)
  perl super_worker.pl -mutil work.sh -splitn 5 -workdir ./
  perl super_worker.pl work.sh -sleept 150 -maxjob 3  --mutil
  perl super_worker.pl work.sh  -bgrun -cycle 3 -clean

	
=cut
###################################################################################################
use strict;
#use lib "/home/liuwenbin/system/pm";
#use COMM;
use FindBin qw($Bin);
use Getopt::Long;
my($bgrun,$mutil,$work_dir,$resource,$queue,$node,$qopts,$line,$splitn,$splits,$absway,$qstat,$cyqt,$maxvf,
$prefix,$suffix,$head,$end,$focus,$fsuffix,$filter,$middle,$maxjob,$tasklim,$sleept,$logtxt,$fend,$qalter,
$reqcol,$reqline,$reql,$cycle,$reqtime,$clean,$delwrite,$sure,$equipment,$nodesel,$nodetxt,$reqsub,$novb,$qcfg,
$checke,$focus2,$fsuffix2,$equprefix,$verb,$wrong,$osure,$owrong,$help,$endsh,$noV,$qstatl,$cfg,$runs,$locate);
GetOptions(
        "locate"=>\$locate,
		"bgrun"=>\$bgrun,
		"mutil"=>\$mutil,
		"workdir:s"=>\$work_dir,
		"resource:s"=>\$resource,
		"queue:s"=>\$queue,
		"node:s"=>\$node,
		"qopts:s"=>\$qopts,
		"splitn:i"=>\$splitn,
		"splits:s"=>\$splits,
		"line:i"=>\$line,
		"absway"=>\$absway,
		"prefix:s"=>\$prefix,
		"suffix:s"=>\$suffix,
		"head:s"=>\$head,
		"middle:s"=>\$middle,
		"end:s"=>\$end,
		"fend:s"=>\$fend,
		"focus:s"=>\$focus,
		"fsuffix:s"=>\$fsuffix,
		"focus2:s"=>\$focus2,
		"fsuffix2:s"=>\$fsuffix2,
		"equprefix:s"=>\$equprefix,
		"filter:s"=>\$filter,
		"maxjob:i"=>\$maxjob,
		"tasklim:i"=>\$tasklim,
		"sleept:i"=>\$sleept,
		"reqsub:i"=>\$reqsub,
		"reqline"=>\$reqline,
		"reql"=>\$reql,
		"reqcol:s"=>\$reqcol,
		"cycle:i"=>\$cycle,
		"reqtime:i"=>\$reqtime,
		"logtxt:s"=>\$logtxt,
		"delwrite"=>\$delwrite,
		"sure:s"=>\$sure,
		"checke"=>\$checke,
		"wrong:s"=>\$wrong,
		"osure:s"=>\$osure,
		"owrong:s"=>\$owrong,
		"equipment"=>\$equipment,
		"nodesel:i"=>\$nodesel,
		"nodetxt:s"=>\$nodetxt,
		"qstat:s"=>\$qstat,
        "qstatl"=>\$qstatl,
		"cyqt:i"=>\$cyqt,
		"qalter"=>\$qalter,
		"dvf:s"=>\$maxvf,
		"clean"=>\$clean,
		"novb"=>\$novb,
		"verb"=>\$verb,
		"help"=>\$help,
        "endsh:s"=>\$endsh,
        "noV"=>\$noV,
        "cfg:s"=>\$cfg,
        "qcfg:s"=>\$qcfg,
        "runs"=>\$runs
);
###################################################################################################
$help && (die `pod2text $0`);
if (@ARGV == 0){
	die"
*****************************************************************************************

Name: super_worker.pl
Description: To split tasks and control processes running on linux SGE or local system.
The scrript combine the excellence of qsub-sge.pl(V8.2 Fan Wei, Hu Yujie) and do_job.pl
(V4.1 Wenbin Liu).
Version: 5.1,  Date:2011-07-26
Version: 5.3,  Date:2015-12-14, add the function of qsub_factory.pl
Version: 5.4,  Date: 2016-01-26, to update qsub_comm at each check cycle by .equ file
Contact: Wenbin Liu, liuwenbin\@genomics.org.cn
Usage: perl super_worker.pl <inshell> [--options]
 <inshell>          input shell file you want to run
 --mutil            throw the tasks in local system, not use qsub
 --resource <str>   resource for qsub, default 'vf=1g'
 --line <num>       the row number of inshell to write in sub_shell, default 1
 --splits <str>     specify singn as the end of a line, default='\\n'
 --splitn <num>     split inshell average into specify number, then -line not work
 --absway           change pathway in shfile into absolutely pathway
 --maxjob <num>     max job number running at the same time, default qusb:100, mutil:5
 --clean            delete middle file of dir, after all the tasks finished
 --cfg <file>       input cfg for qsub_factory
 --help             out put help information to screen

Note: you can use --help to get detail help information

*****************************************************************************************\n\n";
}
###################################################################################################
###################################################################################################
##==== 0.Check errors  ====###
my $file = shift;
(-f $file) || die"Error: can't find file $file $!";
(-z $file) && die"Error: infile $file is empty $!";
!$equipment && ($file =~ /\.equ$/) && ($equipment = 1);
$middle && ($middle =~ /\n/) && die"Erroe: '\\n' was not allowed at -middle $!";
$qstatl && ($qstat ||= "$file.qstat");
foreach($file,$logtxt,$qstat){$_ &&= abs_path($_);}
($qcfg && -s $qcfg) && ($cfg = $qcfg);
if($cfg && -s $cfg){
    $cfg = abs_path($cfg);
    my $qsub_factory = "perl $Bin/qsub_factory.pl";
    $splitn && ($qsub_factory .= " --splitn $splitn");
    $splits && ($qsub_factory .= " --splits=\"$splits\"");
    $head && ($qsub_factory .= " --head=\"$head\"");
    $end && ($qsub_factory .= " --end=\"$end\"");
    $runs && ($qsub_factory .= " --runs");
    system"$qsub_factory --cfg $cfg --shell $file";
    exit;
}
##================================##
##   1.option value default set   ##
##================================##
($locate || $bgrun) && ($mutil = 1); ##-mutil use to call -bgrun at do_job.pl
$line ||= 1;
$reqtime ||= 30;
$cycle ||= 5;
$sleept ||= $mutil ? 100 : 300;
$maxjob ||= $mutil ? 5 : 400;
$tasklim ||= 800;
$cyqt ||= 3;
$reqsub ||= 0;
$verb || ($novb = 1);#$novb was make at first, then I found that use $verb maybe better
($maxjob > $tasklim) && ($maxjob = $tasklim);
#$maxvf ||= '1g';
$maxvf = $maxvf ? real_bit($maxvf) : 0;#sub3.2.1.4.1
($sure || $wrong) && ($checke = 1);
##=== get qsub commend
my @cp_node;
my $qsub_comm = get_qsub_commend(\@cp_node,$nodetxt,$nodesel,$node,$queue,$resource,$qopts,$mutil,$equipment,$noV); #sub0
$prefix ||= $mutil ? 'mutil' : 'work';
$suffix ||= "sh";
$suffix =~ s/^\.+//;
$focus || $focus2 ||
($filter && die"Error: -filter only used when -focus or -focus2, if necessary used -middle \"|filter\" please\n");
deal_focus(\$focus,\$fsuffix);#sub4
deal_focus(\$focus2,\$fsuffix2);#sub4
$filter && mul_path($filter); ##COMM
###################################################################################################
##================================##
##   2.set directory or file      ##
##================================##
##===  script file  ===##
#my ($file_split_pl,$rewrite_pl,$qstat_pl,$shcontral_pl) = get_path("file_split","rewrite_pl","qstat_pl","sh_contral");#COMM sub3.4
my $Bdir = "$Bin/qsub";
(-d $Bdir) || ($Bdir = "lib/00.Commonbin/qsub");
my ($file_split_pl,$rewrite_pl,$qstat_pl,$shcontral_pl) =
("perl $Bdir/file_split.pl","perl $Bdir/rewrite.pl","perl $Bdir/qstat.pl","perl $Bdir/sh_contral.pl");
$file_split_pl .= " -filter";
#$qstat_pl .= " -v";
##=== grobel value  ===##
chomp(my $temdir = `pwd`);
my ($finish,$sh_absl,$kill_sh,$kill_sign,$run_shelf,$err_shelf,$equ_file,$cleanf,$killf);
$equipment && (goto EM);
##==== directory  ===##
my $del_workdir = ($work_dir && (-d $work_dir)) ? 0 : 1;
$work_dir ||= (split/\//,$file)[-1] . $$ . ($mutil ? "mutil" : "qsub"); # directory for running tasks
$work_dir = abs_path($work_dir);
(-d $work_dir) || mkdir"$work_dir";
my $equ_dir = "$work_dir/equipment.$$";           # dierctory to store equipment file
(-d $equ_dir) || mkdir"$equ_dir";
my $shell_lib = 
$filter ? "$work_dir/shell_lib.$$" : $work_dir;   # dierctory to store sub_shell file
(-d $shell_lib) || mkdir"$shell_lib";
my $logdir;
if($reqline){
	$logdir = "$work_dir/advance.$$";          # directoty to store advance rate record file
	(-d $logdir) || mkdir"$logdir";
	$reqcol ||= "$equ_dir/shell.$$.reqcol";    # file for -reqline contral
}
##===  file  ===##
$equprefix ||= "$file.$$";
$equprefix = abs_path($equprefix);
$finish = "$equ_dir/finish.$$";           # shell finish record file
$kill_sh = "$equ_dir/qdel.$$.sh";         # shell to qdel all the tasks
$kill_sign = "$equ_dir/kill_sign.$$";     # file for kill commend signal store
$sh_absl = "$equ_dir/shell.$$.absl";      # shell absolutely pathway file
$run_shelf = "$equ_dir/run_shelf.$$";     # file record last running id of eatch shell
$err_shelf = "$equ_dir/err_shelf.$$";     # file record error task waiting for reqsub
$equ_file = "$equprefix.equ";             # file record all the equipment
$cleanf = "$equprefix.clean.sh";          # shell file for cleaning the middle file
$killf = "$equprefix.kill.sh";            # shell file for killing all the task
open CLE,">$cleanf";
my $del_commend = "rm -rf $work_dir/${prefix}*\nrm -rf $equ_dir\n";
$reqline && ($del_commend .= "rm -rf $logdir\n");
$filter && ($del_commend .= "rm -rf $shell_lib\n");
$del_workdir && ($del_commend .= "rm -rf $work_dir\n");
$del_commend .= "rm -rf $equ_file $cleanf $killf\n";
print CLE $del_commend;
close CLE;
open KLL,">$killf";
print KLL "echo \"Fource kill\" >$kill_sign\n#sh $kill_sh\n";
close KLL;
!$mutil && ($reqsub<2) && $qalter && ($qstat ||= "$file.$$.qstat");
###################################################################################################
##================================##
##  3.spllit the shell file       ##
##================================##
my $maycol = ($reqcol && (-s $reqcol)) ? 0 : 1;
split_file($maycol,$shell_lib,$prefix,$suffix,$sh_absl,$splitn,$line,$splits,$absway,$logdir,$focus,
$fsuffix,$focus2,$fsuffix2,$reqline,$filter,$head,$middle,$end,$file_split_pl,$file); #sub1
(-s $sh_absl) || die"Error: can't creat $sh_absl, maybe there are some error\n";
my $max_splitn = (split/\s+/,`wc -l $sh_absl`)[0];
($max_splitn < $splitn) && ($splitn = $max_splitn);
###################################################################################################
##================================##
##  4.write the equipment file    ##
##================================##
my $deln = $delwrite ? 1 : 0;
write_equip($reqline,$reqcol,$sh_absl,$filter,$focus,$fsuffix,$focus2,$fsuffix2,$equ_file,$work_dir,
$finish,$run_shelf,$err_shelf,$kill_sign,$kill_sh,$cleanf,$qsub_comm,\@cp_node,$rewrite_pl,$deln,
$fend,$qstat,$qalter,$logtxt); #sub2
EM:if($equipment){
	$equ_file = $file;
	my %equph = split/\t|\n/,`less $file`;
	if($equph{'qsub_comm'}){
		$mutil = 0;
		$qsub_comm ||= $equph{'qsub_comm'};
		$equph{'node'} && (@cp_node = split/\s+/,$equph{'node'});
	}else{
		$mutil = 1;
	}
	if($equph{'qstat'}){$qstat = $equph{'qstat'};}
	if($equph{'reqcol'}){$reqline = 1; $reqcol = $equph{'reqcol'};}
	if($equph{'logtxt'}){$logtxt ||= $equph{'logtxt'};}
	if(!$mutil && ($reqsub<2) && $qalter && !$qstat){$qstat = $file;$qstat =~ s/equ$/qstat/;`echo "qstat\t$qstat" >>$file`;}
	my @signs = qw(workdir finish shabsl killsh killsign runsh errsh clean);
	my @get_equip;
	foreach($work_dir,$finish,$sh_absl,$kill_sh,$kill_sign,$run_shelf,$err_shelf,$cleanf){
		my $sign = shift @signs;
		$_ = $equph{$sign};
	}
	%equph = ();
}
###################################################################################################
##================================##
##     5.to throw the tasks       ##
##================================##
if($logtxt){open LG,">>$logtxt" || die"$!";select LG;$novb=0;}else{select STDERR;}
!$mutil && $qstat && ($equipment ? (open ME,">>$qstat" || die$!) : (open ME,">$qstat" || die$!));
(-s $kill_sign) && `rm -r $kill_sign`;
my $xxx = "\n" . ('*' x 88) . "\n";
$novb || ($equipment ? (print "\n$xxx\nWelcone to use super_worker.pl again\n") : version($file));#sub5.0
qsub_mutil($equipment,$mutil,$work_dir,$temdir,$sh_absl,$run_shelf,$err_shelf,$finish,$killf,$kill_sh,$kill_sign,
$cyqt,$sure,$sleept,$maxjob,$tasklim,$reqline,$reqcol,$qsub_comm,$cycle,$reqtime,\@cp_node,$equ_file,
$qstat,$qstat_pl,$shcontral_pl,$reqsub,$checke,$qalter,$maxvf,$novb,$wrong,$osure,$owrong);#sub 3
$novb || (print "Successfully finished!!\n");
$logtxt && (close LG);
!$mutil && $qstat && (close ME);
if($endsh){
    chdir"$temdir";
    (-s $endsh) ? system"sh $endsh" : `$endsh`;
}
###################################################################################################
##================================##
##  6.clen the middle file or dir ##
##================================##
ENN:{
	chdir"$temdir";
	$clean && `sh $cleanf`;
}

###################################################################################################
###################################################################################################
##=====================================##
##            7.SUB FUNCTION           ##
##=====================================##
#sub5.0
#==========#
sub version
#==========#
{
	my $nowtime = localtime();
	my $xxx = "\n" . ('*' x 88) . "\n";
	print "$xxx\*\n*\tWelcome to use super_work.pl	Version: 5.0	Date: 2011.4.30
*\tNow time: $nowtime
*\tYour shell: $_[0]
*\tIf any problems, please connect liuwenbin, liuwenbin\@genomics.org.cn.
*\tGood luck for you. Thanks!!\n*$xxx\n";
}
#sub4
###############
sub deal_focus
###############
{
	my ($focus,$fsuffix) = @_;
	if($$focus){
		$$focus = abs_path($$focus);
		$$focus =~ /^(\S+)\//;
		(-d $1) || mkdir"$1";
		$$fsuffix ? ($$fsuffix =~ s/^\.+//,$$fsuffix = ".$$fsuffix") : ($$fsuffix = ' ');
	}
}
#sub0
#===================#
sub get_qsub_commend
#===================#
{
	my ($cpnode,$nodetxt,$nodesel,$node,$queue,$resource,$qopts,$mutil,$equipmemt,$noV) = @_;
	##=== check compute-node  ===##
	if(!$node && $nodesel && ($nodetxt && -s $nodetxt)){
		my %sel_node = split/\s+=\s+|\s*\n/,`awk '(\$1 && \$1!~/^#/)' $nodetxt`;
		chomp(my $use_name = `whoami`);
		if($sel_node{$use_name}){
			my @l = split/\s+/,$sel_node{$use_name};
			$node = ($nodesel==1) ? $l[0] : ($nodesel==2 && $l[1]) ? $l[1] :
			($nodesel==3) ? join(",",@l) : 0;
		}
	}
	if($queue && $queue!~/\s-\S+\s/){
		my %acce_queue = access_queue();
		my @aqueue;
		foreach(split/,/,$queue){
			$acce_queue{$_} ? (push @aqueue,$_) : (print STDERR "Note: queue $_ was not accessed\n");
		}
		(@aqueue==0) ? ($queue = "",print STEREE "Error: no queue can used with set -queue $queue , we will not specify queue\n") :
		($queue = join(",",@aqueue));
	}
	if($node && $node!~/\s-\S+\s/){
		my %node_died = died_nodes();#sub3.2.1.1
		foreach(split/,/,$node){
			$node_died{$_} ? (print STDERR "Note: compute node $_ has been death\n") : (push @{$cpnode},$_);
		}
		(@cp_node==0) ? ($node=0,print STEREE "Error: no compute node can used with set -node $node , we will not specify nodes\n") :
		(@cp_node==1) ? ($node = shift @{$cpnode}) : ($node = 0);
	}
	##=== get qsub commend  ===##
	my $qsub_comm;
	if(!$mutil && (!$equipment || ($equipment && ($resource || $node || $queue || $qopts)))){
		$resource ||= '1g';
		$resource =~ s/^\s*vf=//;
		$qsub_comm = "qsub -cwd -l vf=$resource";
        $noV || ($qsub_comm .= " -V");
		$node && ($qsub_comm .= " -l h=$node");
		$queue && ($qsub_comm .= " -q $queue");
		$qopts && ($qsub_comm .= " $qopts");
	}
	$qsub_comm && ($qsub_comm =~ /(-q\s+(\S+mem)\.q)\s/) && ($qsub_comm !~ /\s+-P\s+/) && ($qsub_comm =~ s/$1/-q $2.q -P $2/);
	return($qsub_comm || 0);
}
#sub0.1
##==============#
sub access_queue
##==============#
{
	chomp(my $user = `whoami`);
	my $access_queue = 
	(`qstat -g c -U $user | awk '{x++}(x>2){print \$1,1}' ` || 0);
	$access_queue || die"Error: User $user have no access queue\n";
	split/\s+/,$access_queue;
}

#sub1
#=============#
sub split_file
#=============#
{
	my ($maycol,$shell_lib,$prefix,$suffix,$sh_absl,$splitn,$line,$splits,$absway,$logdir,$focus,$fsuffix,
	$focus2,$fsuffix2,$reqline,$filter,$head,$middle,$end,$file_split_pl,$file) = @_;
	## get split_file options  ##
	my $split_comm = "-outdir $shell_lib -prefix $prefix -suffix $suffix -absl $sh_absl";
	$split_comm .= $splitn ? " -splitn $splitn" : " -line $line";
	$splits && ($split_comm .= " -splits \"$splits\"");
	$absway && ($split_comm .= " -absway");
	my $line_end_sign = " ;date|awk '{print \$0,lxxx}' >>$logdir/${prefix}sxxx.$suffix; \#lxxx";
	if($focus){
		$split_comm .= " -head2 \">${focus}sxxx$fsuffix;";
		$focus2 || ($split_comm .= '"');
		$filter || ($middle .= " >>${focus}sxxx$fsuffix");
	}
	if($focus2){
		$split_comm .= $focus ? " >${focus2}sxxx$fsuffix2;\"" :
		" -head2 \">${focus2}sxxx$fsuffix2;\"";
		$filter || ($middle .= " 2>>${focus2}sxxx$fsuffix2");
	}
	if($end){
		(-s $end) && ($end = `less $end`);
		$end =~ s/\s*$/\n/;
		$end .= "date|awk '{print \$0,\"finish ${prefix}sxxx.$suffix\"}' >>$finish\n";
	}else{
		$end = "date|awk '{print \$0,\"finish ${prefix}sxxx.$suffix\"}' >>$finish\n";
	}
	$middle && (-s $middle) && chomp($middle = `less $middle`);
	if($reqline && $maycol){
		$middle .= $line_end_sign;
		$end =~ s/\n/$line_end_sign\n/g;
	}
	my ($headf,$middlef,$endf) = ("head.$$","middle.$$","end.$$");
	if($head){
		if(-s $head){$headf = $head;}else{open HE,">$headf";print HE $head;close HE;}
		$split_comm .= " -head $headf ";
	}
	if($middle){
		open MI,">$middlef";print MI $middle;close MI;
		$split_comm .= " -middle $middlef ";
	}
	open EN,">$endf";print EN "$end";close EN;
	$split_comm .= " -end $endf ";
	system"$file_split_pl $file $split_comm";
	foreach("head.$$","middle.$$","end.$$"){(-f $_) && `rm $_`;}
}
###################################################################################################
#sub2
#==============#
sub write_equip
#==============#
{
	my ($reqline,$reqcol,$sh_absl,$filter,$focus,$fsuffix,$focus2,$fsuffix2,$euq_file,$work_dir,$finish,
	$run_shelf,$err_shelf,$kill_sign,$kill_sh,$cleanf,$qsub_comm,$cpnode,$rewrite_pl,$deln,$fend,$qstat,
	$qalter,$logtxt) = @_;
	###  reqcol
	if($reqline && !(-s $reqcol)){
		open REC,">$reqcol";
		foreach(`less $sh_absl`){
			my @l = split/\s+/;
			print REC "$l[0] = $rewrite_pl $l[1] $logdir/$l[0] $deln\n";
		}
		close REC;
	}
	### sh_absl
	(-s $fend) && ($fend = `less $fend`);
	if($filter){
		chomp $filter;
		my @sh_way = `less $sh_absl`;
		open PATH,">$sh_absl";
		my $sh_num = 0;
		foreach(@sh_way){
			my @l = split/\s+/;
			open SHELL,">$work_dir/$l[0]";
			my $focuend;
			$focus && ($focuend .= " >>${focus}${sh_num}$fsuffix");
			$focus2 && ($focuend .= " 2>>${focus2}${sh_num}$fsuffix2");
			print SHELL "sh $l[1] | $filter $focuend\n";
			if($fend){
				my $fend0 = $fend;
				$fend0 =~ s/sxxx/$sh_num/g;
				print SHELL $fend0;
			}
			close SHELL;
			$sh_num++;
			print PATH "$l[0]\n";#\t$work_dir/$l[0]\n"; #we only need the shell name
		}
		close PATH;
	}
	## equ_file
	open EQU,">$equ_file";
	my $toequ = "workdir\t$work_dir\nshabsl\t$sh_absl\nfinish\t$finish\nrunsh\t$run_shelf\n";
	$toequ .= "errsh\t$err_shelf\nkillsign\t$kill_sign\nkillsh\t$kill_sh\nclean\t$cleanf\n";
	$reqline && ($toequ .= "reqcol\t$reqcol\n");
	$qsub_comm && ($toequ .= "qsub_comm\t$qsub_comm\n");
	$cpnode && @{$cpnode} && ($toequ .= "node\t@{$cpnode}\n");
	$qstat && ($toequ .= "qstat\t$qstat\n");
	$logtxt && ($toequ .= "logtxt\t$logtxt\n");
	print EQU $toequ;
	close EQU;
}
###################################################################################################
#sub3
#=============#
sub qsub_mutil
#=============#
#the sub function for qsub or mutil the tasks
{
	my ($equipment,$mutil,$work_dir,$temdir,$sh_absl,$run_shelf,$err_shelf,$finish,$killf,$kill_sh,$kill_sign,
	$cyqt,$sure,$sleept,$maxjob,$tasklim,$reqline,$reqcol,$qsub_comm,$cycle,$reqtime,$cpnode,$equ_file,
	$qstat,$qstat_pl,$shcontral_pl,$reqsub,$checke,$qalter,$maxvf,$novb,$wrong,$osure,$owrong) = @_;
	my ($cycle_num,$reqtime_num) = (1, 1);
	chdir"$work_dir";
	my $work_bname = (split/\//,$work_dir)[-1];
	my %run_job;
	(-s $run_shelf) && (%run_job = split/\s+/,`cut -f 2,1 $run_shelf`);   ## run_job_id -> run_shell
	my %err_sh;
	my $run_type = $mutil ? 'mutil' : 'qsub';
	if(-s $err_shelf){
		%err_sh = split/\s+/,`less $err_shelf`;                     ## err_shell -> err_job_id
		`rm $err_shelf`;
	}
	my @allsh;
	(-s $sh_absl) && chomp(@allsh = `awk '(\$1){print \$1}' $sh_absl`);                       ## all the shell should run
	my $all_num = @allsh;
	my $rnum = 0;
	my @run_sh;
	my $run_record;
	my %sh_job;
	if($equipment){
		%sh_job = (-s $run_shelf) ? (split/\s+/,$run_shelf) : (); #run_sh -> run_job_id
		check_err($mutil,\@allsh,$finish,\%sh_job,\@run_sh,\%err_sh,$cycle_num,$reqtime_num,$checke,$sure,$novb,$wrong,$osure,$owrong);  #sub3.3
	}
	get_unfinish(\@allsh,\@run_sh,$finish,\%err_sh);#sub3.1   ## all the shell unfinish or errfinish
	while(@run_sh || %err_sh){
		my $run_num = throw_job($work_dir,$mutil,\%run_job,\@run_sh,\%err_sh,$maxjob,$tasklim,$sleept,$qsub_comm,
		$kill_sh,$kill_sign,$run_shelf,$err_shelf,0,0,$reqline,$reqcol,$reqtime,\$reqtime_num,$cpnode,
		$cycle_num,$qstat,$qstat_pl,$all_num,\$rnum,$cyqt,$qalter,$maxvf,$novb,$equ_file); #sub3.2
		$novb || (print localtime() . " all the jobs at $work_bname/ have been thrown in queue at $run_type cycle $cycle_num\n");
		if($reqsub==3){
			`$shcontral_pl $finish $all_num 0 $sleept`;
			$novb || (print localtime() . " all the jobs at $work_bname/ have been finish at $run_type cycle $cycle_num\n");
			last;
		}
		while($run_num){
			$run_record = "";
			sleep($sleept);
            ($equ_file && -s $equ_file) && ($qsub_comm = {split/\t|\n/,`less $equ_file`}->{qsub_comm} || $qsub_comm);
			$run_num = throw_job($work_dir,$mutil,\%run_job,\@run_sh,\%err_sh,$maxjob,$tasklim,$sleept,$qsub_comm,
			$kill_sh,$kill_sign,$run_shelf,$err_shelf,1,$reqsub,$reqline,$reqcol,$reqtime,\$reqtime_num,$cpnode,
			$cycle_num,$qstat,$qstat_pl,$all_num,\$rnum,$cyqt,$qalter,$maxvf,$novb,$equ_file); #sub3.2
		}
		$novb || (print localtime() . " all the jobs at $work_bname/ have been finish at $run_type cycle $cycle_num\n");
		($reqsub==2) && last;
		%sh_job = (-s $run_shelf) ? (split/\s+/,$run_shelf) : ();
		check_err($mutil,\@allsh,$finish,\%sh_job,\@run_sh,\%err_sh,$cycle_num,$reqtime_num,$checke,$sure,$novb,$wrong,$osure,$owrong);  #sub3.3
		get_unfinish(\@allsh,\@run_sh,$finish,\%err_sh);#sub3.1   ## all the shell unfinish or errfinish
		$cycle_num++;
		if(@run_sh && ($cycle < $cycle_num)){
			my $err_record;
			foreach(@run_sh){$err_record .= "$_\t$sh_job{$_}\n";}
			open ERR,">$err_shelf";print ERR "$err_record\n";close ERR;
			print "Sorry! Your tasks have been reqsub more $cycle $run_type cycle, we will not continume.\n";
			print "Shell file: @run_sh do not finish, please chack them.\n";
			print "After checking the reeor, you can rerun the jobs use commend:\nperl $0 -equipment $equ_file\n";
			exit;
		}
	}
}
#sub3.1
##==============#
sub get_unfinish
##==============#
{
	#to get the shell isn't successfully finish to \@run_sh
	my ($allsh,$run_sh,$finish,$err_sh) = @_;
	my %finish_job = (-s $finish) ? 
	(split/\n/,`awk '{print \$NF\"\\n\"\$0}' $finish`) : ();
	my $real_finish;
	@{$run_sh} = ();
	foreach(@{$allsh}){
		($finish_job{$_} && !$err_sh->{$_}) ?
		($real_finish .= "$finish_job{$_}\n") : (push @{$run_sh},$_);
	}
	if($real_finish){
		open FIN,">$finish";print FIN $real_finish;close FIN;
	}else{
		`>$finish`;
	}
	%{$err_sh} = ();
}

#sub3.2
##===========#
sub throw_job
##===========#
{
	#to throw jobs and ruturn the number of running jobs
	my ($work_dir,$mutil,$id_sh,$run_sh,$err_sh,$maxjob,$tasklim,$sleept,$qsub_comm,$kill_sh,$kill_sign,$run_shelf,
	$err_shelf,$check,$reqsub,$reqline,$reqcol,$reqtime,$reqtime_num,$cpnode,$cycle,$qstat,$qstat_pl,$all_num,$rnum,
	$tc,$qalter,$maxvf,$novb,$equ_file) = @_;
	if(-s $kill_sign){    ## $kill_sh can force stop this process and kill all the tasks
		(-s $kill_sh) && `sh $kill_sh`;
		print localtime() . " Note: all the jobs have been force kill\n";
		goto ENN;
	}
	$check ||= 0; #check = 0 to check run_num, check = 1 to throw tasks and ruturn run_num
	my ($able_num,$run_num) = (0, 0);   ## the number allow to throw jobs, number of running jobs
	while(@{$run_sh} || %{$err_sh} || $check){
		$check = 0;
		my $run_record;
		($able_num,$run_num) =	$mutil ?
		able_job_ps($work_dir,$maxjob,$tasklim,$id_sh,$err_sh,$run_shelf,$err_shelf,$kill_sh,$reqsub,
		$reqline,$reqcol,$reqtime,$reqtime_num,$cycle,$all_num,$rnum,$tc,\$run_record,$novb) :  #sub3.2.2
		able_job_qstat($qsub_comm,$maxjob,$tasklim,$id_sh,$err_sh,$run_shelf,$err_shelf,$kill_sh,$reqsub,$reqline,
		$reqcol,$reqtime,$reqtime_num,$cpnode,$cycle,$all_num,$rnum,$tc,\$run_record,$qalter,$work_dir,$maxvf,$novb,$equ_file);   #sub3.2.1
		if($able_num <= 0){
			if($able_num == -1){    ### 系统无反应
				($reqtime >= $$reqtime_num)	?
				(($novb || (print "Error: System have not reflect at reqtime $$reqtime_num, cycle $cycle\n")),$$reqtime_num++) :
				((print "Error: System have not reflect at reqtime $$reqtime_num, cycle $cycle we will not continue\n"),exit);
			}
			sleep($sleept);
			next;
		}
		!$novb && @{$run_sh} &&
		(print localtime() . " at reqtime $$reqtime_num, cycle $cycle throw tasks:\n");
		if($mutil){
			my %tem_resh;
			foreach(1..$able_num){
				@{$run_sh} || last;
				my $shfile = shift @{$run_sh};
				system"nohup sh $work_dir/$shfile > $shfile.o 2> $shfile.e &";
				$tem_resh{"sh $work_dir/$shfile"} = $shfile;
				$novb || (print "$shfile\n");
			}
			if(%tem_resh){
				foreach(`/bin/ps x | grep \"$work_dir\"`){
					s/^\s+|\s+$//g;
					my ($job_id,$comm) = (split/\s+/,$_,5)[0,-1];
					$tem_resh{$comm} || next;
					$id_sh->{$job_id} = $tem_resh{$comm};
					$run_record .= "$job_id\t$tem_resh{$comm}\n";
					$run_num++;$able_num--;
				}
			}
		}else{
			foreach(1..$able_num){
				@{$run_sh} || last;
				my $shfile = shift @{$run_sh};
				my $tem_node = node_sel($cpnode);#sub 3.2.1.3
				my $job_id = (split/\s+/,`$qsub_comm $tem_node $shfile`)[2];
				$run_record .= "$job_id\t$shfile\n";
				$run_num++;$able_num--;
				$novb || (print "$shfile\t$job_id\n");
			}
		}
		$run_record ? re_record($run_record,$run_shelf,$id_sh,$kill_sh,$mutil,$cycle,$reqtime_num,$novb,$all_num,
		$rnum,$tc,0,$qstat,$qstat_pl,$qalter,$maxvf,$work_dir,$reqline,$reqcol,$qsub_comm,$cpnode,$equ_file) : #sub3.2.1.4
		(%{$id_sh} = ());       #no shell running so del the hash
		(@{$run_sh} || %{$err_sh}) && sleep($sleept);
	}
	$run_num;
}

#sub3.2.1
###==============#
sub able_job_qstat
###==============#
{
	#return able_number to throw task and running tasks number, err tasks will reqsub
	my ($qsub_comm,$maxjob,$tasklim,$id_sh,$err_sh,$run_shelf,$err_shelf,$kill_sh,$reqsub,
	$reqline,$reqcol,$reqtime,$reqtime_num,$cpnode,$cycle,$all_num,$rnum,$tc,$run_record,
	$qalter,$workdir,$maxvf,$novb,$equ_file) = @_;
	chomp(my $user = `whoami`);
	my $qstat_result = (`qstat -u $user` || 0);
	$qstat_result || return($maxjob,0);
	($qstat_result =~ /failed receiving gdi request/) && ($_[-1]++,return(-1,0)); ##系统无反应
	my @jobs = split /\n/,$qstat_result;
	shift @jobs;shift @jobs;                 ##remove the first two title lines
	my $toal_job_num = $tasklim - @jobs;
	my $curr_job_num = 0;
	my %died = &died_nodes;#sub3.2.1.1       ##the compute node is down, 有的时候节点已死，但仍然是正常状态
	foreach(@jobs){
		s/^\s+//;
		my @job_field = (split/\s+/)[0,4,7];
		if ($id_sh->{$job_field[0]}){
			## current date node to be: compute-0-0, login-0-0 or supermem-0-0
			my $node_name = $1 if($job_field[2] =~ /\@(\S+-\d+-\d+)/); 
			if (($node_name && $died{$node_name}) || $job_field[1]=~/E/ || $job_field[1]=~/s/i ||
			$job_field[1]=~/d/ || $job_field[1]=~/T/){ #qusb-seq.pl use $job_field[4] eq r,t or qw
				$err_sh->{$id_sh->{$job_field[0]}} = $job_field[0];
				`qdel $job_field[0]`;
			}else{
				$$run_record .= "$job_field[0]\t$id_sh->{$job_field[0]}\n";
				$curr_job_num++;
			}
		}
	}
	if(!$reqsub && $err_sh && %{$err_sh}){
		my %recolh;
		$reqline && (%recolh = split/\s+=\s+|\n/,`less $reqcol`);
		if($reqtime >= $$reqtime_num){
            my %qstath = ($qstat && -s $qstat) ? split/\s+/,`awk '(NF>8){print \$2,\$9}' $qstat` : ();
			foreach(keys %{$err_sh}){
				del_oe($_,$err_sh->{$_});          ## sub3.2.1.2
				$reqline && `$recolh{$_}`;          ## rewrite the key file
				my $tem_node = node_sel($cpnode);  ## sub 3.2.1.3
				my $qsub_comm0 = $qsub_comm;
				if($qalter && $qstath{$_}){
					my $maxvmem = $qstath{$_};
                    ($maxvmem ne 'N/A') && ($qsub_comm0 =~ s/\bvf=\S+/vf=$maxvmem/);
				}
				my $job_id = (split/\s+/,`$qsub_comm0 $tem_node $_`)[2];
				$$run_record .= "$job_id\t$_\n";
				$curr_job_num++;
				$novb || (print localtime() . " reqsub task $job_id $_ at qsub reqtime $$reqtime_num, cycle $cycle\n");
			}
			%{$err_sh} = ();
			$$reqtime_num++;
		}else{
			my $err_record;
			foreach(keys %{$err_sh}){$err_record .= "$_\t$err_sh->{$_}\n";}
			open ERR,">$err_shelf";print ERR "$err_record\n";close ERR;
			$$run_record ? re_record($$run_record,$run_shelf,$id_sh,$kill_sh,$mutil,$cycle,$reqtime_num,$novb,
			$all_num,$rnum,$tc,1,$qstat,$qstat_pl,$qalter,$maxvf,$work_dir,$reqline,$reqcol,$qsub_comm,$cpnode,$equ_file) : #sub3.2.1.4
			(`>run_shelf`,%{$id_sh} = ()); #no shell running and process die, so del the shell file
			say_sorry($id_sh,$err_sh,$reqtime,$cycle,$equ_file); #sub3.2.1.5
		}
	}
	my $able_num = $maxjob - $curr_job_num;
	($toal_job_num < $able_num) && ($able_num = $toal_job_num);
	($able_num < 0) && ($able_num = 0);
	($able_num,$curr_job_num);
}
#sub3.2.1.1
#####=========#
sub died_nodes
#####=========#
##HOSTNAME	ARCH	NCPU  LOAD  MEMTOT  MEMUSE  SWAPTO  SWAPUS
##compute-0-24 lx26-amd64 8 - 15.6G - 996.2M -
{
	my $die_node =
	(`qhost | awk '{x++}(x>3 && (\$4~/-/ || \$5~/-/ || \$6~/-/ || \$7~/-/)){print \$1,1}'` || 0);
	$die_node ? (split/\s+/,$die_node) : ();
}
#sub3.2.1.2
####=======#
sub del_oe
####=======#
{
	my ($shelf,$job_id) = @_;
	my $ko = 1;
	foreach("$shelf.o$job_id","$shelf.e$job_id"){(-f $_) && (`rm $_`,$ko=0);}
	if($ko && $job_id && $job_id eq '3'){
        chomp(my @of =  `ls $shelf.o* $shelf.e* 2>/dev/null` || ());  ##job_id eq 3 is the job can't find .e file
        foreach(@of){(-f $_) && `rm $_`;}
    }
}
#sub3.2.1.3
####========#
sub node_sel
####========#
{
	($_[0] && @{$_[0]}) || return(" ");
	my $n = shift @{$_[0]};
	push @{$_[0]},$n;
	"-l h=$n";
}
#sub3.2.1.4
####==========#
sub re_record
####==========#
{
	my ($run_record,$run_shelf,$id_sh,$kill_sh,$mutil,$cycle,$reqtime,$novb,$all_num,$rnum,$tc,
	$stop,$qstat,$qstat_pl,$qalter,$maxvf,$work_dir,$reqline,$reqcol,$qsub_comm,$cpnode,$equ_file) = @_;
	my ($run_id, $new_runsh);
	my $kqdel = $mutil ? 'kill' : 'qdel';
	%{$id_sh} = split/\s+/,$run_record;
	if($stop){
		$new_runsh = $run_record;
        foreach(keys %{$id_sh}){$run_id .= "$_ ";};
	}elsif(-s $run_shelf){
		my %sh_id = split/\s+/,`awk '{print \$2,\$1}' $run_shelf`;
		foreach(keys %{$id_sh}){$sh_id{$id_sh->{$_}} = $_;$run_id .= "$_ ";}
		foreach(keys %sh_id){$new_runsh .= "$sh_id{$_}\t$_\n";}
	}else{
		foreach(keys %{$id_sh}){$new_runsh .= "$_\t$id_sh->{$_}\n";$run_id .= "$_ ";}
	}
	if(!($$rnum % $tc)){
		$run_id =~ s/^\s+|\s+$//g;
		my $f_num = (split/\s+/,$run_id);
		$novb || (print localtime() . " at reqtime $$reqtime, cycle $cycle in queue: $f_num/$all_num\n");
		if(!$mutil && ($qstat || $qalter)){
			my $locatime;
			my $tem_qstat = (`$qstat_pl $run_id` || 0);
			$qstat && $tem_qstat && ($locatime = localtime(), print ME "#$locatime\n$tem_qstat\n");
			if($qalter && $tem_qstat){
				my %recolh;
				$reqline && (%recolh = split/\s+=\s+|\n/,`less $reqcol`);
#				foreach(`echo "$tem_qstat" | awk '(!/^#/ && !/^-/ && \$1){print \$1,\$2,\$3,\$4,\$5}'`){
				foreach(`echo "$tem_qstat" | awk '(!/^#/ && !/^-/ && \$1){print \$1,\$2,\$7,\$8,\$9}'`){###2014-8-18
					my @l = split/\s+/;
					($l[3] eq 'N/A') && next;
					($maxvf && real_bit($l[3]) - real_bit($l[2]) > $maxvf) || next;
					my $qsub_comm0 = $qsub_comm;
					$qsub_comm0 =~ s/\bvf=\S+/vf=$l[4]/;
                    $equ_file && (-f $equ_file) && `echo \"qsub_comm\t$qsub_comm0\" >> $equ_file`;
					del_oe(@l[1,0]);          ## sub3.2.1.2
					$reqline && `$recolh{$l[1]}`;          ## rewrite the key file
					my $tem_node = node_sel($cpnode);  ## sub 3.2.1.3
					`qdel $l[0]`;
					my $job_id = (split/\s+/,`$qsub_comm0 $tem_node $work_dir/$l[1]`)[2];
					delete $id_sh->{$l[0]};$id_sh->{$job_id} = $l[1];
					$new_runsh =~ s/\b$l[0]\t$l[1]\n/$job_id\t$l[1]\n/;
					$run_id =~ s/\b$l[0]\b/$job_id/;
					$novb || (print "Note: at reqtime $$reqtime, cycle $cycle memory overbrim in $l[1], we change vf=$l[2] to vf=$l[3]\n");
				}
			}
		}
	}
	open RSH,">$run_shelf";print RSH $new_runsh;close RSH;
	`echo \"$kqdel $run_id\" > $kill_sh`;
	$$rnum++;
}
#sub3.2.1.4.1
#####========#
sub real_bit
#####========#
{
	my $vf = uc($_[0]);
	($vf=~/^(\S+)([BKMGT])/) || return($vf);
	my %h = ('B',1,'K',1000,'M',10**6,'G',10**9,'T',10**12);;
	$1 * $h{$2};
}

#sub3.1.1.5
####=========#
sub say_sorry
####=========#
{
	#usage: say_sorry($id_sh,$err_sh,$reqtime,$cycle,$equ_file);
	my ($id_sh,$err_sh,$reqtime,$cycle,$equ_file) = @_;
	my (@over_err,@over_sh);
	$id_sh && %{$id_sh} && (@over_sh = values %{$id_sh});
	$err_sh && %{$err_sh} && (@over_err = keys %{$err_sh});
	my $say_sorry = 
	localtime() . " Sorry!! Your tasks have been reqsub more then $reqtime times cycle $cycle,";
	$say_sorry .= " we will not continume.\n";
	@over_err && ($say_sorry .= "There may be some errors at @over_err, please check them\n");
	@over_sh && ($say_sorry .= "Shell file: @over_sh are still running\n");
	$say_sorry .= "After checking the reeor, you can rerun the jobs use commend:\nperl $0 -equipment $equ_file\n";
	print $say_sorry;
	exit;
}
#sub3.2.2
###============#
sub able_job_ps
###============#
{
	my ($work_dir,$maxjob,$tasklim,$id_sh,$err_sh,$run_shelf,$err_shelf,$kill_sh,$reqsub,
	$reqline,$reqcol,$reqtime,$reqtime_num,$cycle,$all_num,$rnum,$tc,$run_record,$novb) = @_;
	chomp(my @jobs = `/bin/ps x | awk '(\$1~/^[0-9]/){print \$1,\$3}'`);
	@jobs || return(-1,0);                            ## 系统无反应
	my $toal_job_num = $tasklim - @jobs;
	my $curr_job_num = 0;
	foreach(@jobs) {
		my ($job_id,$state) = split/\s+/;
		if($id_sh->{$job_id}){
			if($state eq 'Z' || $state eq 'X'){
				$err_sh->{$id_sh->{$job_id}} = $job_id;
				`kill $job_id`;
			}else{
				$$run_record .= "$job_id\t$_\n";
				$curr_job_num++;
			}
		}
	}
	if(!$reqsub && %{$err_sh}){
		my (%recolh,%tem_resh);
		$reqline && (%recolh = split/\s+=\s+|\n/,`less $reqcol`);
		if($reqtime >= $$reqtime_num){
			foreach(keys %{$err_sh}){
				$reqline && `$recolh{$_}`;             # rewrite the key file
				system"sh $work_dir/$_ > $_.o 2>$_.e &";
				$tem_resh{"sh $work_dir/$_"} = $_;
				$novb || (print localtime() . " reqline task $_ at bgrun reqtime $$reqtime_num, cycle $cycle\n");
			}
			foreach(`/bin/ps x | gerp \"sh $work_dir\"`){
				s/^\s+|\s+$//g;
				my ($job_id,$comm) = (split/\s+/,$_,5)[0,-1];
				$tem_resh{$comm} || next;
				$id_sh->{$job_id} = $tem_resh{$comm};
				$$run_record .= "$job_id\t$tem_resh{$comm}\n";
				$curr_job_num++;
			}
			%{$err_sh} = ();
			$$reqtime_num++;
		}else{
			my $err_record;
			foreach(keys %{$err_sh}){$err_record .= "$_\t$err_sh->{$_}\n";}
			open ERR,">$err_shelf";print ERR "$err_record\n";close ERR;
			$$run_record ? re_record($$run_record,$run_shelf,$id_sh,$kill_sh,$mutil,$cycle,$reqtime_num,$novb,$all_num,$rnum,$tc,1) : #sub3.2.1.4
			(`>run_shelf`,%{$id_sh} = ()); #no shell running and process die, so del the shell file
			say_sorry($id_sh,$err_sh,$reqtime,$cycle,$equ_file); #sub3.2.1.5
		}
	}
	my $able_num = $maxjob - $curr_job_num;
	($toal_job_num < $able_num) && ($able_num = $toal_job_num);
	($able_num < 0) && ($able_num = 0);
	($able_num,$curr_job_num);
}

#sub3.3
##===========#
sub check_err
##===========#
{
	my ($mutil,$allsh,$finish,$sh_job,$run_sh,$err_sh,$cycle_num,$reqtime,$checke,$sure,$novb,$wrong,$osure,$owrong) = @_;
	my %finh = split/\s+/,`awk '{print \$NF,1}' $finish`;
	my $run_type = $mutil ? 'mutil' : 'qsub';
	my @unfsh;
	foreach(@{$allsh}){
		my $be_err = 0;
		##read finish file
		if(!$finh{$_}){
			#push @{$run_sh},$_;
			push @unfsh,$_;
			$be_err=1;
		}
		($checke || $osure || $owrong) || ($sh_job->{$_} ||= $be_err,next);
		##read the .o and .e file
		my ($e_job,$o_job);
		$mutil ? (($e_job,$o_job) = ("$_.e","$_.o")) :
		$sh_job->{$_} ? (($e_job,$o_job) = ("$_.e$sh_job->{$_}","$_.o$sh_job->{$_}")) :
		(chomp($e_job = (`ls $_.e* | tail -1` || 0)), chomp($e_job = (`ls $_.e* | tail -1` || 0)));## some jobs may finish before checking
		##check .o file
		if($o_job && (-f $o_job)){
			!$mutil && !$sh_job->{$_} && ($o_job =~ /$_\.o(\d+)/) && ($sh_job->{$_} = $1);
			(-s $o_job) || ((-s $e_job) ? (goto CHE) : next);
			my $ocontent = `less $o_job`;
			if($osure && $ocontent !~ m#(o$sure)#) {
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, \"$1\" isn't found, so this work may be unfinished\n");
				$be_err=2;
			}
			if ($owrong && $ocontent =~ m#($owrong)#){
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, \"$1\" is found, so this work may be unfinished\n");
				$be_err=2;
			}
		}else{
			#$be_err || (push @{$run_sh},$_);
			$err_sh->{$_} = ($sh_job->{$_} || 1);
			$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, $_ can't find .o file\n");
			$be_err=3;
		}
		if(!$checke){
			#$sh_job->{$_} ||= $be_err;
			$be_err && ($err_sh->{$_} = ($be_err==3) ? 3 : $sh_job->{$_});
			$err_sh->{$_} = ($sh_job->{$_} || 1);
			next;
		}
		CHE:{;}
		## check .e file
		if($e_job && (-f $e_job)){
			!$mutil && !$sh_job->{$_} && ($e_job =~ /$_\.e(\d+)/) && ($sh_job->{$_} = $1);
			(-s $e_job) || next;
			my $content = `less $e_job`;
			##check whether the C/C++ libary is in good state
			if ($content =~ /GLIBCXX_3.4.9/ && $content =~ /not found/) {
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, GLIBCXX_3.4.9 not found, so this work may be unfinished\n");
				$be_err=2;
			}
			##check whether iprscan is in good state
			if ($content =~ /iprscan: failed/) {
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, iprscan: failed, so this work may be unfinished\n");
				$be_err=2;
			}
			##check the user defined job completion mark
			if ($sure && $content !~ m#($sure)#) {
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, \"$1\" isn't found, so this work may be unfinished\n");
				$be_err=2;
			}
			if ($wrong && $content =~ m#($wrong)#){
				#$be_err || (push @{$run_sh},$_);
				$err_sh->{$_} = ($sh_job->{$_} || 1);
				$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, In $e_job, \"$1\" is found, so this work may be unfinished\n");
				$be_err=2;
			}
		}else{
			#$be_err || (push @{$run_sh},$_);
			$err_sh->{$_} = ($sh_job->{$_} || 1);
			$novb || (print "In $run_type reqtime $reqtime cycle $cycle_num, $_ can't find .e file\n");
			$be_err=3;
		}
		#$sh_job->{$_} ||= $be_err;
		$be_err && ($err_sh->{$_} = ($be_err==3) ? 3 : $sh_job->{$_});
		$err_sh->{$_} = ($sh_job->{$_} || 1);
	}
	@unfsh && !$novb && (print "In $run_type reqtime $reqtime cycle $cycle_num, shell file: @unfsh unfinish\n");
}
#sub3.1
##############
sub abs_path
##############
{
    my $file = $_[0];
    chomp(my $current_dir = `pwd`);
    if($file !~/^\//){
        $file = "$current_dir/$file";
    }
    $file;
}

sub mul_path
{
    my @a = split/\s+/,$_[0];
    foreach(@a){
        (/^\//) && next;
        (/^(\.{1,2}\/)/) && ($_ = abs_path($_), next);
        ($_ eq '.' || $_ eq '..') && next;
        ((-f $_) || (-d $_)) && ($_ = abs_path($_), next);
        (/^([12]?>{1,3}&?)([^>&]+)/) && ($_ = $1 . abs_path($2));
    }
    $_[0] = join(" ",@a);
}
