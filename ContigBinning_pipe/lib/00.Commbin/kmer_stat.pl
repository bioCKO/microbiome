#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;

# set options
my %opt = ("outdir",".", "shdir","./Detail","step","123","vf","3G","dvf","2G",
    ## for step2
    "r","32",
    ## for run step1 and step2
    "k","15", "meryl1"," -B -C -v -memory 614400 -threads 1 -c 0", "meryl2"," -Dh", "meryl3"," -Dt -n 1", 
);
# get options from screen
GetOptions(\%opt,"list:s","outdir:s","shdir:s","step:n","notrun","vf:s","qopts:s","dvf:s",
    #for step1
    "size:s",
    ## for step2
    "r:n",
    ##for step1 and step2
    "k:n","meryl1:s","meryl2:s","kfreq",
);
# get software/script's path
use lib "$Bin/../00.Commonbin";
use PATHWAY;
(-s "$Bin/../../bin/cfg.5.1.txt") || die"Error: can't find config at $Bin/../../bin, $!\n";
my ($super_worker, $meryl) = get_pathway("$Bin/../../bin/cfg.5.1.txt",[qw(SUPER_WORKER MERYL)]);
my $fq2fa_cut = "perl $Bin/lib/fq2fa_cut.pl"; 
my $stat4krst = "perl $Bin/lib/stat4krst/stat4krst.pl";
## software/script for step1

#=======================================================================================
($opt{list}) || 
die"Name: $0
Description: For one sample, get kmer frequency distribution, and then estimate genomes size and heterogeneity based on the distribution.
Date:  201602
Connector: lishanshan[AT]novogene.com
Usage1: perl $0  --list clean_reads.list -k 15 --size 300M  --outdir 01.run_assembly  --shdir Detail 
       *--list		[str]   list of clean fq or fq.gz
                            Form: sample_id  libsize  clean_reads_path
        --step      [num]   steps, default = 12
                                1. get kmer frequency distribution using the data size from input default = 300M
                                2. get kmer frequency distribution by setting the data size,  = 32*genome_size(estimated from step1)
                                3. stat kmer_stat for all samples from step2 result
        --k         [num]   set which mer for step1. default=15
        --r         [num]   must be set for step2. to control the kmer freq distribution peak, by setting data size equal to r*genome_size. default = 32
        --size      [str]   data size to use for step 1. form: 330M/0.33G/330000000; default use all data in step1      
    [other opts for step1 and step2]
        --meryl1    [str]   given a sequence file (-s) and lots of parameters, compute the mer-count tables.default = \" -B -C -v -memory 614400 -threads 1 -c 0\"
        --meryl2    [str]   Dump (to stdout) a histogram of mer counts. default = \"-Dh\"
        --kfreq     [str]   get each kind of kmer sequence and its frequency . default --kfreq
        --meryl3    [str]   if --kfreq, Dump mers >= a threshold.  Use -n to specify the threshold. default =\" -Dt -n 1\"
	[options for other]
        --outdir     [str]  project directory,default is ./01.run_assembly
        --shdir      [str]  output shell script directory, default = ./Detail
        --vf         [str]  resource for superworker, default =3G
        --dvf        [str}  adjust resoouce based on vf for superworker.default not set
        --qopts      [str]  other qsub options for superworker
		--queue      [str]  queue for qsub, default not set.
        --notrun            just produce shell script, not run. Not if (step1 has never been run, && --step 12 && --notrun) , only output worksh for step1. If step1 has been run, --step 12 || --step 2, can output worksh for step2.
        --locate            run locate
        --changelog       [str]  log: output CHANGLOG information to screen.  

";

#=======================================================================================
(-s $opt{list}) || die "Error: empty or not exist: $opt{list}.\n";
my $assdir = $opt{outdir} . "/01.run_assembly";
my $statdir = $opt{outdir} . "/02.stat";
foreach($opt{outdir}, $opt{shdir}, $assdir, $statdir) { (-d $_) || `mkdir -p $_`; }
foreach($opt{outdir}, $opt{shdir}, $opt{list}) { $_ = abs_path($_) ; }
## get options for software/script
$opt{vf} && ($super_worker .= " --resource $opt{vf}");
$opt{qopts} && ($super_worker .= " --qopts $opt{qopts}");
$opt{dvf} && ($super_worker .= " --dvf $opt{dvf}");
$opt{queue} && ($super_worker .= " --queue $opt{queue}");
my $meryl1 = "$meryl$opt{meryl1} -m $opt{k}";
my $meryl2 = $meryl . $opt{meryl2};
my $meryl3 = $meryl . $opt{meryl3};
$stat4krst .= " -k $opt{k}";

# main script
my ($locate_run, $qsub_run);
my $splits = '\n\n';
## input for all
my %clean;
for (`less $opt{list}`) {
    chomp;
    (/^#/) || !(/\S+/) && next;
    my ($sample, $libsize, $readsfq) = (split /\s+/)[0..2];
    if ($libsize < 1500) {
        push @{$clean{$sample}}, $readsfq;
    }
}
my @samples = keys %clean;
foreach(@samples) {(-d "$assdir/$_") || `mkdir -p $assdir/$_`; (-d "$assdir/$_/01.kmer_stat/") || `mkdir -p $assdir/$_/01.kmer_stat/`;}
## step1: run kmer_freq only once, using the data size from input
if ($opt{step} =~ /1/) {
    my $step1;
    foreach(@samples) {
        my $survey = "$assdir/$_/01.kmer_stat/survey";
        (-d $survey) || `mkdir -p $survey`;
        open LIST,">$survey/clean_fq.list"||die$!;
        print LIST join "\n", @{$clean{$_}};
        close LIST;
        my $outname =  $opt{size} ? "$_.$opt{size}" : "$_.all";
        $step1 .= "cd $survey\n";
        $step1 .= write_sh("clean_fq.list", $opt{k}, $outname, $opt{size});
    }
    open OUT, ">$opt{shdir}/step1.1.kmer_survey.sh" ||die$!;
    print OUT $step1;
    close OUT;
    my $locate_run = "sh step1.1.kmer_survey.sh & \n";
    my $qsub_run = "$super_worker step1.1.kmer_survey.sh  --prefix kmer_survey -splits '$splits' & wait\n";
    if (! $opt{notrun}){ #motify by liuchen 20170310
    $opt{locate} ? system "cd $opt{shdir}\n $locate_run" : system "cd $opt{shdir}\n$qsub_run\n";
}
}

## step2: run kmer_freq again, by setting the data size = 32*genome_size
if ($opt{step} =~ /2/) {
    $opt{r} || die "Error: --r must be set if run step1.2.kmer_again.sh\n";
    my $step2 = "";
    foreach(@samples) {
### get new data size = 32*genome_size (from survey result)
        my $new_size =  $1 * $opt{r} . "M" if (`less $assdir/$_/01.kmer_stat/survey/*.survey.xls` =~ /(?:gce1\.0\.0_H|gce1.0.0|Genomeye)\s+\S+\s+\S+\s+\S+\s+\S+\s+([\d\.]+)\s+\S+/);#motify by liuchen 20170310
        $new_size || die "Error: no kmer_freq survey results in $assdir/$_/01.kmer_stat/survey/*.survey.xls\n";
        my $again = "$assdir/$_/01.kmer_stat/again";
        (-d $again) || `mkdir -p $again`;
        my $outname = "$_.$new_size";
        $step2 .= "cd $again\ncp ../survey/clean_fq.list . \n";
        $step2 .= write_sh("clean_fq.list", $opt{k}, $outname, $new_size);
    }
    open OUT, ">$opt{shdir}/step1.2.kmer_again.sh" ||die$!;
    print OUT $step2;
    close OUT;
    my $locate_run = "sh step1.2.kmer_again.sh & \n";
    my $qsub_run = "$super_worker step1.2.kmer_again.sh  --prefix kmer_again -splits '$splits' & wait\n";
    if (!$opt{notrun}){
    $opt{locate} ? system "cd $opt{shdir}\n $locate_run" : system "cd $opt{shdir}\n$qsub_run\n";
}
}
## step3: get kmer_stat for all samples
if ($opt{step} =~ /3/) {
    open STAT,">$statdir/all_kmer.stat.xls" || die"$!\n";
    print STAT "Sample ID\tK-mer\tK-mer Number\tK-mer Depth\tGenome Size(Mb)\tRevised Size(Mb)\tHeterozygous Rate(%)\tRepeat Rate(%)\n";
    foreach (@samples){
        #gce1.0.0        k15     83204919        16.90   4.92    4.82    N/A     17.63%  0.45%   97.99%
        `less $assdir/$_/01.kmer_stat/again/*.survey.xls` =~ /(?:gce1\.0\.0_H|gce1.0.0|Genomeye)\s\S+\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+(\S+)\s+(\S+)\s+/;
        my ($kmer_number, $kmer_depth, $genome_size, $revised_size, $hete_rate, $repeat_rate) = ($1, $2, $3, $4, $5, $6);
		foreach($hete_rate, $repeat_rate) {s/%//}
        while ($kmer_number =~ /^(\d+)(\d\d\d)/) {$kmer_number =~ s/^(\d+)(\d\d\d)/$1,$2/};
        print STAT join("\t",$_,$opt{k},$kmer_number,$kmer_depth, $genome_size, $revised_size, $hete_rate, $repeat_rate)."\n";         
    }
    close STAT;
}

#sub==========================================================================================================
sub write_sh{
    my ($list, $k, $out, $size) = @_;
    my $sh = $size ? "$fq2fa_cut --list $list  --size $size --out $out.fa \n" : "$fq2fa_cut --list $list  --out $out.fa \n";
    $sh .= "$meryl1 -s $out.fa -o $out.fa\_k$k\n";
    $sh .= "$meryl2 -s $out.fa\_k$k >$out\_k$k.merge.xls\n";
    $sh .= "$stat4krst -n $out $out\_k$k.merge.xls . .\n";
    if ($opt{kfreq}) {
        $sh .= "$meryl3 -s $out.fa\_k$k>$out\_k$k.merge.kfreq\n";
        $sh .= "gzip $out\_k$k.merge.kfreq\n"
    }
    $sh .= "\n";
}
