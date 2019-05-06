#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use File::Basename;
use Getopt::Long;


# set default options
my %opt = ("step","123","outdir",".","shdir","./Shell","num_each","500",
    ## for common
    "b","Y","e","1e-5","m","0","d","40","p","40",
    ## for step1
    ## for t3ss
    "t3ss_opt"," -m TTSS_STD-1.0.1.jar -t selective",
);

# get options from screen
GetOptions(\%opt, "step:s","pep_list:s","outdir:s","shdir:s","notrun","qopts:s","splitn:n","locate","help",
    ## for common
    "spe_type:s","num_each:n","function:s","b:s","e:s","m:n","d:n","p:n",
    ## for t3ss
    "t3ss_opt:s",
    ## for secretory
    "secretory_type:s",
    ## for gi
    "cds_list:s","gff_list:s",
    ## for step3 make gbk
    "ass_list:s", "gbk_list:s",
);

# get software/script's path
use lib "$Bin/../../lib/00.Commonbin";
use PATHWAY;
(-s "$Bin/../../bin/cfg.5.1.txt") || die"error: can't find config at $Bin/../../bin, $!\n";

my ($super_worker, $super_worker1, $Rscript, $convert, $java, $diamond,  $hmmscan, $hmm_db, $go_class,   $nrb_db, $nrf_db, $nrb_info, $nrf_info,
    $trembl_db, $trembl_info,   $swissprot_db, $swissprot_info,     $kegg_db, $kegg_info, $kegg_map, $kegg_ko, $kegg_taxonomy, $kegg_color, $ec_number_class,    
    $phi_db, $phi_info,    $cazy_db, $cazy_name_list, $cazy_info, $cazy_catalog,    $tcdb_db, $tcdb_info, $tcdb_family, $tcdb_category,   
    $cog_db, $cog_whog, $cog_fun,    $vfdb_db, $vfdb_info,    $ardb_db, $ardb_info,    $kog_db, $kog_fun, $kog_kog,     $nog_db, $nog_info, $nog_fun,
    $p450_db, $p450_info,   $dfvf_db, $dfvf_info,     $pog_db, $pog_info,     $t3ss, $t3ss_std, $signalp, $tmhmm, $dimob,  $tnss, $antismash, $Pfam_clan ) = get_pathway("$Bin/../../bin/cfg.5.1.txt",[qw(SUPER_WORKER SUPER_WORKER1 RSCRIPT CONVERT JAVA DIAMOND HMMSCAN  HMM_DB  GO_CLASS NRB_DB NRF_DB NRB_INFO NRF_INFO   TREMBL_DB TREMBL_INFO  SWISSPROT_DB  SWISSPROT_INFO  KEGG_DB KEGG_INFO KEGG_MAP KEGG_KO KEGG_TAXONOMY KEGG_COLOR EC_NUMBER_CLASS    PHI_DB PHI_INFO   CAZY_DB CAZY_NAME_LIST CAZY_INFO CAZY_CATALOG   TCDB_DB TCDB_INFO TCDB_FAMILY TCDB_CATEGORY   COG_DB COG_WHOG COG_FUN   VFDB_DB VFDB_INFO ARDB_DB ARDB_info   KOG_DB KOG_FUN KOG_KOG  NOG_DB NOG_INFO NOG_FUN   P450_DB P450_INFO   DFVF_DB DFVF_INFO   POG_DB POG_INFO   T3SS T3SS_STD  SIGNALP  TMHMM  DIMOB  TNSS ANTISMASH PFAM_CLAN)]);

## split pep
my $pep_split = "perl $Bin/Commonbin/split_fa.pl";
## for step2 annotation
my $choose_blast_m8 = "perl $Bin/NR/0.choose_blast_m8.pl"; 
my $choose_blast_m8_phi = "perl $Bin/NR/0.choose_blast_m8_phi.pl";  ####  PHI Version 4.3 May 1st 2017 :the db pep are only 60bp 
### T3SS
my $t3ss_stat = "perl $Bin/T3SS/t3ss_stat.pl";
### SECRETORY
my $tmhmm_filter = "perl $Bin/SECRETORY/tmhmm.filter.pl";
### GI
my $split_by_dis = "perl $Bin/GI/split_by_dis.pl";
my $gff3_to_ptt = "perl $Bin/GI/gff3_to_ptt.pl";
my $stat_gi = "perl $Bin/GI/stat_gi.pl";
my $hmmscan_dir = dirname ($hmmscan);
$dimob = "export PATH=$hmmscan_dir:\\\$PATH; " . $dimob;
## step2
### GO
my $function_out2go_hmm = "perl $Bin/GO/1.function_out2go_hmm.pl";
my $annot_make = "perl $Bin/GO/2.annot.make.pl";
my $pfamgo2GO = "perl $Bin/GO/3.pfamgo2go_wego.pl";
my $drawGO_addnum = "perl $Bin/GO/4.drawGO_addnum_v2.pl";
my $pfam_anno = "perl $Bin/GO/5.pfam.anno.pl";
my $pfam_super_anno = "perl $Bin/GO/6.pfam_super_anno.pl";
### NR
my $nr_anno = "perl $Bin/NR/1.anno.pl";
my $nr_stat = "perl $Bin/NR/2.stat.pl";
my $nr_draw = "perl $Bin/NR/3.draw.pl"; 
### trembl 
my $trembl_anno = "perl $Bin/TREMBL/1.anno.pl";
my $trembl_stat = "perl $Bin/TREMBL/2.stat.pl"; 
my $trembl_draw = "perl $Bin/TREMBL/3.draw.pl"; 
### NOG 
my $nog_anno = "perl $Bin/NOG/1.nog.anno.pl";
my $nog_stat ="perl $Bin/NOG/2.nog.stat.pl";
my $nog_func_stat ="perl $Bin/NOG/3.function_stat.pl";
my $nog_draw ="perl $Bin/NOG/4.draw_nog_r.pl";
### KEGG
my $kegg_anno = "perl $Bin/KEGG/1.anno.V2.pl";
my $kegg_catalog = "perl $Bin/KEGG/2.catalog.pl";
my $KO_unigene = "perl $Bin/KEGG/3.pathway_by_KO/1.get_Unigenes.KEGG.anno.pl"; 
my $kegg_even_table = "perl $Bin/KEGG/3.pathway_by_KO/2.even.table.deal.pl"; 
my $kegg_num_abun = "perl $Bin/KEGG/3.pathway_by_KO/3.num.abun.pl"; 
my $kegg_draw_pathway = "perl $Bin/KEGG/3.pathway_by_KO/4.draw.keggpathway.pl"; 
my $kegg_drawAnnot = "$Bin/KEGG/3.pathway_by_KO/5.DrawAnnotationPic.R"; 
my $kegg_Ko3_draw_ec_map = "perl $Bin/KEGG/3.pathway_by_KO/6.Ko3.draw_ec_map.V3.pl"; 
my $kegg_refomat_map_gene = "perl $Bin/KEGG/9.refomat_map.gene.V2.pl"; 
### SWISSPROT
my $swissprot_anno = "perl $Bin/SWISSPROT/1.anno.pl";
### PHI
my $phi_anno = "perl $Bin/PHI/1.anno.pl";
my $phi_draw = "perl $Bin/PHI/2.draw_phi.pl";
### CAZY
my $cazy_anno = "perl $Bin/CAZY/1.anno.pl";
my $cazy_summary = "perl $Bin/CAZY/2.summary.pl";
my $cazy_class = "perl $Bin/CAZY/2.statis_class.pl";
my $cazy_allclass = "perl $Bin/CAZY/2.statis_allclass.pl";
my $cazy_draw = "perl $Bin/CAZY/3.CAZy.multi_draw.pl";
### TCDB
my $tcdb_parser = "perl $Bin/TCDB/1.tcdb_parser_m8.pl";
my $tcdb_catalog = "perl $Bin/TCDB/2.catalog.pl";
my $tcdb_draw = "perl $Bin/TCDB/3.draw_tcdb_r_addnum.pl";
### COG
my $cog_parser = "perl $Bin/COG/1.cog_parser_m8.pl";
my $cog_catalog = "perl $Bin/COG/2.catalog.pl";
my $cog_draw = "perl $Bin/COG/3.draw_cog_r_addnum.pl";
### VFDB
my $vfdb_anno = "perl $Bin/VFDB/1.anno.pl";
### ARDB 
my $ardb_anno = "perl $Bin/ARDB/1.anno.pl";
### KOG
my $kog_parser = "perl $Bin/KOG/1.kog_parser_m8.pl";
my $kog_catalog = "perl $Bin/KOG/2.catalog.pl";
my $kog_draw = "perl $Bin/KOG/3.draw_kog_r_addnum.pl";
### P450
my $p450_anno = "perl $Bin/P450/1.anno.pl";
my $p450_denovo_and_stat = "perl $Bin/P450/2.p450_denovo_and_stat.pl";
### DFVF
my $dfvf_anno = "perl $Bin/DFVF/1.anno.pl";
### POG
my $pog_anno = "perl $Bin/POG/1.anno.pl";
### summary
my $summary_annot = "perl $Bin/Commonbin/annotation_stat.pl";
my $all_sum_annot = "perl $Bin/Commonbin/all_sum_annot.pl";
my $tnss_stat = "perl $Bin/TNSS/TnSS_annoflow.pl";
my $summary_gi = "perl $Bin/Commonbin/summary_gi.pl";
my $summary_secret = "perl $Bin/Commonbin/summary_secretory.pl";
### for gbk
my $make_gbk = "perl $Bin/Commonbin/make_genbank.pl";
my $make_tbl = "perl $Bin/Commonbin/make_tbl.pl";
my $tbl2asn = "$Bin/Commonbin/tbl2asn";

### for secondary metablism using antismash
$antismash = "export PATH=$hmmscan_dir:\$PATH\n" . $antismash;
my $gene_num = "perl $Bin/SECONDARY/gene_num.pl";
my $bar_diagram = "perl $Bin/SECONDARY/bar_diagram.pl";

### for prophage 
my $prophage_seed = "System/Python-2.7.6/bin/python microinstall/phiSpyNov11_v2.3/genbank_to_seed.py";
my $prophage_phiSpy = "System/Python-2.7.6/bin/python microinstall/phiSpyNov11_v2.3/phiSpy.py";
my $part_seq_gene = "perl $Bin/Commonbin/part_seq_gene.pl";

##for crispr
my $crispr = "perl microinstall/CRISPRdigger_autoinstall_20151211/scripts/CRISPRdigger.pl";
my $crispr_dr = "perl $Bin/CRISPR/CRISPR_fill.pl";
# ==============================================================================================================================
($opt{pep_list} && $opt{spe_type} && $opt{function} && !$opt{help}) || 
die"Name: $0
Description: pipeline for genome function
Date:201604
Version:v1.0
Connector: lishanshan[AT]novogene.com
Usage: perl $0   --spe_type B --outdir 04.Genome_Function --shdir Detail --pep_list pep.list --function go-nr-trembl-kegg-swissprot-phi-cazy-tcdb-cog-vfdb-ardb-t3ss-secretory-gi-tnss-secondary-prophage-crispr --secretory_type gram- --cds_list cds.list --gff_list gff.list --ass_list ass.list
    [main opts]
       *--pep_list          [str]   pep list of all sample
                                        e.g. sample sample1.pep
                                             sample sample2.pep 
       *--spe_type          [str]   species type, B: Bacteria, F:fungi
       *--function          [str]   function type to annotate. default = ''.
                                        common for bactreia and fungi: nr-swissprot-trembl-kegg-go-phi-cazy-secretory-tcdb-secondary
                                        For bactreia only: t3ss-tnss-cog-vfdb-ardb-gi-prophage-crispr
                                        For fungi only:  kog-nog-p450-dfvf
                                        For virus,phage: nr-swissprot-trembl-pog-kegg-go-tnss
        --num_each          [str]   gene number in each split file. default = '500'
        --e                 [str]   e-value threshold for blast and filter m8 result, default = 1e-5
        --secretory_type    [str]   only for secretory annotation. when spe_type = 'B', it can be 'gram+' or 'gram-' (if not set, it will be gram-); when spe_type = 'F', it will be 'euk'.
    [other options for t3ss]
        --t3ss_opt          [str]   default = '-m TTSS_STD-1.0.1.jar -t selective'
                                    -m: 
                                    TTSS_STD-1.0.1.jar is for standard; 
                                    For animal: T3SS/module/TTSS_ANIMAL-latest.jar
                                    For plant: T3SS/module/TTSS_PLANT-latest.jar
                                    -t: means cutoff
                                    cutoff=<cutoff_value> (The threshold, default cutoff=0.995),sensitive (cut    off=0.95),selective (cutoff=0.9999)
    [other options for gi]
        --cds_list          [str]   cds list of all sample
                                        e.g. sample sample1.cds
                                             sample sample2.cds 
        --gff_list          [str]   gff list of all sample
                                        e.g. sample sample1.gff
                                             sample sample2.gff 
    [other options for filter]
        --b                 [str]   Y or N, pick the BestHit blast m8 result for each subject, default = Y
        --m                 [num]   match length threshold for blast m8 results, default = 0
        --d                 [num]   identity threshold for filter blast m8 result, default = 40
        --p                 [num]   min match percentage%. default = 40
    [other options for step3 annotsummary]
        --ass_list          [str]   if set, pipeline will make gbk for bacteria 
        --gbk_list          [str]   for just run secondary metabolism using anitismash.and prophage. If run general function 'go-kegg------t3ss', --gbk_list should not be set
    [opts for others] 
        --outdir            [str]   directory for output data. default = ./
        --shdir             [str]   directory for output shell script. default = ./Shell
        --notrun                    just produce shell script, not run. default not set
        --qopts             [str]   other qsub options for superworker.e.g.: --qopt ' -q all.q,micro.q'
        --locate                    run locate
        --splitn            [num]   cut files when superworker.default = '10'
        --help              [str]   help information for readfq 
    Note: pipeline for 'secondary metabolism' is only for bacteria; please use online antismash.

";
#===============================================================================================================================
-s $opt{pep_list} || die "Error: empty or not exist: $opt{pep_list}\n";
if ($opt{function} =~ /gi/) {$opt{cds_list} && $opt{gff_list} && (-s $opt{cds_list}) && (-s $opt{gff_list}) || die"cds_list gff.list and pep_list must be set if run gi\n"}
if ($opt{function} =~ /Prophage/){$opt{gff_list}||die"gff_list must be set if run Prophage stat\n"}
$opt{spe_type} =~ /F/ && $opt{function} =~ /secondary/ && die "Please use online antismash for fungi\n";
# ==============================================================================================================================
# -s abs mkdir
foreach($opt{outdir}, $opt{shdir}, "$opt{outdir}/01.run_function", "$opt{outdir}/02.stat") { (-d $_) || `mkdir -p $_`;}
foreach($opt{pep_list}, $opt{outdir}, $opt{shdir} ) {$_ = abs_path($_);}
# get options for software/script
my $qopts = $opt{qopts} ? " --qopts ' $opt{qopts}'" : "";
$opt{splitn} && ($super_worker .= " --splitn $opt{splitn}");
my %db = ("swissprot"=>$swissprot_db, "trembl"=>$trembl_db, "kegg"=>$kegg_db, "phi"=>$phi_db, "cazy"=>$cazy_db, "tcdb"=>$tcdb_db,  "cog"=>$cog_db, "vfdb"=>$vfdb_db, "ardb"=>$ardb_db, "kog"=>$kog_db, "nog"=>$nog_db, "p450"=>$p450_db, "dfvf"=>$dfvf_db, "pog"=>$pog_db);
$db{nr} = $opt{spe_type} =~ /F/ ? $nrf_db : $nrb_db;
my %info_nr;$info_nr{nr} = $opt{spe_type} =~ /F/ ? $nrf_info : $nrb_info;  ##lihongyue 20170507
($opt{function} =~ /secretory/) &&  ( $opt{secretory_type} ||= ($opt{spe_type} =~ /F/) ? "euk" : "gram-");

# main scripts
my ($locate_run, $qsub_run);
my $splits = '\n\n';
## read pep_list and split pep_fasta 
my (@pep, $sh0);
my $i = 0;
for (`less $opt{pep_list}`) {
    chomp(my @l = split /\s+/, $_);
    my $dir = "$opt{outdir}/01.run_function/$l[0]/00.Split";
    $sh0 .= "$pep_split $l[1] $opt{num_each} $dir split\n";
    chomp(my $total = `grep -c '>' $l[1]`);
    my $split_num = ($total % $opt{num_each}) ? int($total/$opt{num_each}) + 1 : int($total/$opt{num_each});

    @{$pep[$i]} = @l;
    foreach (0..$split_num-1) {
        push @{$pep[$i]}, "$dir/split_$_.fa";
    }
    $i++;
}
my %ass;
if ($opt{ass_list}) { %ass = split /\s+/,`awk '{print \$1,\$2}' $opt{ass_list}`};
my %gff;
if ($opt{gff_list}){ %gff= split /\s+/,`awk '{print \$1,\$2}' $opt{gff_list}`};


my $flag;
foreach(qw(go pfam nr trembl nog kegg swissprot   phi cazy tcdb cog vfdb   ardb kog p450 dfvf pog)){
    ($opt{function} =~ /$_/) && ($flag = 1) && last;
}
if ($flag) {
    writesh("$opt{shdir}/step0.split.sh", $sh0);
    $locate_run .= "sh step0.split.sh\n";
    $qsub_run .= "$super_worker step0.split.sh --resource 1G  $qopts --prefix split --splits '\\n'  --line 10 \n";
}

## 
## step1: blast: diomand,hmmscan,jar against all databases=======================================================================
my @stat_arg;
### GO 
if ($opt{function} =~ /go|pfam/) {
    my $sh;
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        my $out = "$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GO/";
        (-d "$out/{blast_out,go_stat}") || `mkdir -p $out/{blast_out,go_stat}`;
        foreach (@{$pep[$i]}[2..$#{$pep[$i]}]) {
            my $fa_name = basename($_); 
            $sh .= "$hmmscan --acc --domtblout $out/blast_out/$fa_name.dtb -o $out/blast_out/$fa_name.out $hmm_db $_\n";
        }
        $stat_arg[$i] .= " --go GO/go_stat/$sample.pfamgo.annot.GO";
    }
    writesh("$opt{shdir}/step1.1.hmmscan_go.sh", $sh);
    $locate_run .= "sh step1.1.hmmscan_go.sh &\n";
    $qsub_run .= "$super_worker step1.1.hmmscan_go.sh --resource 2G,num_proc=4  $qopts --prefix hmmscan_go --splits '\\n'   &\n";  ##yue
}
### diamond step1.2.1.diamond.sh ... step1.16.1.diamond.sh
my @diamond_db = qw(nr trembl nog kegg swissprot   phi cazy tcdb cog vfdb   ardb kog p450 dfvf pog); #15
my @vf = (7,7,6,3,1,  1,1,1,2,1,  1,1,1,1,1);

for my $i (0..$#diamond_db) {
    my $curr_db = $diamond_db[$i];
    if ($opt{function} =~ /$curr_db/) {
        my $sh;
        for my $i (0..$#pep) {
            my $sample = ${$pep[$i]}[0];
            my $out = "$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/" . uc($curr_db);
            (-d "$out/{blast_out,$curr_db\_stat}") || `mkdir -p $out/{blast_out,$curr_db\_stat}`;
            my $blast_list;
            foreach (@{$pep[$i]}[2..$#{$pep[$i]}]) {
                my $fa_name = basename($_); 
                $sh .= "$diamond blastp -q $_ -t $out/blast_out -a $out/blast_out/$fa_name.blast -p 4 -e $opt{e} --sensitive -d $db{$curr_db}\n";
                $sh .= "$diamond view -a $out/blast_out/$fa_name.blast.daa -o $out/blast_out/$fa_name.blast.m8\n\n";
                $blast_list .= "$out/blast_out/$fa_name.blast.m8\n";
            }
            writesh("$out/$curr_db\_stat/$sample.$curr_db\_blast.list", $blast_list);
            my $uc_db = uc($curr_db);
            $stat_arg[$i] .= " --$curr_db $uc_db/$curr_db\_stat/*anno";
        }
        my $j = $i+2;
        writesh("$opt{shdir}/step1.$j.diamond_$curr_db.sh", $sh);
        $locate_run .= "sh step1.$j.diamond_$curr_db.sh &\n";
		$opt{qopts} ||= "";
#        my $qopts =  ($curr_db =~ /nr|trembl|nog/) ? " --qopts ' $opt{qopts} -l num_proc=4'" : $opt{qopts} ? " --qopts ' $opt{qopts}'" : "";
        my $qopts =  $opt{qopts} ? " --qopts ' $opt{qopts}'" : "";
        $qsub_run .= "$super_worker step1.$j.diamond_$curr_db.sh --resource $vf[$i]G,num_proc=4  $qopts --prefix diamd_$curr_db --splits '$splits'";  ###yue
		$qsub_run .= ($curr_db =~ /nr|trembl|nog/) ? " --line 1 &\n" : "  &\n";
    }
}
### jar step1.17.jar_t3ss.sh
if ($opt{function} =~ /t3ss/) {
    my $sh;
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        my $out = "$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/T3SS";
        (-d "$out") || `mkdir -p $out`;
        $sh .= "cd $out\n";
        $sh .= "mkdir -p module\n";
        $sh .= "cp $t3ss_std module/\n";
        $sh .= "$java -jar $t3ss -f ${$pep[$i]}[1] -m TTSS_STD-1.0.1.jar -t selective -o $sample.t3ss.out -q >temp.o 2>temp.e\n";
        $sh .= "$t3ss_stat $sample.t3ss.out $sample\n\n";
        $stat_arg[$i] .= " --t3ss T3SS/$sample.t3ss.xls";
    }
    writesh("$opt{shdir}/step1.17.jar_t3ss.sh", $sh);
    $locate_run .= "sh step1.17.jar_t3ss.sh &\n";
    $qsub_run .= "$super_worker1 step1.17.jar_t3ss.sh --resource 15G,num_proc=4  $qopts --prefix jar_t3ss --splits '$splits'   &\n";   #yue
}
my %list;
### diomb step1.18.secretory.sh
if ($opt{function} =~ /secretory/) {
    my $sh;
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        my $out = "$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/SECRERETORY";
        (-d "$out") || `mkdir -p $out`;
        $sh .= "cd $out\n";
        $sh .= "$signalp -t $opt{secretory_type} -T temp -m $sample.SignalP.ori.fa -n $sample.SignalP.ori.gff ${$pep[$i]}[1] >$sample.SignalP.ori.xls\n";
        $sh .= "$tmhmm ${$pep[$i]}[1] >$sample.tmhmm.xls\n";
        $sh .= "$tmhmm_filter $sample.tmhmm.xls $sample.SignalP.ori.gff $sample.SignalP.ori.fa $sample.secretory.gff $sample.secretory.fa\n";
        $sh .= "rm -rf temp* TMHMM*\n\n";
		$stat_arg[$i] .= " --secretory SECRERETORY/$sample.secretory.gff";
		chomp(my $total = `grep -c ">" ${$pep[$i]}[1]`);
		$list{secretory} .= "$sample\t$total\t$out/$sample.secretory.gff\n";
		$list{secretorydir} .= "$sample\t$out\n";
    }
	writesh("$opt{outdir}/02.stat/secretory.list",$list{secretory});
	writesh("$opt{outdir}/02.stat/secretorydir.list",$list{secretorydir});
    writesh("$opt{shdir}/step1.18.secretory.sh", $sh);
    $locate_run .= "sh step1.18.secretory.sh &\n";
    $qsub_run .= "$super_worker step1.18.secretory.sh --resource 2G,num_proc=4  $qopts --prefix secretory --splits '$splits'  &\n";   ##yue
}
### diomb step1.19.GI.sh
if ($opt{function} =~ /gi/) {
    my %cds = split /\s+/,`awk '{print \$1,\$2}' $opt{cds_list}`;
    my %gff = split /\s+/,`awk '{print \$1,\$2}' $opt{gff_list}`;
    my ($sh1,$sh2,$sh3);
    my $sh2_name = "$opt{shdir}/step1.19.2.diomb_GI.sh";
    `rm -f $sh2_name`; 
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $cds{$sample}||next;
        my $out = "$opt{outdir}/01.run_function/$sample/02.GIs/";
        (-d "$out/split") || `mkdir -p $out/split`;
        $sh1 .= "cd $out\n";
        $sh1 .= "$split_by_dis $cds{$sample} cds split/cds\n";
        $sh1 .= "$split_by_dis ${$pep[$i]}[1] pep split/pep\n";
        $sh1 .= "$gff3_to_ptt $gff{$sample} split/ptt\n\n";

		`rm -f $out/split/pep/*mob`;
		my %scfs;
		open IN,"$cds{$sample}"||die"Error in $cds{$sample}\n";
		while(<IN>){
			/^>/||next;
			my $prefix=(split /[\s=:]+/, $_)[2];
			$scfs{$prefix}=1;
		}
		close IN;
		foreach my $prefix(keys %scfs){
			$sh2 .= "$dimob $out/split/pep/$prefix.pep  $out/split/cds/$prefix.cds $out/split/ptt/$prefix.ptt >$out/split/ptt/$prefix.ptt.dis\n";
		}

        $sh3 .= "cd $out\nls $out/split/ptt/*dis >$out/split/dis.list\n";
#$sh3 .= "$stat_gi $out/split/dis.list >$out/$sample.GI.xls\n\n"; # bylss at 201702
        $sh3 .= "$stat_gi $out/split/dis.list >$out/GI.temp\n".
                "$part_seq_gene --tab GI.temp --seq $ass{$sample} --gff $gff{$sample} --prefix $sample.GI\n\n";
		$list{gi} .= "$sample\t$out/$sample.GI.xls\n";
    }
    writesh("$opt{shdir}/step1.19.1.split_GI.sh", $sh1);
    writesh("$opt{shdir}/step1.19.2.diomb_GI.sh", $sh2);
    writesh("$opt{shdir}/step1.19.3.stat_GI.sh", $sh3);
    $locate_run .= "sh step1.19.1.split_GI.sh\nsh step1.19.2.diomb_GI.sh\nsh step1.19.3.stat_GI.sh\n";
    $qsub_run .= "$super_worker step1.19.1.split_GI.sh --resource 1G  $qopts --prefix split_gi --splits '$splits'  \n$super_worker step1.19.2.diomb_GI.sh --resource 1G  $qopts --prefix diomb_gi --splits '\\n'  \n$super_worker step1.19.3.stat_GI.sh --resource 1G  $qopts --prefix stat_gi --splits '$splits'  \n";
}
$locate_run && ($locate_run .= "wait\n");
$qsub_run && ($qsub_run .= "wait\n");

## step2 gene annotation and stat=============================================================================================

my %stat;
if ($opt{function} =~ /go/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{go} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GO/go_stat\n";
        $stat{go} .= "cat ../blast_out/*.out >$sample.hmm_out\n";
        $stat{go} .= "$function_out2go_hmm $sample.hmm_out $sample.hmm_go.txt $sample.pfam.txt\n";
        $stat{go} .= "$annot_make $sample.hmm_go.txt >$sample.pfamgo.annot\n";
        $stat{go} .= "$pfamgo2GO $sample.pfamgo.annot $go_class\n";
        $stat{go} .= "$drawGO_addnum -gglist  $sample.pfamgo.annot.wego --go $go_class -outprefix $sample.go\n";
		$stat{go} .= "$pfam_anno $sample.pfam.txt $sample.gene.pfam.xls\n";
		$stat{go} .= "$pfam_super_anno $Pfam_clan $sample.pfam.txt $sample.pfam.xls\n\n";
        $list{go} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GO/go_stat/$sample.go.xls\n";
    }

}
#if ($opt{function} =~ /pfam/) { ####add by gxj at 20160602
#	for my $i (0..$#pep) {
#		my $sample = ${$pep[$i]}[0];
#		$stat{pfam} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GO/go_stat\n";
#		($opt{function} =~ /go/) || ($stat{pfam} .= "cat ../blast_out/*.out >$sample.hmm_out\n");
#		($opt{function} =~ /go/) || ($stat{pfam} .= "$function_out2go_hmm $sample.hmm_out $sample.hmm_go.txt $sample.pfam.txt\n");
#		$stat{pfam} .= "$pfam_anno $sample.pfam.txt $sample.gene.pfam.xls\n";
#		$stat{pfam} .= "$pfam_super_anno $Pfam_clan $sample.pfam.txt $sample.pfam.xls\n";
#		$list{go} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GO/go_stat/$sample.pfam.xls\n";
#	}
#}
if ($opt{function} =~ /nr/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{nr} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/NR/nr_stat\n";
        $stat{nr} .= "$choose_blast_m8 -i $sample.nr_blast.list -o $sample.nr.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{nr}\n";
        $stat{nr} .= "$nr_anno $sample.nr.filter $sample.nr.filter.anno $info_nr{nr}\n"; #lihongyue 20170507
        $stat{nr} .= "$nr_stat $sample.nr.filter.anno $sample.nr.species.anno.xls\n";
        $stat{nr} .= "$nr_draw $sample.nr.species.anno.xls $sample.nr.anno\n\n";
    }
}
if ($opt{function} =~ /trembl/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{trembl} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/TREMBL/trembl_stat\n";
        $stat{trembl} .= "$choose_blast_m8 -i $sample.trembl_blast.list -o $sample.trembl.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{trembl}\n";
        $stat{trembl} .= "$trembl_anno $sample.trembl.filter $sample.trembl.filter.anno $trembl_info\n";
    }
}
if ($opt{function} =~ /nog/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{nog} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/NOG/nog_stat\n";
        $stat{nog} .= "$choose_blast_m8 -i $sample.nog_blast.list -o $sample.nog.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{nog}\n";
        $stat{nog} .= "$nog_anno $sample.nog.filter $sample.nog.filter.anno $nog_info\n";
        $stat{nog} .= "$nog_stat  $sample.nog.filter.anno NOG\n";
        $stat{nog} .= "mv NOG.catalog $sample.nog.gene.catalog; mv NOG.nog_stat_1 $sample.nog.orthologous.stat.xls\n";
        $stat{nog} .= "$nog_func_stat NOG.class_stat_1 $sample.nog.class.stat.xls $nog_fun\n";
        $stat{nog} .= "$nog_draw $sample.nog.class.stat.xls $sample.nog.class\n\n";
        $list{nog} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/NOG/nog_stat/$sample.nog.filter.anno\n";
    }
}

if ($opt{function} =~ /kegg/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{kegg} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/KEGG/kegg_stat/\n";
        $stat{kegg} .= "$choose_blast_m8 -i $sample.kegg_blast.list -o kegg.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{kegg}\n";
        $stat{kegg} .= "$kegg_anno kegg.filter kegg.filter.anno $kegg_info $kegg_ko\n";
        $stat{kegg} .= "$kegg_catalog kegg.filter.anno kegg.list.catalog\n";
        $stat{kegg} .= "$KO_unigene kegg.filter.anno . \n"; #out: Unigenes.KEGG.anno.xls
        $stat{kegg} .= "$kegg_even_table Unigenes.KEGG.anno.xls table.even.xls\n";#out: GeneNums/, Absolute/
        $stat{kegg} .= "$kegg_num_abun --anno Unigenes.KEGG.anno.xls --table table.even.xls --outdir ./  --prefix Unigenes.absolute\n";
        $stat{kegg} .= "$kegg_draw_pathway --step 1 --ko2gene GeneNums/Unigenes.absolute.ko.xls --level3 Absolute/Unigenes.absolute.level3.xls --outdir pathwaymaps\n";#out: pathwaymaps/, pathwaymaps.report/
        $stat{kegg} .= "cp $kegg_color pathwaymaps\n";
        $stat{kegg} .= "awk -F \"\\t\" '{print \$1\"\\t\"\$2\"\\t\"\$3}' GeneNums/Unigenes.absolute.level2.xls | perl -ne 'next if \$_=~/^Others\\t/;print;'> DrawAnnotationPic.R.txt\n";
        $stat{kegg} .= "$Rscript $kegg_drawAnnot DrawAnnotationPic.R.txt kegg.unigenes.num\n";
        $stat{kegg} .= "$convert -density 150 kegg.unigenes.num.pdf kegg.unigenes.num.png\n";
        $stat{kegg} .= "$kegg_Ko3_draw_ec_map --ko_path $kegg_ko kegg.list.catalog\n";
        $stat{kegg} .= "$kegg_refomat_map_gene kegg.list.catalog.map.gene $kegg_map\n\n";
        $list{kegg} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/KEGG/kegg_stat/kegg.filter.anno\n";
    }
}
if ($opt{function} =~ /swissprot/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{swissprot} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/SWISSPROT/swissprot_stat\n";
        $stat{swissprot} .= "$choose_blast_m8 -i $sample.swissprot_blast.list -o $sample.swissprot.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{swissprot}\n";
        $stat{swissprot} .= "$swissprot_anno $sample.swissprot.filter $sample.swissprot.filter.anno $swissprot_info\n\n";
    }
}
if ($opt{function} =~ /phi/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{phi} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/PHI/phi_stat\n";
#       $stat{phi} .= "$choose_blast_m8 -i $sample.phi_blast.list -o $sample.phi.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{phi}\n";
        $stat{phi} .= "$choose_blast_m8_phi -i $sample.phi_blast.list -o $sample.phi.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{phi}\n";
        $stat{phi} .= "$phi_anno $sample.phi.filter $sample.phi.filter.anno $phi_info\n";
        $stat{phi} .= "$phi_draw $sample.phi.filter.anno $sample.phi.class\n\n";
    }
}
if ($opt{function} =~ /cazy/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{cazy} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/CAZY/cazy_stat\n";
        $stat{cazy} .= "$choose_blast_m8 -i $sample.cazy_blast.list -o $sample.cazy.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{cazy}\n";
        $stat{cazy} .= "$cazy_anno $sample.cazy.filter $sample.cazy.filter.anno $sample.cazy.filter.catalog $cazy_name_list $cazy_info $cazy_catalog\n";
        $stat{cazy} .= "$cazy_summary . $sample.basic_summary.stat\n";
        $stat{cazy} .= "$cazy_class . $sample.statis_class.stat\n";
        $stat{cazy} .= "$cazy_allclass . $sample.statis_allclass.stat $cazy_catalog\n\n";
        $list{cazy} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/CAZY/cazy_stat/$sample.statis_class.stat\n";
    }
}
if ($opt{function} =~ /tcdb/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{tcdb} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/TCDB/tcdb_stat\n";
        $stat{tcdb} .= "$choose_blast_m8 -i $sample.tcdb_blast.list -o $sample.tcdb.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{tcdb}\n";
        $stat{tcdb} .= "$tcdb_parser $sample.tcdb.filter $tcdb_info\n";
        $stat{tcdb} .= "$tcdb_catalog $sample.tcdb.filter.anno $sample.tcdb $tcdb_family $tcdb_category\n";
        $stat{tcdb} .= "$tcdb_draw $sample.tcdb.class.stat $sample.tcdb.class\n";
        $stat{tcdb} .= "$tcdb_draw $sample.tcdb.subclass.stat $sample.tcdb.subclass\n";
    }
}
if ($opt{function} =~ /cog/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{cog} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/COG/cog_stat\n";
        $stat{cog} .= "$choose_blast_m8 -i $sample.cog_blast.list -o $sample.cog.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{cog}\n";
        $stat{cog} .= "$cog_parser $sample.cog.filter $cog_whog $cog_fun\n";
        $stat{cog} .= "$cog_catalog $sample.cog.filter.anno $sample.cog.catalog $sample.cog.calss.catalog $sample.cog.all.catalog $cog_fun\n";
        $stat{cog} .= "$cog_draw $sample.cog.calss.catalog $sample.cog.class\n\n";
        $list{cog} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/COG/cog_stat/$sample.cog.filter.anno\n";
    }
}
if ($opt{function} =~ /vfdb/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{vfdb} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/VFDB/vfdb_stat\n";
        $stat{vfdb} .= "$choose_blast_m8 -i $sample.vfdb_blast.list -o $sample.vfdb.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{vfdb}\n";
        $stat{vfdb} .= "$vfdb_anno $sample.vfdb.filter $sample.vfdb.filter.anno $vfdb_info\n\n";
    }
}
if ($opt{function} =~ /ardb/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{ardb} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/ARDB/ardb_stat\n";
        $stat{ardb} .= "$choose_blast_m8 -i $sample.ardb_blast.list -o $sample.ardb.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{ardb}\n";
        $stat{ardb} .= "$ardb_anno $sample.ardb.filter $sample.ardb.filter.anno.all $ardb_info\n";
        $stat{ardb} .= "awk '{if (NR == 1) {print \$0;} else if(\$2>=\$6){print \$0;}}' $sample.ardb.filter.anno.all >$sample.ardb.filter.anno\n\n";
    }
}
if ($opt{function} =~ /kog/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{kog} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/KOG/kog_stat\n";
        $stat{kog} .= "$choose_blast_m8 -i $sample.kog_blast.list -o $sample.kog.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{kog}\n";
        $stat{kog} .= "$kog_parser $sample.kog.filter $kog_kog $kog_fun\n";
        $stat{kog} .= "$kog_catalog $sample.kog.filter.anno $sample.kog.catalog $sample.kog.calss.catalog $sample.kog.all.catalog $kog_fun\n";
        $stat{kog} .= "$kog_draw $sample.kog.calss.catalog $sample.kog.class\n\n";
        $list{kog} .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/KOG/kog_stat/$sample.kog.filter.anno\n";
    }
}
if ($opt{function} =~ /p450/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{p450} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/P450/p450_stat\n";
        $stat{p450} .= "$choose_blast_m8 -i $sample.p450_blast.list -o $sample.p450.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{p450}\n";
        $stat{p450} .= "$p450_anno $sample.p450.filter $sample.p450.filter.anno $p450_info\n";
        $stat{p450} .= "$p450_denovo_and_stat ${$pep[$i]}[1] $sample.p450.filter.anno $sample.all_p450.pep $sample.p450.all.anno.xls\n";
    }
}
if ($opt{function} =~ /dfvf/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{dfvf} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/DFVF/dfvf_stat\n";
        $stat{dfvf} .= "$choose_blast_m8 -i $sample.dfvf_blast.list -o $sample.dfvf.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{dfvf}\n";
        $stat{dfvf} .= "$dfvf_anno $sample.dfvf.filter $sample.dfvf.filter.anno $dfvf_info\n\n";
    }
}
if ($opt{function} =~ /pog/) {
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $stat{pog} .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/POG/pog_stat\n";
        $stat{pog} .= "$choose_blast_m8 -i $sample.pog_blast.list -o $sample.pog.filter -d $opt{d} -e $opt{e} -b $opt{b} -m $opt{m} -p $opt{p} -q ${$pep[$i]}[1] -s $db{pog}\n";
        $stat{pog} .= "$pog_anno $sample.pog.filter $sample.pog.filter.anno $pog_info\n\n";
    }
}
## write step2 shell 
#qw(nr trembl nog kegg swissprot   phi cazy tcdb cog vfdb   ardb kog p450 dfvf pog)
if ($opt{function} =~ /go/) {
    writesh("$opt{shdir}/step2.1.annot_go.sh", $stat{go});
    $locate_run .= "sh step2.1.annot_go.sh &\n";
    $qsub_run .= "$super_worker step2.1.annot_go.sh --resource 1G  $qopts --prefix annot_go --splits '$splits'   &\n";
}
for my $i (0..$#diamond_db) {
    my $curr_db = $diamond_db[$i];
    if ($opt{function} =~ /$curr_db/) {
        my $j = $i+2;
        writesh("$opt{shdir}/step2.$j.annot_$curr_db.sh", $stat{$curr_db});
        $locate_run .= "sh step2.$j.annot_$curr_db.sh &\n";
		my $resource = ($opt{function} =~ /nr|trembl/) ? '13G' : ($opt{function} =~ /nog/) ? '9G' : '1G';
        $qsub_run .= "$super_worker step2.$j.annot_$curr_db.sh --resource $resource  $qopts --prefix annot_$curr_db --splits '$splits'  &\n";
    }
}
if($locate_run) {(split /\n/,$locate_run)[-1] !~ /^wait/ && ($locate_run .= "wait\n") && ($qsub_run .= "wait\n")};
foreach(keys %list){
    writesh("$opt{outdir}/02.stat/$_.list", $list{$_});
}
## step 3 annot_summary based on step2 ===========================================================================================
### annot-summary , make gbk for bacteria
if (@stat_arg) {
    my ($sh, $gbk_list, $sum_anno_list);
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        $sh .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation\n";
        $sh .= "$summary_annot ${$pep[$i]}[1] $stat_arg[$i] $sample.anno.table.xls\n";
        $sum_anno_list .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/$sample.anno.table.xls\n";
        ### make gbk
        my $gbk_func = $opt{function}; $gbk_func =~ s/tnss|secondary|gi//g; $gbk_func =~ s/-{2,3}/-/g;$gbk_func =~ s/-$//;
        if ($ass{$sample} && $opt{spe_type} =~ /B/) {
#            $sh .= "$make_gbk $ass{$sample} ${$pep[$i]}[1] ${$pep[$i]}[0].anno.table.xls --anno $gbk_func --outdir . --outfile $sample.gbk\n";
			$sh .= "mkdir $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GBK\n";
			$sh .= "cd $opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GBK\n";
			$sh .= "$make_tbl $opt{outdir}/../03.Genome_Component/01.run_component/$sample/01.Gene_Prediction/$sample.gmhmmp.gff $opt{outdir}/../04.Genome_Function/01.run_function/$sample/01.General_Gene_Annotation/NR/nr_stat/$sample.nr.filter.anno $opt{outdir}/../03.Genome_Component/01.run_component/$sample/03.ncRNA-Finding/rRNA/denovo/$sample.rRNAd.gff $opt{outdir}/../03.Genome_Component/01.run_component/$sample/03.ncRNA-Finding/tRNA/$sample.tRNA.gff\n";
			$sh .= "cp $ass{$sample} $sample.fsa\n"; #change at 20161207 by gxj ($ass{$sample})
#			$sh .= "cp $opt{outdir}/../02.Assembly/01.run_assembly/$sample/02.3.fill/all.scafSeq.fna $sample.fsa\n";
			$sh .= "mv output.tbl $sample.tbl\n";
			$sh .= "$tbl2asn -i $sample.fsa -V b -a s\n";
			$sh .= "mv $sample.gbf $sample.gbk\n";
			$gbk_list .= "$sample\t$opt{outdir}/01.run_function/$sample/01.General_Gene_Annotation/GBK/$sample.gbk\n";
        }
    }

    $gbk_list && writesh("$opt{outdir}/02.stat/gbk.list", $gbk_list);
    writesh("$opt{outdir}/02.stat/annot_summary.list", $sum_anno_list);
    $sh .= "$all_sum_annot $opt{outdir}/02.stat/annot_summary.list $opt{outdir}/02.stat/all_sample.annoSummary.stat.xls\n";
	(glob "$opt{outdir}/01.run_function/*/01.General_Gene_Annotation/T3SS") && ($sh .= "perl -e 'my \@t3ss=glob \"$opt{outdir}/01.run_function/*/01.General_Gene_Annotation/T3SS/*.t3ss.stat.xls\"; `head -1 \$t3ss[0] >$opt{outdir}/02.stat/all_sample.t3ss.stat.xls`;foreach(\@t3ss){`sed -n '2p' \$_ >>$opt{outdir}/02.stat/all_sample.t3ss.stat.xls`}' \n"); 
    $list{cazy} && ($sh .= "$cazy_draw  $opt{outdir}/02.stat/cazy.list $opt{outdir}/02.stat/all_CAZy_class $opt{outdir}/02.stat/all_sample.cazy.stat.xls\n");
    $list{gi} && ($sh .= "$summary_gi $opt{outdir}/02.stat/gi.list $opt{outdir}/02.stat/all_sample.gi.stat.xls\n");
	$list{secretory} && ($sh .= "$summary_secret $opt{outdir}/02.stat/secretorydir.list $opt{outdir}/02.stat/all_sample.secretory.stat.xls\n");

    writesh("$opt{shdir}/step3.1.annot_summary.sh", $sh);
    $locate_run .= "sh step3.1.annot_summary.sh\n";
    $qsub_run .= "$super_worker step3.1.annot_summary.sh --resource 1G  $qopts --prefix annot_summary  --splits '$splits'  \n";
}

### tnss 
if ($opt{function} =~ /tnss/) {
    my $sh;
    for my $i (0..$#pep) {
        (-d "$opt{outdir}/01.run_function/${$pep[$i]}[0]/01.General_Gene_Annotation/TNSS") || `mkdir -p $opt{outdir}/01.run_function/${$pep[$i]}[0]/01.General_Gene_Annotation/TNSS`;
        $sh .= "cd $opt{outdir}/01.run_function/${$pep[$i]}[0]/01.General_Gene_Annotation/TNSS\n";
        $sh .= "$tnss_stat ../${$pep[$i]}[0].anno.table.xls --rightList $tnss --outprefix ${$pep[$i]}[0] --outdir .\n";
		($i==0) && ($sh .= "awk '{if(NR==1)print \"Sample ID\\t\"\$0}' ${$pep[$i]}[0].TnSS.stat.xls >$opt{outdir}/02.stat/all_sample.tnss.stat.xls\n");
	   	$sh .= "awk '{if(NR==2)print \"${$pep[$i]}[0]\\t\"\$0}' ${$pep[$i]}[0].TnSS.stat.xls >>$opt{outdir}/02.stat/all_sample.tnss.stat.xls\n";
    }
    writesh("$opt{shdir}/step3.2.annot_tnss.sh", $sh);
    $locate_run .= "sh step3.2.annot_tnss.sh &\n";
    $qsub_run .= "$super_worker step3.2.annot_tnss.sh --resource 1G  $qopts --prefix annot_summary  --splits '$splits'  &\n";
}
### secondary using antismash (for bacteria; for fungi, please use online anitismash )
if ($opt{function} =~ /secondary/) {
    $opt{gbk_list} ||= "$opt{outdir}/02.stat/gbk.list";
    (-s $opt{gbk_list}) || die "Error: $opt{gbk_list}\n";
    my %gbk = split /\s+/, `awk '{print \$1,\$2}' $opt{gbk_list}`;
    my $sh; 
	my $sh2 = "rm -f $opt{outdir}/02.stat/all_sample.secondary_metablism.stat.xls\n";
    for my $i (0..$#pep) {
        my $sample = ${$pep[$i]}[0];
        my $out = "$opt{outdir}/01.run_function/$sample/03.Secondary_Metabolism";
        -d $out || `mkdir -p $out`;
        $sh .= "cd $out\n";
        $sh .= "$antismash $gbk{$sample} --clusterblast --outputfolder $out --disable-embl -d >antismash.log\n";
        $sh .= "$gene_num geneclusters.txt $sample.number.stat\n";
        $sh .= "sed -i '1i\\clusters\\tclusters_number\\tgene_number' $sample.number.stat\n";
        $sh .= "$bar_diagram --table $sample.number.stat --style 2 --show_data --rotate=\"-45\" --y_title \"Number(#)\"  --size_sig 15 >$sample.cluster_num.svg\n";
        $sh .= "$convert $sample.cluster_num.svg $sample.cluster_num.png\n";
		$sh .= "rm -f $out*.fasta\n\n";
		$sh2 .= "awk '{if(NR!=1)print \"$sample\\t\"\$0}' $out/$sample.number.stat >>$opt{outdir}/02.stat/all_sample.secondary_metablism.stat.xls\n";
    }
	$sh2 .= "sed -i '1i\\Sample ID\\tClusters\\tClusters_number\\tGene_number' $opt{outdir}/02.stat/all_sample.secondary_metablism.stat.xls\n";
    writesh("$opt{shdir}/step3.3.1.annot_secondary.sh", $sh);
    writesh("$opt{shdir}/step3.3.2.stat_secondary.sh", $sh2);
    $locate_run .= "sh step3.3.1.annot_secondary.sh\nsh step3.3.2.stat_secondary.sh";
    $qsub_run .= "$super_worker step3.3.1.annot_secondary.sh --resource 4G  $qopts --prefix annot_secondary  --splits '$splits'\n$super_worker step3.3.2.stat_secondary.sh --resource 1G $qopts --prefix stat_second --splits '$splits'\n";
}

### Prophage ###
if ($opt{function} =~ /prophage/) {
	$opt{gbk_list} ||= "$opt{outdir}/02.stat/gbk.list";
	(-s $opt{gbk_list}) || die "Error: $opt{gbk_list}\n";
	my %gbk = split /\s+/, `awk '{print \$1,\$2}' $opt{gbk_list}`;
	my $sh;
	my $sh2 = "rm -f $opt{outdir}/02.stat/all_sample.prophage.stat.xls\n";
	for my $i (0..$#pep) {
		my $sample = ${$pep[$i]}[0];
		my $out = "$opt{outdir}/01.run_function/$sample/04.Prophage";
		-d $out || `mkdir -p $out`;
		$sh .= "cd $out\n";
		$sh .= "$prophage_seed $gbk{$sample} tempdir\n";
		$sh .= "$prophage_phiSpy  -i tempdir -o . -n 2 \n";
#$sh .= "awk '{print \$2}' prophage.tbl |sed 's/_/\\t/g' |awk 'BEGIN{print \"Locate\\tStart\\tEnd\\tLength\"}{print \$0\"\\t\"\$3-\$2+1}' > $sample.Prophage.xls \n\n";  # by lss at  201702
        $sh .= "awk '{print \$2}' prophage.tbl |sed 's/_/\\t/g' |awk 'BEGIN{print \"Prophage_ID\\tLocate\\tStart\\tEnd\\tLength\"}{x++;print \"Prophage_\"x\"\\t\"\$0\"\\t\"\$3-\$2+1}' >Prophage.temp\n";
        $sh .= "$part_seq_gene --tab Prophage.temp --seq $ass{$sample} --gff $gff{$sample} --prefix $sample.Prophage\n\n";
		$sh2 .= "awk '{if(NR!=1)a+=1;b+=\$5}END{print \"$sample\\t\"a\"\\t\"b\"\\t\"b/a}' $out/$sample.Prophage.xls >> $opt{outdir}/02.stat/all_sample.prophage.stat.xls \n";
	}
	$sh2 .= "sed -i '1i\\Sample_ID\\tProphage_Num\\tTotal_Length\\tAverage_Length' $opt{outdir}/02.stat/all_sample.prophage.stat.xls \n";
	writesh("$opt{shdir}/step3.4.1.annot_prophage.sh", $sh);
	writesh("$opt{shdir}/step3.4.2.stat_prophage.sh", $sh2);
	$locate_run .= "sh step3.4.1.annot_prophage.sh\nsh step3.4.2.stat_prophage.sh";
	$qsub_run .= "$super_worker step3.4.1.annot_prophage.sh --resource 2G  $qopts --prefix annot_prophage  --splits '$splits'\n$super_worker step3.4.2.stat_prophage.sh --resource 1G $qopts --prefix stat_prophage --splits '$splits'\n";
}
### CRISPR
if ($opt{function} =~ /crispr/) {
	my ($sh, $sh2);
	$sh2 = "rm -f $opt{outdir}/02.stat/all_sample.crispr.stat.xls\n";
	while(my($sample,$seq_path) = each(%ass)){
		my $out = "$opt{outdir}/01.run_function/$sample/05.CRISPR";
		-d $out || `mkdir -p $out`;
		$sh .= "cd $out\n";
		$sh .= "cp $seq_path $sample \n";
		$sh .= "$crispr -i $sample \n";
#		$sh .= "awk -vOFS=\"\\t\" '{print \$1,\$2,\$3,\$9,\$10}' $sample.sameRLen.dr > $sample.dr.xls \n ";
		$sh .= "$crispr_dr $sample $sample.sameRLen.gff3 $sample.dr.xls \n";
		$sh .= "awk '\$3==\"CRISPR\"' $sample.sameRLen.gff3 |sed 's/\=/\\t/g' |sed 's/;/\\t/g' |awk 'BEGIN{print \"SeqID\\tStart\\tEnd\\tStrand\\tLength\\taSPLength\\tSPnum\\taDRLength\"}{print \$1\"\\t\"\$4\"\\t\"\$5\"\\t\"\$7\"\\t\"\$16\"\\t\"\$18\"\\t\"\$20\"\\t\"\$22}' >  $sample.crispr.xls \n\n";
		$sh2 .= "awk '{if(NR!=1)a+=1;b+=\$5}END{print \"$sample\\t\"a\"\\t\"b\"\\t\"b/a}' $out/$sample.crispr.xls >> $opt{outdir}/02.stat/all_sample.crispr.stat.xls \n";		
	}
	$sh2 .= "sed -i '1i\\Sample_ID\\tCRISPR_Num\\tTotal_Length\\tAverage_Length' $opt{outdir}/02.stat/all_sample.crispr.stat.xls \n";
	writesh("$opt{shdir}/step3.5.1.annot_crispr.sh", $sh);
	writesh("$opt{shdir}/step3.5.2.stat_crispr.sh", $sh2);
	$locate_run .= "sh step3.5.1.annot_crispr.sh\nsh step3.5.2.stat_crispr.sh";
	$qsub_run .= "$super_worker step3.5.1.annot_crispr.sh --resource 2G  $qopts --prefix annot_crispr  --splits '$splits'\n$super_worker step3.5.2.stat_crispr.sh --resource 1G $qopts --prefix stat_crispr --splits '$splits'\n";
}
### do sh

((split /\n/,$locate_run)[-1] !~ /^wait/) && ($locate_run .= "wait\n") && ($qsub_run .= "wait\n");

## qsub=========================================================================================================================
writesh ("$opt{shdir}/qsub_Step4.genome_function.sh.sh", $qsub_run);
$opt{notrun} && exit;
$opt{locate} ? system "cd $opt{shdir}\n$locate_run" : system"cd $opt{shdir}\n$qsub_run";

# ==============================================================================================================================
# sub function
sub writesh {
    my ($sh_name, $sh) = @_;
    open SH, ">$sh_name" || die "Error: Cannot create $sh_name.\n";
    print SH $sh;
    close SH;
}

# sub1 used in step1 and step2 ...
