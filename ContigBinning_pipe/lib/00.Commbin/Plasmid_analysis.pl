#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my %opt= (rank=>"1,3,4,5",cluster_range=>"0.001,0.1",cover_cut=>0.5,outdir=>".",prefix=>"all",cpu=>1,blast_vf=>"2G",
    run=>"qsub",blast_opts=>"-e 1e-5 -F F -b 5",mega_opts=>"-p 0.8 -b 5 -v 5",#qopts=>'-P mgtest -q bc.q',
    len=>50,ident=>0.6);
GetOptions(\%opt,"rank:s","cluster_range:s","cover_cut:f","prefix:s","select:s","cpu:i","outdir:s","blast_vf:s",
    "qopts:s","run:s","len:i","blast_opts:s","ident:f","plasmdb:s","megablast","mega_opts:s",
    "shdir:s","subdir:s","pldir:s","top:i","add_num:i","seq_lim:f","wgs","lisdir:s","cover:f");
#==================================================================================================================
## script pathway
my $blastall = "Alignment/blast-2.2.26/bin/blastall";
my $megablast = "Alignment/blast-2.2.26/bin/megablast";
$blastall = $opt{megablast} ? "$megablast $opt{mega_opts}" : "$blastall -p blastn $opt{blast_opts}";
#my $ntdb = ($opt{plasmdb} || "$Bin/plasmid20120315/plasmid20120315.fa");
my $ntdb = ($opt{plasmdb} || "share/MicroGenome_pipeline/MicroGenome_pipeline_v5.0/database/plasmid_database/20140417/plasmid20140417.fa");
foreach('extract_seq.pl','blast_parser.pl','stat_plasmid.pl','super_worker.pl','cut_seq.pl'){
    (-s "$Bin/Plasmid_analysis/$_") || die"error: can't find script $_ at $Bin, $!";
}
my ($extract_seq_p,$blast_parser,$stat_coverage,$super_worker_p,$cut_seq_p) = (
    "perl $Bin/Plasmid_analysis/extract_seq.pl",
    "perl $Bin/Plasmid_analysis/blast_parser.pl",
    "perl $Bin/Plasmid_analysis/stat_plasmid.pl",
    "perl $Bin/Plasmid_analysis/super_worker.pl",
    "perl $Bin/Plasmid_analysis/cut_seq.pl"
);
($opt{run} ne 'qsub') && ($super_worker_p .= " --mutil");
$opt{qopts} && ($super_worker_p .= " --qopts=\"$opt{qopts}\"");
foreach(qw(len ident cover top)){$opt{$_} && ($stat_coverage .= " --$_ $opt{$_}");}
#==================================================================================================================
## usage:
(@ARGV==2 || @ARGV==1) || die "Name: Plasmid_analysis.pl
Description: script to extract enthetic sequence from assembly result wiht GC-depth info, and blast them to plasmid db
  to find the weather the sequence enthetied by plasm.
Author: liuwenbin
Version: 1.0  Data: 2012-07-20
Usage: perl Plasmid_analysis.pl <refreance.fa> [GC_depth.node.cluster] [-options]
    refreance.fa           inputfile of assembly result
    GC_depth.node.cluster  GC_depth cluster result, to select nonuniformity sequence, when ignore select all ref.
    --add_num <num>        add specified number of main scaffolds to outseq file.
    --seq_lim <flo>        limit the size of add scaffold(Kb), default the whold sequence.
    --wgs                  use the whold genomics for plasmid db blast alignment, not selected portion even some parameters set.
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
    --len <num>            blast m8 match min length, defualt=50
    --ident <flo>          identity cutoff, default=0.6
    --cover <flo>          minimal coverage cutoff, default=2
    --top <num>            output the top max coverage result for eatch scaffold, default=5
    --cpu <num>            thread for the process, default=1
    --run <str>            run type, qsub or mutil, default=qsub
    --blast_vf <str>       resultce for qsub blast m8, defalt=8G
    --pldir <str>          set plasm directory, default not set
    --qopts <str>          other qsub options, default=''
    --plasmdb <file>       plasm database, default use Bin/plasmid_database/20130423/plasmid20130423.fa
Example:
    perl Plasmid_analysis.pl NLH.fasta --cpu 10 --qopts='-P mgtest -q bc.q'
    perl Plasmid_analysis.pl NLH.fasta GC_depth.node.cluster --cpu 10 --qopts='-P mgtest -q bc.q' --cover_cut 0.8\n\n";
#==================================================================================================================
#    --megablast            use megablast instead of blastall, it maybe run faster
#    --mega_opts <str>      megablast options, default='-p 0.8 -b 5 -v 5'
## check error:
foreach(@ARGV){(-s $_) || die"error: can't find valid file $_, $!\n";}
my ($ref,$node) = @ARGV;
foreach($ref,$opt{outdir}){$_ &&= &abs_path($_);}#sub1
$opt{wgs} && ( ($node,$opt{add_num},$opt{seq_lim}) = (0, 0, 0) );
#==================================================================================================================
## main process:
#step1 extract enthetic sequence from assembly result
(-d $opt{outdir}) || mkdir($opt{outdir});
$opt{shdir} ||= "$opt{outdir}/Shell";
$opt{outdir} = abs_path($opt{outdir});
my (@moutf,@outf,@samp);
my (%ref,%node);
if(`head -1 $ref`=~/(\S+)[\s=]+(\S+)/ && -s $2){
    %ref = split/[\s=]+/,`less $ref`;
    $node && (%node = split/[\s=]+/,`less $node`);
    push @samp,keys %ref;
}elsif(-s $ref){
    $ref{all} = $ref;
    $node && ($node{all} = $node);
    push @samp,'all';
}
else {
    warn "error input seq file of $ref or in $ref. Seq empty or do not exist. Running Plasmid exit\n"; exit;
}
my (@outdir,@blast_dir);
my $extract_opts = " ";
foreach(qw(rank cluster_range cover_cut)){$opt{$_} && ($extract_opts .= " --$_ $opt{$_}");}
$opt{select} && ($extract_opts .= " --select '$opt{select}'");
my (@enthetic,@del_seq);
my $i = 0;
foreach(@samp){
    my ($node0,$ref0,$outd) = ($node{$_} || 0, $ref{$_},$opt{outdir});
    ($_ ne 'all') && ($outd .= "/$_");
    $opt{subdir} && ($outd .= "/$opt{subdir}");
    $opt{pldir} && ($outd .= "/$opt{pldir}");
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
        $opt{add_num} && ($del_seq[$i] = "$outd/log");
        $run_seq_cut ? system"$run_seq_cut" : system"$extract_seq_p $node0 $ref0 $extract_opts0 2> $outd/log";
    }
    push @moutf,[$outf];
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
my @cf = ('plasmid.blast.m0','plasmid.blast.xls','plasmid.stat.xls');
open SH,">$opt{shdir}/run_blastm0.sh";
foreach my $i(0..$#moutf){
    $enthetic[$i] && next;
    my @outf = @{$moutf[$i]};
    foreach(0..$#outf){
        print SH "cd $blast_dir[$i]\n$blastall -d $ntdb -i $outf[$_] -m 0 -o blast.$_\n",
        "$blast_parser blast.$_ > blast.$_.xls\n\n";
        $outf[$_] = "$blast_dir[$i]/blast.$_";
    }
    @{$moutf[$i]} = @outf;
}
close SH;
my $splits = '\n\n';
(-s "$opt{shdir}/run_blastm0.sh") && system"cd $opt{shdir};$super_worker_p run_blastm0.sh -splits \"$splits\" -resource $opt{blast_vf} --prefix plasm --sleept 100";
#my ($rn,$blast_out) = (0,"$opt{outdir}/blast.m8.tax");
my $rn = 0;
foreach my $i(@moutf){foreach(@{$i}){(-s $_) && ($rn = 1);}}
$rn || die"Note: can't find enthetic sequence\n";
foreach my $i(0..$#samp){
    $enthetic[$i] && next;
    my ($bout1,$bout2,$bout3) = ("$outdir[$i]/$cf[0]","$outdir[$i]/$cf[1]","$outdir[$i]/$cf[2]");
    foreach($bout1,$bout2){(-s $_) && `rm $_`;}
    my @bout = @{$moutf[$i]};
    my $mf = shift @bout;
    if($opt{cpu}==1 && !$opt{add_num}){
        system"mv $mf $bout1";
        system"mv $mf.xls $bout2";
        (-z "$blast_dir[$i]/log") && `rm $blast_dir[$i]/log`;
    }else{
        system"cp $mf $bout1";
        system"cp $mf.xls $bout2";
        foreach(@bout){
            system"awk 'NR>1' $_ >> $bout1";
            system"awk 'NR>1' $_.xls >> $bout2";
        }
        (-d "$blast_dir[$i]/../fa_cut") && `rm -r $blast_dir[$i]/../fa_cut`;
        (-z "$blast_dir[$i]/../log") && `rm $blast_dir[$i]/../log`;
        ($blast_dir[$i] =~ /blast_out$/) && (-d $blast_dir[$i]) && `rm -r $blast_dir[$i]`;
    }
    system"$stat_coverage $bout2 > $bout3";
}
#==================================================================================================================
## SUB:
#sub1
sub abs_path{
    chomp(my $temdir = `pwd`);
    ($_[0] =~ /^\//) ? $_[0] : "$temdir/$_[0]";
}
