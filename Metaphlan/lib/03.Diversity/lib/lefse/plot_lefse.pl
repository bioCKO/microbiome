#!/usr/bin/perl -w

=head1 Description:

    script for high-dimensional biomarker discovery and explanation that identifies genomic features (genes, pathways, or taxa) characterizing the differences between two or more biological conditions.

=head1 Version:

    Version: 1.0  Date: 2014-06-11
    Version: 2.0  Date: 2015-01-12, fix lefse bug, format the input from Relative folder
    Version: 3.0  Date: 2015-08-20, add Parameter: --lefse_vs, set vs group list
    Contact: chenjunru[AT]novogene.cn lihang[AT]novogenen.cn

=head1 Usage: perl plot_lefse.pl <metaphlan_tab:relative folder> <all.mf> [--options]

    *<metaphlan_tab file>   input metaphlan_table relative folder,like Object/02.MetaPhlAn/relative
    *<mf_file >             input file for all.mf, like Object/01.Data_split/all.mf
    --step <num>            step to run: 1-Format Data for LEfSe
                                         2-Perform the actual statistica analysis LDA Effect Size (LEfSe) 
                                         3-Plot the list of biomarkers with their effect size
                                         4-Plot the representation of the biomarkers on the hierarchical tree
                                         5-Plot the images for all the features that are detected as biomarkers
                                         default=12345
    --lefse_vs              set vs group list                      
    --prefix <str>          set output prefix
    --format_options=<str>  set format data options, default='-c 1 -o 1000000'
    --LDA_options=<str>     set statistica analysis options, default='-l 4'
    --list_options=<str>    set plot the list of biomarkers options,default='--format pdf'
    --tree_options=<str>    set plot hierarchical tree options,default='--format pdf --right_space_prop 0.15'
    --all_options=<str>     set Plot all the features options,default='--format pdf'
    --help <str>            format: output format data help information to screen.
                            LDA: output statistica analysis help information to screen.
                            list: output plot the list of biomarkers help information to screen.
                            tree: output plot hierarchical tree help information to screen.
                            all: output Plot all the features help information to screen.

=cut
#==================================================================================================================================
use strict;
#find lefse root
use FindBin qw($Bin);
use lib "$Bin/../../../../lib/00.Commbin";
use PATHWAY;
#my $lib="$Bin/../..";
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin, $!\n";
my($lefse_root,$convert) = 
get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(LEFSE_ROOT CONVERT)]);

#get options
use Getopt::Long;
my %opt = (step=>12345,prefix=>"LDA",format_options=>" -c 1 -o 1000000 ",LDA_options=>" -l 4 ",list_options=>" --format pdf ",tree_options=>" --format pdf --right_space_prop 0.15 ",all_options=>" --format pdf ");
GetOptions(
    \%opt,"metaphlan_tab:s","mf_file:s","step:i","lefse_vs:s","prefix:s","format_options:s",
    "LDA_options:s","list_options:s","tree_options:s","all_options:s","help:s"
);
my $metaphlan2lefse="perl $Bin/lib/metaphlan2lefse.pl";
my $format_input="python $lefse_root/format_input.py ";
my $run_lefse="python $lefse_root/run_lefse.py ";
my $plot_res="python $lefse_root/plot_res.py ";
my $plot_cladogram="python $lefse_root/plot_cladogram.py ";
my $plot_features="python $lefse_root/plot_features.py ";

if($opt{help}){
    ($opt{help} eq 'format') ? system"$format_input -h" :
    ($opt{help} eq 'LDA') ? system"$run_lefse -h" :
    ($opt{help} eq 'list') ? system"$plot_res -h" :
    ($opt{help} eq 'tree') ? system"$plot_cladogram -h" :
    ($opt{help} eq 'all') ? system"$plot_features -h" :
    die"error: --help just can be selected from format|LDA|list|tree|all\n";
    exit;
}

#====================================================================================================================
@ARGV >= 2 || die `pod2text $0`;
my ($metaphlan_tab,$mf)=@ARGV;


if ($opt{lefse_vs} && -s $opt{lefse_vs}) {
    my $i=0;
    for (`less $opt{lefse_vs}`) {
        my @vs_group= split;
        my $vs_group_filename;
        for (@vs_group){
            $vs_group_filename.=$_."-vs-";
        }
        substr($vs_group_filename,-4,4)="";
        $i++;
        (-d "$i\_$vs_group_filename")?`rm -rf "$i\_$vs_group_filename"/*`:`mkdir "$i\_$vs_group_filename"`;

        ### 0) Format the metaphlan_table.even.txt for Format data.
        open(SH,">$opt{prefix}.$i.sh");
        print SH "source $lefse_root/activate.sh\n";
        print SH "$metaphlan2lefse $metaphlan_tab $mf $i\_$vs_group_filename/$opt{prefix}.$i.txt @vs_group\n";

        ### 1) Format Data for LEfSe
        if($opt{step}=~/1/){
            print SH "$format_input $i\_$vs_group_filename/$opt{prefix}.$i.txt $i\_$vs_group_filename/$opt{prefix}.$i.in $opt{format_options}\n";
        }

        ### 2) Perform the actual statistica analysis LDA Effect Size
        if($opt{step}=~/2/){
            $opt{LDA_options}?print SH "$run_lefse $i\_$vs_group_filename/$opt{prefix}.$i.in $i\_$vs_group_filename/$opt{prefix}.$i.res $opt{LDA_options}\n":print SH "$run_lefse $i\_$vs_group_filename/$opt{prefix}.$i.in $i\_$vs_group_filename/$opt{prefix}.$i.res\n";
        }
        ### 3) Plot the list of biomarkers with their effect size
        if ($opt{step}=~/3/) {
            my $format;
            if($opt{list_options}=~/--format\s+(pdf|svg|png)/){$format=$1;}else{$format='pdf';}
            print SH "$plot_res $i\_$vs_group_filename/$opt{prefix}.$i.res $i\_$vs_group_filename/$opt{prefix}.$i.$format $opt{list_options}\n",
            "$convert  -density 300 $i\_$vs_group_filename/$opt{prefix}.$i.$format $i\_$vs_group_filename/$opt{prefix}.$i.png\n";
        }
        ### 4) Plot the representation of the biomarkers on the hierarchical tree
        if ($opt{step}=~/4/) {
            my $format;
            if($opt{tree_options}=~/--format\s+(pdf|svg|png)/){$format=$1;}else{$format='pdf';}
            print SH "$plot_cladogram $i\_$vs_group_filename/$opt{prefix}.$i.res $i\_$vs_group_filename/$opt{prefix}.$i.tree.$format $opt{tree_options}\n",
            "$convert  -density 300 $i\_$vs_group_filename/$opt{prefix}.$i.tree.$format  $i\_$vs_group_filename/$opt{prefix}.$i.tree.png\n";
        } 
        ### 5) Plot the images for all the features that are detected as biomarkers
        if ($opt{step}=~/5/) {
            (-d "$i\_$vs_group_filename/biomarkers_raw_images")?`rm -rf $i\_$vs_group_filename/biomarkers_raw_images/*`:`mkdir $i\_$vs_group_filename/biomarkers_raw_images`;
            print SH "$plot_features $i\_$vs_group_filename/$opt{prefix}.$i.in $i\_$vs_group_filename/$opt{prefix}.$i.res  $i\_$vs_group_filename/biomarkers_raw_images/ $opt{all_options}\n";
        }
        print SH "\n";
#        close SH;
        `sh $opt{prefix}.$i.sh > "$i\_$vs_group_filename"/$opt{prefix}.$i.log`;

    }
}else{
    open(SH,">$opt{prefix}.sh");
    ### 0) Format the metaphlan_table.even.txt for Format data.
    print SH "source $lefse_root/activate.sh\n";
    print SH "$metaphlan2lefse $metaphlan_tab $mf $opt{prefix}.txt\n";

    ### 1) Format Data for LEfSe
    if($opt{step}=~/1/){
        print SH "$format_input $opt{prefix}.txt $opt{prefix}.in $opt{format_options}\n";
    }
    ### 2) Perform the actual statistica analysis LDA Effect Size
    if($opt{step}=~/2/){
        $opt{LDA_options}?print SH "$run_lefse $opt{prefix}.in $opt{prefix}.res $opt{LDA_options}\n":print SH "$run_lefse $opt{prefix}.in $opt{prefix}.res\n";
    }
    ### 3) Plot the list of biomarkers with their effect size
    if ($opt{step}=~/3/) {
        my $format;
        if($opt{list_options}=~/--format\s+(pdf|svg|png)/){$format=$1;}else{$format='pdf';}
        print SH "$plot_res $opt{prefix}.res $opt{prefix}.$format $opt{list_options}\n",
        "$convert  -density 300 $opt{prefix}.$format $opt{prefix}.png\n";
    }
    ### 4) Plot the representation of the biomarkers on the hierarchical tree
    if ($opt{step}=~/4/) {
        my $format;
        if($opt{tree_options}=~/--format\s+(pdf|svg|png)/){$format=$1;}else{$format='pdf';}
        print SH "$plot_cladogram $opt{prefix}.res $opt{prefix}.tree.$format $opt{tree_options}\n",
        "$convert  -density 300 $opt{prefix}.tree.$format  $opt{prefix}.tree.png\n";
    }
    ### 5) Plot the images for all the features that are detected as biomarkers
    if ($opt{step}=~/5/) {
        (-d "biomarkers_raw_images")?`rm -rf biomarkers_raw_images/*`:`mkdir biomarkers_raw_images`;
        print SH "$plot_features $opt{prefix}.in $opt{prefix}.res  biomarkers_raw_images/ $opt{all_options}\n";
    }
    close SH;
    `sh $opt{prefix}.sh > $opt{prefix}.log`;
    # else...
}


