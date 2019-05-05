#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my %opt= (rank=>"1,3,4,5",cluster_range=>"0.001,0.1",cover_cut=>0.5,outdir=>".",prefix=>"all",cpu=>80,blast_vf=>"15G",
    run=>"qsub",len=>200,blast_opts=>"-e 1e-5 -F F -b 5",mega_opts=>"-p 0.8 -b 5 -v 5"); #,qopts=>'-P mgtest -q bc.q');
GetOptions(\%opt,"rank:s","cluster_range:s","cover_cut:f","prefix:s","select:s","cpu:i","outdir:s","blast_vf:s",
    "qopts:s","run:s","len:i","blast_opts:s","gidTaxid:s","name:s","node:s","ntdb:s","megablast","mega_opts:s",
    "shdir:s","subdir:s","ntdir:s","top:i","add_num:i","seq_lim:f","wgs","lisdir:s");
#==================================================================================================================
## script pathway
my $blastall = "/PUBLIC/software/public/Alignment/blast-2.2.26/bin/blastall"; #SZ & HK,  "/opt/bio/ncbi/bin/blastall";#SZ
my $megablast = "/PUBLIC/software/public/Alignment/blast-2.2.26/bin/megablast";#HK and SZ
$blastall = $opt{megablast} ? "$megablast $opt{mega_opts}" : "$blastall -p blastn $opt{blast_opts}";
my $ntdb0 = "/PUBLIC/database/Common/NT/nt_20141019/nt";
#my $ntdb0 = "/PUBLIC/database/Common/NT/nt.new";
#my $ntdb0 = "/PROJ/GR/share/MICRO/USER/liuwenbin/database/NT/nt";
#(-s "$ntdb0") || ($ntdb0 = "/ifs1/pub/database/ftp.ncbi.nih.gov/blast/db/20130904/nt");
my $ntdb = ($opt{ntdb} || $ntdb0);
(-s "$ntdb.00.nhr") || die"error: can't find NT database: $ntdb, $!";
foreach('extract_seq.pl','add_taxid2.pl','blast_tax_stat.pl','super_worker.pl','cut_seq.pl','tax_cover.pl'){
    (-s "$Bin/$_") || die"error: can't find script $_ at $Bin, $!";
}
my ($extract_seq_p,$add_taxid_p,$classify_p,$super_worker_p,$cut_seq_p,$tax_cover_p) =
("perl $Bin/extract_seq.pl",
 "perl $Bin/add_taxid2.pl",
 "perl $Bin/blast_tax_stat.pl",
 "perl $Bin/super_worker.pl",
 "perl $Bin/cut_seq.pl",
 "perl $Bin/tax_cover.pl"
);
($opt{run} ne 'qsub') && ($super_worker_p .= " --mutil");
$opt{qopts} && ($super_worker_p .= " --splitn $opt{cpu} --qopts=\"$opt{qopts}\"");
#==================================================================================================================
#print @ARGV,"\n";
#exit;
## usage:
(@ARGV==2 || @ARGV==1) || die "Name: run_nt_2.3.pl
Description: script to extract enthetic sequence from assembly result wiht GC-depth info, and blast them to NT
  to find the enthetic species.
Author: BC_MG, megar some connected script by liuwenbin
Version: 1.0  Data: 2011-12-28
Version: 2.0  Data: 2012-06-22,  infile can be a list to fit population
Version: 2.3  Data: 2012-07-07,  Updata the database
Usage: perl run_nt_2.3.pl <refreance.fa> [GC_depth.node.cluster] [-options]
    refreance.fa           inputfile of assembly result
    GC_depth.node.cluster  GC_depth cluster result, to select nonuniformity sequence, when ignore select all ref.
    --add_num <num>        add specified number of main scaffolds to outseq file.
    --seq_lim <flo>        limit the size of add scaffold(Kb), default the whold sequence.
    --wgs                  use the whold genomics for nt blast alignment, not selected portion even some parameters set.
    --prefix <str>         outfile prefix, default=all
    --outdir <dir>         subfile output directory, default=.
    --lisdir <dir>         set list directory name and stat multi sample meger info in it
    --shdir <dir>          directory for running shell file, default=outdir/Shell
    --rank <str>           the ranks of: seq_id GC% Depth [cluster_num], star form 0, defalt=1,3,4,5
    --select <str>         conditions to select enthetic sequence write in awk form, e.g: --select '\$4>60 && \$5>300'
                           means select GC%>60% and Depth>300X region, default select according to cluster_num.
    --cluster_range <str>  cluster_num frequence range see the cluster as enthetic, default=0.001,0.1
    --cover_cut <flo>      sequence enthetic coverage cutoff to selected out, defaut=0.5
    --blast_opts <str>     blast options, default='-e 1e-5 -F F -b 5'
    --megablast            use megablast instead of blastall, it maybe run faster
    --mega_opts <str>      megablast options, default='-p 0.8 -b 5 -v 5'
    --len <num>            blast m8 match min length, defualt=200
    --top <num>            output specified number of besthit for eatch scaffold, default=10
    --cpu <num>            thread for the process, default=80
    --run <str>            run type, qsub or mutil, default=qsub
    --blast_vf <str>       resultce for qsub blast m8, defalt=15G
    --qopts <str>          other qsub options, default=''
    --ntdb <file>          NT database, default=/PUBLIC/database/Common/NT/nt_20141019/nt
    --gidTaxid <file>      gi_taxid_nucl.dmp from NCBI taxonomy, default 20141020 version
    --name <file>          names.dmp from NCBI taxonomy, default 20141020 version
    --node <file>          nodes.dmp from NCBI taxonomy, default 20141020 version
Example:
    perl run_nt_2.3.pl NLH.fasta --cpu 10 --qopts='-P mgtest -q bc.q'
    perl run_nt_2.3.pl NLH.fasta GC_depth.node.cluster --cpu 10 --qopts='-P mgtest -q bc.q' --megablast\n\n";
#==================================================================================================================
## check error:
#foreach(@ARGV){(-s $_) || die"error: can't find valid file $_, $!\n";}
(-s $ARGV[0]) || die"error: can't find valid file $ARGV[0], $!\n";
($ARGV[1] && -s $ARGV[1]) || ($ARGV[1] = "");
foreach("extract_seq.pl","super_worker.pl","classifyBaseOnTaxonomy.pl","add_taxid.pl"){
    (-s "$Bin/$_") || die"error: can't find $_ at $Bin, $!\n";
}
my ($ref,$node) = @ARGV;
$opt{wgs} && ( ($node,$opt{add_num},$opt{seq_lim}) = (0, 0, 0) );
foreach($node,$ref,$opt{outdir},$opt{gidTaxid},$opt{name},$opt{node}){$_ &&= &abs_path($_);}#sub1
foreach(qw(gidTaxid name node len top)){$opt{$_} && ($add_taxid_p .= " --$_ $opt{$_}");}
#==================================================================================================================
## main process:
#step1 extract enthetic sequence from assembly result
(-d $opt{outdir}) || mkdir($opt{outdir});
$opt{shdir} ||= "$opt{outdir}/Shell";
$opt{outdir} = abs_path($opt{outdir});
my (@moutf,@outf,@samp);
my (%ref,%node);
if(`head -1 $ref`=~/(\S+)\s*=?\s*(\S+)/ && -s $2){
    %ref = split/[\s=]+/,`less $ref`;
    $node && (%node = split/[\s=]+/,`less $node`);
    push @samp,keys %ref;
}elsif(-s $ref){
    $ref{all} = $ref;
    $node && ($node{all} = $node);
    push @samp,'all';
}
else {
	warn "error input seq file of $ref or in $ref. Seq empty or do not exist. Running NT exit\n"; exit;
}
my (@outdir,@blast_dir);
my $extract_opts = " ";
foreach(qw(rank cluster_range cover_cut)){$opt{$_} && ($extract_opts .= " --$_ $opt{$_}");}
$opt{select} && ($extract_opts .= " --select '$opt{select}'");
my (@enthetic,@del_seq);
my $i = 0;
if(@samp > 1 && $opt{cpu} > 1){
	my $seq_cut_num = int($opt{cpu} / @samp);
	($opt{cpu} > @samp * $seq_cut_num) && ($seq_cut_num++);
	$opt{cpu} = $seq_cut_num;
}
foreach(@samp){
    my ($node0,$ref0,$outd) = ($node{$_} || 0, $ref{$_},$opt{outdir});
    ($_ ne 'all') && ($outd .= "/$_");
    $opt{subdir} && ($outd .= "/$opt{subdir}");
    $opt{ntdir} && ($outd .= "/$opt{ntdir}");
    (-d $outd) || `mkdir -p $outd`;
    push @outdir,$outd;
    my $extract_opts0 = $extract_opts . " --outfile $outd/$_.ext.fa";
    my ($run_seq_cut,$outf);
    if($opt{cpu}==1 && !$opt{add_num}){
        $outf = $node ? "$outd/$_.ext.fa" : $ref0;
        push @blast_dir,$outd;
    }else{
        $outf = "$outd/fa_cut";
        (-d "$outd/blast_out") || mkdir"$outd/blast_out";
        push @blast_dir,"$outd/blast_out";
        if($node){
           $extract_opts0 .= " --outdir $outd/fa_cut --cut_num $opt{cpu}";
           foreach(qw(seq_lim add_num)){$opt{$_} && ($extract_opts0 .= " --$_ $opt{$_}");}
        }else{
            $run_seq_cut = "$cut_seq_p $ref0 $opt{cpu} $_ $outd/fa_cut 2> $outd/log";
            foreach(qw(seq_lim add_num)){$opt{$_} && ($run_seq_cut .= " --$_ $opt{$_}");}
        }
    }
    $opt{add_num} && ($del_seq[$i] = "$outd/log");
    push @moutf,[$outf];
    $run_seq_cut ? system"$run_seq_cut" : system"$extract_seq_p $node0 $ref0 $extract_opts0 2> $outd/log";
    if(!(-s $outf)){
        $enthetic[$i] = 1;
        warn "Note: $_ has no enthetic sequence according to GC-depth\n";
    }
    $i++;
}
#==================================================================================================================
##step2 add taxid
foreach(@moutf){
    if(-d $_->[0]){
        chomp(@{$_} = `ls $_->[0]/*.fa`);
    }
}
(-d $opt{shdir}) || mkdir($opt{shdir});
foreach(qw(scaff organism)){$opt{$_} && ($classify_p .= " --$_ $opt{$_}");}
my @cf = ('nt_blast.scaffold.cover.xls','tax_organism.cover.xls','organism.cover.xls','max_tax_organism');
my @max_org;
open SH,">$opt{shdir}/run_blast.sh";
open CL,">$opt{shdir}/run_nt_cover.sh";
foreach my $i(0..$#moutf){
    $enthetic[$i] && next;
    my @outf = @{$moutf[$i]};
    foreach(0..$#outf){
        print SH "cd $blast_dir[$i]\n$blastall -d $ntdb -i $outf[$_] -m 8 -o blast.$_.m8\n",
        "$add_taxid_p blast.$_.m8 -out blast.$_.m8.tax\n\n";
        $outf[$_] = "$blast_dir[$i]/blast.$_.m8";
    }
    my $copt = " --len $ref{$samp[$i]}";
    if($samp[$i] ne 'all'){
        $copt .= " -samp_name $samp[$i]";
        $opt{lisdir} && (push @max_org,[$samp[$i],"$outdir[$i]/$cf[3]"]);
    }
    $node && $del_seq[$i] && ($copt .= " --scaff $del_seq[$i]");
    print CL "cd $outdir[$i]; $classify_p $copt blast.m8.tax -tax_cover $cf[1] --spe_cover $cf[2] --main $cf[3] > $cf[0]\n";
    @{$moutf[$i]} = @outf;
}
close SH;
close CL;
my $splits = '\n\n';
system"cd $opt{shdir}; $super_worker_p run_blast.sh -splits \"$splits\" -resource $opt{blast_vf} --prefix ntblast --sleept 100";
#my ($rn,$blast_out) = (0,"$opt{outdir}/blast.m8.tax");
my $rn = 0;
foreach my $i(@moutf){foreach(@{$i}){(-s $_) && ($rn = 1);}}
$rn || die"Note: can't find enthetic sequence\n";
my @blast_out;
foreach my $i(0..$#samp){
    $enthetic[$i] && next;
    my ($bout1,$bout2) = ("$outdir[$i]/blast.m8","$outdir[$i]/blast.m8.tax");
    foreach($bout1,$bout2){(-s $_) && `rm $_`;}
    if($opt{cpu}==1 && !$opt{add_num}){
        (-s "$blast_dir[$i]/blast.0.m8.tax") && system"mv $blast_dir[$i]/blast.0.m8.tax $bout2";
        (-s "$blast_dir[$i]/blast.0.m8") && system"mv $blast_dir[$i]/blast.0.m8 $bout1";
    }else{
        foreach(@{$moutf[$i]}){
            (-s $_) && `cat $_ >> $bout1`;
            (-s "$_.tax") && `cat $_.tax >> $bout2`;
        }
        (-d "$blast_dir[$i]/../fa_cut") && `rm -r $blast_dir[$i]/../fa_cut`;
        (-d $blast_dir[$i]) && `rm -r $blast_dir[$i]`
    }
    system"$tax_cover_p $bout2 $ref{$samp[$i]} > $outdir[$i]/tax_organism.complex.xls";
}
#==================================================================================================================
#step3 classify
if(@samp > 20){
    system"cd $opt{shdir};$super_worker_p run_nt_cover.sh -resource 0.2g --prefix ntclass --sleept 30";
}else{
    system"sh $opt{shdir}/run_nt_cover.sh > $opt{shdir}/run_nt_cover.sh.o 2> $opt{shdir}/run_nt_cover.sh.e";
}
$opt{lisdir} || exit;
(-d $opt{lisdir}) || mkdir($opt{lisdir});
foreach my $f(@cf[0..2]){
    my $of = "$opt{lisdir}/$f";
    (-f $of) && `rm $of`;
    foreach my $d(@outdir){
        (-s "$d/$f" && (split/\s+/,`wc -l $d/$f`)[0] > 1) || next;
        (-s $of) ? `awk 'NR>1' $d/$f >> $of` : `cp $d/$f $of`;
    }
}
open CF,">$opt{lisdir}/$cf[3]" || die$!;
foreach(@max_org){
    print CF $_->[0],"\t",`less $_->[1]`;
}
close CF;
#==================================================================================================================
## SUB:
#sub1
sub abs_path{
    chomp(my $temdir = `pwd`);
    ($_[0] =~ /^\//) ? $_[0] : "$temdir/$_[0]";
}
