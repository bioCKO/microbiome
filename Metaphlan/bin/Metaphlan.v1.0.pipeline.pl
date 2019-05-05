#!/usr/bin/perl -w
=head1 Description

For metaphlan analysis : QC, MetaPhlAn TaxAnno, Diversity analysis

=head1 Version

    Contact: Dan Lin, lindan[AT]novogene.com
    Version: 1.0 Date: 2016-06-15 No Special Day

=head1 Usage

    perl metagenome_pipeline.pl --data_list NHT130208.cfg [-options]
    
    --AVF        [str]   set vf and dvf options for QC,and metaphlan
                         default=8G/7G;5G/1G
    --step       [str]   analysis step as follow, default=123
                         1.data QC for multiple samples
                         2.taxonomical annotation
                         3.diversity analysis (1: TopN heatmap or column diagram. 2:lefse. 3:metastat 4: Ttest) 
    --outdir     [dir]   output directory, default=.                  
    --shdir      [dir]   output shell directory, default=$opt{outdir}/Shell 

[options for step1]

    *--data_list [file]  input info file,
                         example :#Samplename\tRawDataPath\tInsertSize(bp)\tDatasize(M)\tLibraryID\tDescription
                         must include #Samplename\tRawDataPath\tInsertSize(bp)\tDatasize(M)\tLibraryID
    *--read_len   [dir]   fasta read length, important for idba_ud and soapaligner , must set for safety (eg. --read_len 150)
    --group      [str]   group information for samples,format=novoid\tsample[\tgroup],
    --fqp        [str]   the fastq files regular expression,default=[*_[12].fq.gz]
    --adp        [str]   the adapter files regular expression,default=[*_[12].adapter.list.gz]
    --rf_opts    [str]   the filter options for readfq,defult=[-z -q 38,40 -n 10 -l 15]
    --host       [str]   the host ref genome,default not set, can accept multiple genomes
    --hvf        [str]   set the resource for construct host genome's index,default=8G
    --qc_opts    [str]   set other data QC process options

[options for step2]  

    --reads_list [file]  when donnot run step1, set clean data file for step2

[options for step3]

    --relative_dir [dir]   when donnot run step2, set [k p c o f g s] relarive abundance directory for step3
    --top_bar    [str]   set top N level for column diagram.
    --top_heatmap[str]   set top N level for heatmap.
    --mf         [str]   when donnot run step1, set group info for step3 diversity analysis,format=samplid\tgroup,
    --lefse_vs   [file]  input vs list for LDA analysis,look like: a  b, needed for lefse
[other options]
    --help       [str]   must set be qc|ta|ds
                         qc: output data QC pipeline help information to screen.
                         ta: output tax annotation pipeline help information to screen.
                         ds: output diversity pipeline help information to screen.
    --notrun            only write the shell, but not run
    --locate            just run locate, not qsub

=head1 Note
    1 You can use -norun , then just write the shell but not run it.
    2.For data_list, you must set # at the header, the Datasize represent the total datasize that you want to output for RawDataPath
    3.When you already got the cleandata, you can set --reads_list to run step2 directly. similarly, if you already got the [k p c o f g s]tax anno abundance files, you can set the directory of these files with the parameter --relative_dir and run step3 directly.
    
=head1 Example
    perl Metagenome_pileline.pl --data_list sample.cfg.txt --read_len 150 --group group.list --lefse_vs lefse.list --host /BJPROJ/GR/share/medinfo.00database/genome/human/hg19/hg19.fa --outdir . --shdir Shell 
   perl Metagenome_pileline.pl --step23 --reads_list reads.list --mf mf.list -lefse_vs lefse.list --outdir step23 --shdir Shell
   perl Metagenome_pileline.pl --step 3 --relative_dir relative_dir_path --mf mf.list -lefse_vslefse.list --outdir step3 --shdir Shell 
=cut

#=======================================================================================

use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;

#set options
my @host;
my %opt = (
   AVF=>'8G/7G;5G/1G',step=>'123',fqp=>'',adp=>'',rf_opts=>'',qc_options=>'',hvf=>'8G',host=>\@host,
   top_bar=>'10',top_heatmap=>'35',outdir=>".",shdir=>"./Shell",
);
GetOptions(
   \%opt, "data_list:s","read_len:s","host:s","AVF:s","step:s","reads_list:s","relative_dir:s","outdir:s","shdir:s","fqp:s","adp:s","rf_opts:s","hvf:s","qc_options:s","top_bar:n","top_heatmap:n","group:s","mf:s","lefse_vs:s","Vslist:s","Vslist_t:s","help:s","notrun","locate"
);
#end for get options

#get software & scripts' pathway
use lib "$Bin/../lib/00.Commbin";
my $lib = "$Bin/../lib/";
use PATHWAY;
(-s "$Bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/, $!\n";
my ($super_worker, $qc, $metaphlan, $diversity, $sh_control) = get_pathway("$Bin/Pathway_cfg.txt",[qw(SUPER_WORK QC_MAIN METAPHLAN DIVERSITY SH_CONTRAL2)]);

if($opt{help}){
    ($opt{help} eq 'qc') ? system"$qc":
    ($opt{help} eq 'ta') ? system"$metaphlan":
    ($opt{help} eq 'ds') ? system"$diversity":
    die"error: --help just can be selected from qc|ta|ds\n";
    exit;
}
#===========================================================================================
#options set
if(!$opt{step} || $opt{step} =~ /1/){ ($opt{data_list} && -s $opt{data_list} && $opt{read_len} ) || die `pod2text $0`;}
$opt{data_list} && ($opt{data_list}=abs_path($opt{data_list}));
$opt{reads_list} && ($opt{reads_list}=abs_path($opt{reads_list}));
$opt{relative_dir} && ($opt{relative_dir}=abs_path($opt{relative_dir}));
$opt{group} && ($opt{group}=abs_path($opt{group}));
$opt{mf} && ($opt{mf}=abs_path($opt{mf})) && ($diversity .= " --mf $opt{mf}");
$opt{lefse_vs} && ($opt{lefse_vs}=abs_path($opt{lefse_vs})) && ($diversity .= " --lefse_vs $opt{lefse_vs}");
$opt{top_bar} && ($diversity .= " --top_bar $opt{top_bar}");
$opt{top_heatmap} && ($diversity .= " --top_heatmap $opt{top_heatmap}");
$opt{Vslist} && ($opt{Vslist}=abs_path($opt{Vslist}));
$opt{Vslist_t} && ($opt{Vslist_t}=abs_path($opt{Vslist_t}));
my $shdir  = $opt{shdir};
my $detail = "$shdir/detail";
for($opt{outdir},$shdir,$detail){
    (-s $_) || mkdir($_);
    $_ = abs_path($_);
}
my @dir;
for ("01.DataClean", "02.MetaPhlAn", "03.Diversity"){
    push @dir, "$opt{outdir}/$_";
}
#opts for qc
if ($opt{AVF}) {
    my $i=1;
    my @AVF=split/;/,$opt{AVF};
    foreach my $avf(@AVF){
        my @avf=split/\//,$avf; $#avf == 1 || warn"warnings: please check AVF option's format\n";
        $#avf == 1 || warn"warnings: please check AVF option's format\n";
        $i == 1 ?
        $qc .= " --svf $avf[0] --dvf $avf[1] ":
        $i == 2 ?
        $metaphlan .= " --vf $avf[0] ":
        $i >2 ?
        warn"warnings: please check AVF option, just for two steps\n" : 1 ;
        $i++;
    }
}
if($opt{read_len} && ($opt{read_len} == 125 || $opt{read_len} == 150)) {
    $qc .= " --read_len $opt{read_len} ";
}
$opt{fqp} && ($qc .= " --fqp $opt{fqp} ");
$opt{adp} && ($qc .= " --adp $opt{adp} ");
$opt{rf_opts} && ($qc .= " --rf_opts ' $opt{rf_opts} ' ");
if(@host){
    foreach(@host){
        $qc .= " --host $_ ";
    }
}
$opt{hvf} && ($qc .= " --hvf $opt{hvf} ");
$opt{qc_opts} && ($qc .= " $opt{qc_opts} ");

## for data list
my (@samples,%samples);
if($opt{data_list} && -s $opt{data_list}){
  for(`less -S $opt{data_list}`){
    chomp;
    next if /^#/;
    next if /^$/;
    my @or=split/\s+/;
    if(! -s "$or[1]/$or[4]"){
        warn"warnings:$or[0]'s RawData Pathway is not exists!\n";
        next;
    }
    push @samples,$or[0]  if ! grep {$or[0] eq $_ } @samples;
    push @{$samples{$or[0]}},$_;
  }
##For all.mf
    open(MF,">$opt{outdir}/all.mf");
    if ($opt{group}) {
       open(DETA,">$opt{outdir}/data.list") || die $!;
       for(`less -S $opt{group}`){
            chomp;
            my @or=split/\s+/;
            if ($samples{$or[0]}) {
                $or[2] ?
                print MF "$or[1]\t$or[2]\n":
                print MF "$or[1]\t$or[1]\n";
                foreach my $mid (@{$samples{$or[0]}}){
                    $mid=~s/^$or[0]/$or[1]/;
                    print DETA "$mid\n";
                }
            }else{warn "warnings:sample $or[0] is not exists in data_list or RawData Pathway is not exists\n";}
       }
        $qc .= " --data_list $opt{outdir}/data.list ";
        $diversity .= " --mf $opt{outdir}/all.mf ";
       close DETA;
}else{   
    foreach(@samples){ print  MF "$_\t$_\n";}
    $qc .= " --data_list $opt{data_list} ";
    $diversity .= " --mf $opt{outdir}/all.mf ";
} 
close MF;
}

##main shell
my $main_shell = "metaphlan_pipeline.sh";
open SH,">$shdir/$main_shell" || die$!;

##==  1) Data Clean  ==##
if($opt{step}=~/1/){
    (-d $dir[0]) || mkdir $dir[0];
    write_file("$opt{shdir}/step1.DataClean.sh","cd $dir[0]\n$qc --outdir $dir[0] --shdir $detail/01.DataClean\n");
    shell_box(*SH,"1) run Data Clean","$shdir/step1.DataClean.sh",0,"$detail/01.DataClean/step1.rec");
    my $sign = "step1 QC";
    my $rec = "$detail/01.DataClean/step1.rec";
    check_task($sh_control,*SH,$sign,$rec);
    my $clean_list="$dir[0]/Dataclean.total.list";
    $metaphlan .= " --data_list $clean_list ";
}

##==  2) MetaPhlAn TaxAnno  ==##
if($opt{step}=~/2/){
    (-d $dir[1]) || mkdir $dir[1];
    if($opt{reads_list} && -s $opt{reads_list}){$metaphlan .= " --data_list $opt{reads_list} ";}
    write_file("$opt{shdir}/step2.MetaPhlAn.sh", "cd $dir[1]\n$metaphlan --outdir $dir[1] --shdir $detail/02.MetaPhlAn\n");
    shell_box(*SH, "2) run metaphlan taxAnno", "$shdir/step2.MetaPhlAn.sh",0,"$detail/02.MetaPhlAn/step2.rec");
    my $sign = "step2 metaphlan tax anno";
    my $rec = "$detail/02.MetaPhlAn/step2.rec";
    check_task($sh_control,*SH,$sign,$rec); 
    $diversity .= " --relative_dir $dir[1]/relative";
}

##== 3) Diversity Analysis
if($opt{step}=~/3/){
    (-d $dir[2]) ||mkdir $dir[2];
    if($opt{relative_dir} && -s $opt{relative_dir}){$diversity .= "--relative_dir $opt{relative_dir}\n";}
    write_file("$opt{shdir}/step3.Diversity.sh", "cd $dir[2]\n$diversity --outdir $dir[2] --shdir $detail/03.Diversity\n");
    shell_box(*SH, "3) run diversity analysis", "step3.Diversity.sh");
}

close SH;
$opt{notrun} || system"cd $shdir; nohup sh $main_shell";

#====================================================================================================================
## subs 
#=============
sub shell_box{
#=============
    my ($handel,$STEP,$shell,$qopt,$bgrun) = @_;
    my $middle= $qopt ? "nohup $super_worker $qopt --head=\"cd `pwd`\" $shell" : "nohup sh $shell >& $shell.log";
    my $end = "date +\"\%D \%T -> Finish $STEP\"";
    if($bgrun){
        (-s $bgrun) && `rm $bgrun`;
        $end .= " > $bgrun";
        if($qopt && $qopt !~ /-splitn\s+1\b/){
            $middle .= " --endsh '$end'";
        }else{
            `echo '$end' >> $shell`;
        }
        $STEP .= " background";
        $middle .= " &";
    }else{
        $middle .= "\n$end";
    }
    print $handel "##$STEP\ndate +\"\%D \%T -> Start  $STEP\"\n$middle\n\n";
}
#==============
sub write_file{
#==============
    my $file = shift;
    open SSH,">$file" || die$!;
    for(@_){
        print SSH;
    }
    close SSH;
}

#==============
sub check_task{
#==============
    my ($sh_control,$handel,$STEP,$rec) = @_;
    print $handel "#== check $STEP\ndate +\"\%D \%T -> Checking $STEP\"\n$sh_control $rec\n",
          "date +\"\%D \%T -> Finished checking $STEP\"\n\n";
}

