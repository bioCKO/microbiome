#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use File::Basename;
use Getopt::Long;

# set default options
my %opt = ("outdir",".","shdir",".","step","123456","spe_type","B",
    ## for step2345: split
    "fa_split","10",
    ## step1: gene
    "shape","partial",
    ## step2: repeat
    ### repbase, repeatmasker
    "repbase_par"," -nolow -no_is -norna -engine wublast -parallel 1",
    ### trf
    "trf_par"," 2 7 7 80 10 50 2000 -d -h",
    ### proteinmakser
    "protmask_par"," -noLowSimple -pvalue 1e-4",
    ## step3: ncRNA
    ## step4: pseudogene
    "solar_cut","0.5","genewise_cut", "0.5", "extent","2000",
    ## step5: tranposon
    "transpo_type","nuc-pep",
);

# get options from screen
GetOptions(\%opt, "ass_list:s","outdir:s","shdir:s","step:n","notrun","qopt:s","verbose","locate","help","splitn:n",
    ## for step0: split (if step2345)
    "fa_split:n", 
    ## step1: gene
    "spe_type:s","shape:s","gcode:n","config:s",
    ## step2: repeat
    "repbase","trf","protein_mask","repeat_denovo","repbase_par:s","trf_par:s","protmask_par:s","repeat_stat",
    ## step3: ncRNA
    "ncRNA_type:s", "rRNAh_ref:s","ncRNA_stat",   
    ## step4: pseudogene
    "pseudo_ref:s","solar_cut:s","genewise_cut:s","extent:s",
    ## step5: tranposon
    "transpo_type:s","pep_list:s",
);

# get software/script's path
use lib "$Bin/../00.Commonbin";
use PATHWAY;
(-s "$Bin/../../bin/cfg.5.1.txt") || die"Error: can't find config at $Bin/../../bin, $!\n";
my ($super_worker, $gm_key, $GeneMarkS, $GeneMark_hmm, $convert, $repeat_build, $repeat_modeler,$repeat_masker, $repeat_masker_lib, $trf,$prot_mask,   $SOF_RNAmmer,$formatdb,$blast,$tRNAscan,$ncRNA_database,$cmsearch,$Rfam_cm_dir,   $solar,$gene_wise) = get_pathway("$Bin/../../bin/cfg.5.1.txt",[qw(SUPER_WORKER GM_KEY GENEMARKS GENEMARK_HMM CONVERT    REPEAT_FILTER REPEAT_MODELER REPEAT_MASKER RPT_MSK_LIB TRF PROTEIN_MASKER   RNAMER FORMATDB BLASTALL TRNASCAN NCRNA_DB CMSEARCH CM_SPLIT   SOLAR GENEWISE )]);
## for prepare step
my $fasta_deal = "perl $Bin/00.Common_bin/fastaDeal.pl";
my $trans_gbk = "perl $Bin/../00.Commonbin/genbank_parser_v3.1.pl";
## for step1
my $genemark_convert = "perl $Bin/01.Gene-Prediction/1.genemark_convert_2.pl";
my $plot_length = "perl $Bin/01.Gene-Prediction/2.plot_length_svg.pl";
my $gene_predict_F = "perl $Bin/01.Gene-Prediction/fungi/bin/gene-predict.pl";
my $gene_predict_F_pasa = "perl $Bin/01.Gene-Prediction/fungi/bin/gene-predict.pasa.pl";
## for step2
my $repeat_to_gff = "perl $Bin/02.Repeat-Finding/repeat_to_gff.pl";
## for step3: ncRNA
my $delete_dupLine = "perl $Bin/03.ncRNA-Finding/1.delete_dupLine.pl"; 
my $delete_duprRNA = "perl $Bin/03.ncRNA-Finding/2.delete_duprRNA.pl";
my $gbk_get_rRNA = "perl $Bin/03.ncRNA-Finding/3.get_rRNA_from_genbank_v4.pl";
my $delet_dupli_rRNA = "perl $Bin/03.ncRNA-Finding/4.delet_dupli_rRNA.pl";
my $blast_parser = "perl $Bin/03.ncRNA-Finding/5.blast_parser.pl";
my $homology_rRNA_sim = "perl $Bin/03.ncRNA-Finding/6.homology_rRNA_sim.pl";
my $tab_to_gff3 = "perl $Bin/03.ncRNA-Finding/7.tab_to_gff3.pl";
my $filter_blast_hit = "perl $Bin/03.ncRNA-Finding/8.filter_blast_hit.pl";
my $creat_cmfile = "perl $Bin/03.ncRNA-Finding/9.creat_cmfile.pl";
my $cmsearch_combine = "perl $Bin/03.ncRNA-Finding/10.cmsearch_combine.pl";
my $filter_ncRNA_gff = "perl $Bin/03.ncRNA-Finding/11.filter_ncRNA_gff.pl";
my $tRNAscan_to_gff3 = "perl $Bin/03.ncRNA-Finding/12.tRNAscan_to_gff3.pl";
my $ncRNA_merge = "perl $Bin/03.ncRNA-Finding/13.ncRNA_merge.pl";
## for step4 pseudogene
### step4.1
my $solar_add_realLen = "perl $Bin/04.Pseudogene/1.solar_add_realLen.pl";
my $solar_add_identity = "perl /$Bin/04.Pseudogene/2.solar_add_identity.pl";
my $get_pos = "perl $Bin/04.Pseudogene/3.get_pos.pl";
my $extract_seq = "perl $Bin/04.Pseudogene/4.extract_sequence.pl";
my $prepare_pep = "perl $Bin/04.Pseudogene/5.prepare_pep.pl"; ## out step4.2
my $gwise_file_sh = "perl $Bin/04.Pseudogene/6.gwise_file_sh.pl";
### step4.3
my $gw_parser = "perl $Bin/04.Pseudogene/7.gw_parser.pl";
my $gw_parser_proka = "perl $Bin/04.Pseudogene/7.gw_parser_proka.pl";
my $merge_overlap = "perl $Bin/04.Pseudogene/8.merge_overlap.pl";
my $cat_file = "perl $Bin/04.Pseudogene/9.cat_file.pl";
my $gw_to_gff = "perl $Bin/04.Pseudogene/10.gw_to_gff.pl";
my $getGene = "perl $Bin/04.Pseudogene/11.getGene.pl";
my $cds2pep_zy = "perl $Bin/04.Pseudogene/12.cds2pep_zy.pl";
my $cat_dir = "perl $Bin/../00.Commonbin/cat_dir.pl";
### step5: transposon
my $split_pep = "perl $Bin/../04.Genome_Function/Commonbin/split_fa.pl";
my $transposonPSI = "perl $Bin/05.Transposon/transposonPSI.pl";
my $tpsi_stat = "perl $Bin/05.Transposon/tpsi.stat.pl";
my $TPSI_btab_to_gff3 = "perl $Bin/05.Transposon/TPSI_btab_to_gff3.pl";
### stat result
my $component_stat = "perl $Bin/06.Stat/PGAP.stat_v3.pl";
my $sample_stat = "perl $Bin/06.Stat/sample_stat.pl";
# ==============================================================================================================================
( $opt{ass_list} && -s $opt{ass_list} && !$opt{help} ) || die"Name: Genome Component Pipeline
Descriptions:  Genome Component Pipeline
Date: 20160320
Version: v1.0
Connector: lishanshan[AT]novogene.com
Usage: perl $0  --ass_list ass.list  --spe_type B --shdir Detail  --outdir 03.Genome_Component  --step 123456  --repbase --trf --protein_mask --repeat_denovo --repeat_stat  --ncRNA_type rRNAd-rRNAh-tRNA-sRNA --rRNAh_ref rRNAh_ref.list --ncRNA_stat  --pseudo_ref pseudo_ref.list --transpo_type nuc-pep
    [main opts]
       *--ass_list      [str]   list of assembly fasta sequences
                                Form:  sample_id  ass_seq_path
                                e.g.:  sample1    02.3.fill/all.scafSeq.fna
        --spe_type      [str]	species type, B: Bacteria, F: Fungi. default = B (for gene prediction and set ncRNA type)
       *--step          [num]   step to run. default = \"\".
                                step1: gene prediction
                                step2: repeat_finding
                                step3: ncRNA-Finding
                                step4: pesudo-gene prediction
                                step5: transposon prediction
                                step6: stat result
    [opts for split fasta]
        --fa_split      [num]   cut number of assembly fasta. default = 10

    [other opts for step1]
        --shape         [str]   set the shape of prokaryote DNA, circular,linear,partial, default=partial
        --gcode         [num]   genetic code, default: 11; supported: 11, 4 and 1
        --config        [num]   config file for fungi gene predict. if not set will use augustus method
                                e.g.
                                >REFERENCE:
                                ref1:
                                gbk=ref1.gbk
                                ref2:
                                pep=ref1.pep
                                >HOMOGENE:
                                sample1 ref1 ref2
                                >TRINITY:
                                sample1 trinity.fa
                                sample2 trinity.fa
                                >TRANSCRIPT:
                                sample1 fq1 fq2 fq1 fq2
                                sample2 fq1 fq2
    [other opts for step2]
        --repbase               run RepeatMasker. default not run.
        --trf                   run trf.  default not run.
        --proteinmask           run RepeatProteinMask. default not run.
        --repeat_denovo         run Denovo Repeat Finding.(firstly built model, then run repbase). default not run.
        --repbase_par   [str]   parameter for --repbase. default = \" -nolow -no_is -norna -engine wublast -parallel 1\"
        --trf_par       [str]   parameter for --trf. default = \"  2 7 7 80 10 50 2000 -d -h\"
        --protmask_par  [str]   parameter for --protmask_par. default = \" -noLowSimple -pvalue 1e-4\"
        --repeat_stat           for each sample, cat the splitted fasta result to one file. default not run.

    [other opts for step3]
        --ncRNA_type    [str]   RNA types: rRNAd-rRNAh-tRNA-sRNA-miRNA-snRNA; For bacteria: default = \"rRNAd-tRNA-sRNA\"; for fungi: default = \"rRNAd-tRNA-sRNA-miRNA-snRNA\".
       *--rRNAh_ref    [str]   fasta list file of ref genomes, used to predict rRNA using homologyous method
                                e.g. gbk  sample1  ref1.gbk  ref2.gbk ref3.gbk
                                     rRNA sample3  ref1_rNRA.fa
        --ncRNA_stat            for each sample, cat the splitted fasta result to one file. default not run.   
        [other opts for step4]
       *--pseudo_ref    [str]   list of ref name and its pep file. must be set if run step4
                                e.g. 
                                     sample1 ref1_name ref1.pep
                                     sample2 ref2_name ref2.pep
        --solar_cut     [num]   cutoff of gene align rate for solar result (default 0.5).
        --genewise_cut  [num]   cutoff of gene align rate for genewise result (default  0.5).
        --extent        [num]   extent length of flanking sequence around blast result (default 2000).

    [other opts for step5]
        --transpo_type  [str]   method,can be nuc-pep; \"nuc\" using nucleotide seq of genome; \"pep\" using peptide seq.default = \"nuc-pep\n
        --pep_list      [str]   pep list used to predict transposon using \"pep\" method if --transpo_type pep. if not set, pep.list will be create after step1 gene prediction

    [opts for other]
        --outdir        [str]   directory for output data. default = ./
        --shdir         [str]   directory for output shell script. default = ./Shell
        --notrun                just produce shell script, not run. default not set
        --qopts         [str]   other qsub options for superworker 
        --locate                run locate
        --splitn        [num]   cut files when superworker
        --help          [str]   help information for readfq 
        --verbose               output running progress information to screen  
        [note]
        step1: GeneMarkS for prokaryote. (from gene-predict.pl by liangshuqing in 2014)
            Firstly, run GeneMarkS to make a \"hmm.mod\" file. We choose --combine option to combine the GeneMarkS generated (native) and Heuristic model. then run GeneMark.hmm to predict genes.
            For prokayote chromosome, if it starts from the replication origin site, then the shape should be set as linear. In this case, no gene will be destroyed. Be cautious to set the shape as circular, it is not stable and ease to get error.
";
# ==============================================================================================================================
# -s abs mkdir
foreach($opt{outdir}, $opt{shdir}, "$opt{outdir}/01.run_component", "$opt{outdir}/02.stat") { (-d $_) || `mkdir -p $_`;}
foreach($opt{ass_list}, $opt{outdir}, $opt{shdir} ) {$_ = abs_path($_);}
# get options for software/script
$super_worker .= ($opt{qopts}) ? " --qopts ' $opt{qopts}'" : "";
$super_worker .= ($opt{splitn}) ? " --splitn $opt{splitn}" : "";
$fasta_deal .= " -cutf $opt{fa_split}";
## for step1: gene
$GeneMarkS .= ($opt{spe_type} eq "B") ? " --prok" :  ($opt{spe_type} eq "V") ? " --virus" :  ($opt{spe_type} eq "P") ? " --phage" : "";
if ($opt{spe_type} eq "F") {
    $opt{gcode} ||=1;
}elsif($opt{spe_type} eq "B"){
    $opt{gcode} ||=11;
}

## for step2: repeat
$repeat_masker .= "$opt{repbase_par}";
$prot_mask .= "$opt{protmask_par}";
## for step3: ncRNA
$opt{ncRNA_type} ||= ($opt{spe_type} =~ /F/) ? "rRNAd-tRNA-sRNA-miRNA-snRNA" : "rRNAd-tRNA-sRNA";

# main scripts
my ($locate_run,$qsub_run);
my $splits = '\n\n';
## read input
my (@ass_info, @split_dir, @split_fa, @repeat_dir, @ncRNA_dir, @pseudo_dir, @transposon_dir);
my $i = 0;
for (`less $opt{ass_list}`) {
    chomp(my @l = split /\s+/, $_);
    @{$ass_info[$i]} = @l;
    (-d "$opt{outdir}/01.run_component/$l[0]") || `mkdir -p $opt{outdir}/01.run_component/$l[0]`;
#    (-d "$opt{outdir}/01.run_component/$l[0]/00.Split_fa") || mkdir "$opt{outdir}/01.run_component/$l[0]/00.Split_fa";
    my $seq = basename $l[1];
    foreach(1..$opt{fa_split}) {push @{$split_fa[$i]}, "$opt{outdir}/01.run_component/$l[0]/00.Prepare/split_fa/$seq.$_";}
    push @split_dir,"$opt{outdir}/01.run_component/$l[0]/00.Prepare/split_fa";
    push @repeat_dir,"$opt{outdir}/01.run_component/$l[0]/02.Repeat-Finding";
    push @ncRNA_dir,"$opt{outdir}/01.run_component/$l[0]/03.ncRNA-Finding";
    push @pseudo_dir,"$opt{outdir}/01.run_component/$l[0]/04.Pseudo_Gene";
    push @transposon_dir,"$opt{outdir}/01.run_component/$l[0]/05.Transposon";
    $i++;
}

## for prepare. 1. split fasta 2. build database if use repeat_denovo method to run step 2(repeat)
if ($opt{step} =~ /[123]/) {
    my $sh = "";
    ##for fungi gene prediction
    if ($opt{spe_type} =~ /F/ && $opt{step} =~ /1/ && $opt{config}) {
        my %ref;
        open IN,"$opt{config}" ||die"Error in $opt{config}\n";
        $/='>';
        <IN>;
        while (<IN>) {
            chomp(my @l = split /\n/);
            if ($l[0] =~ /REFERENCE\s*:/) {
                my $tempref;
                foreach (@l[1..$#l]) {
                    /^\s*$/ && next;
                    /(\S+):/ && ($tempref = $1);
                    /(\S+)\s*=\s*(\S+)/ && (${$ref{$tempref}}{$1} = $2);
                }
            }elsif($l[0] =~ /HOMOGENE\s*:/) {
                foreach (@l[1..$#l]) {
                    /^\s*$/ && next;
                   my @homo = split /\s+/, $_;
                   my $genedir="$opt{outdir}/01.run_component/$homo[0]/01.Gene_Prediction/";
                   (-d $genedir) || `mkdir -p $genedir`; 
                   (-s "$genedir/homo_ref.list") && (`rm -f $genedir/homo_ref.list`);
                   foreach my $refname (@homo[1..$#homo]) {
                        if (${$ref{$refname}}{gbk}) {
                            my $base = basename(${$ref{$refname}}{gbk});
                            (-d "$opt{outdir}/00.Reference/") || `mkdir -p $opt{outdir}/00.Reference`;
                            $sh .= "ln -sf ${$ref{$refname}}{gbk} $opt{outdir}/00.Reference/$base\n";
                            $sh .= "$trans_gbk $opt{outdir}/00.Reference/$base --type pep\n";
                            ${$ref{$refname}}{pep} = "$opt{outdir}/00.Reference/$base.pep";
                        }
                        $sh .= "cat ${$ref{$refname}}{pep} >>$genedir/homo_ref.pep\n\n";
                    }
                    writesh("$genedir/homo_ref.list","Name= $homo[0]\npep = $genedir/homo_ref.pep\n");
                }                   
            }elsif($l[0] =~ /TRINITY\s*:/) {
                foreach (@l[1..$#l]) {
                    /^\s*$/ && next;
                    my @trinity = split /\s+/, $_;
                    my $genedir="$opt{outdir}/01.run_component/$trinity[0]/01.Gene_Prediction";
                    (-d $genedir) || `mkdir -p $genedir`; 
                    system"ln -sf $trinity[1] $genedir/trinity.fa";
                }
            }elsif($l[0] =~ /TRANSCRIPT\s*:/) {
                foreach (@l[1..$#l]) {
                    /^\s*$/ && next;
                    my @transcript = split /\s+/, $_;
                    my $genedir="$opt{outdir}/01.run_component/$transcript[0]/01.Gene_Prediction";
                    (-d $genedir) || `mkdir -p $genedir`; 
                    ($#transcript % 2) && die"wrong format for transcripts\n";
                    my $out;
                    for (my $i=1;$i<$#transcript;$i=$i+2) {
                        $out .= "$transcript[$i]\t$transcript[$i+1]\n";
                    }
                    writesh("$genedir/transcript.list", "$out");
                }            
            }

        }
        close IN;$/="\n";
    }

	if($opt{step} =~ /2|3/){
		for my $i (0..$#ass_info) {
			(-d $split_dir[$i]) || `mkdir -p $split_dir[$i]`;
			$sh .= "$fasta_deal ${$ass_info[$i]}[1] --outdir $split_dir[$i]\n\n";
		}
	}
    if (($opt{step} =~ /2/) && $opt{repeat_denovo}) {
        for my $i (0..$#ass_info) {
            my $build = "$opt{outdir}/01.run_component/${$ass_info[$i]}[0]/00.Prepare/repeat_builddb";
            (-d $build) || `mkdir -p $build`;
            $sh .= "cd $build;\n$repeat_build -name mydb -engine abblast ${$ass_info[$i]}[1] >RepeatModeler.log; \n";
            $sh .= "$repeat_modeler -database mydb -engine abblast >> RepeatModeler.log;\n\n";
        }
    }
    writesh("$opt{shdir}/step0.prepare.sh", $sh);
    $locate_run .= "sh step0.prepare.sh\n";
    $qsub_run .= "$super_worker step0.prepare.sh --resource 1G  --prefix prepare --splits '$splits' \n";
}

## step1: predict gene =========================================================================================================================================== 
if ($opt{step} =~ /1/) {
    my ($sh, $pep_list, $cds_list, $gff_list);
    for my $i (0..$#ass_info) {
        my ($sample, $asseq) = (${$ass_info[$i]}[0], ${$ass_info[$i]}[1]);
        my $out = "$opt{outdir}/01.run_component/$sample/01.Gene_Prediction";
        (-d $out)|| `mkdir -p $out`;
        if ($opt{spe_type} =~ /B/) {
            $sh .= "cd $out\n";
            # predict gene
            $sh .= "if [ -e ~/.gm_key ]; then diff ~/.gm_key $gm_key; if [ \$? -ne 0 ]; then rm ~/.gm_key; cp $gm_key ~/.gm_key; fi; else cp $gm_key ~/.gm_key; fi\n";
            $sh .= "$GeneMarkS -name $sample -clean -gcode $opt{gcode} -shape $opt{shape} --combine $asseq\n";
            $sh .= "$GeneMark_hmm -m $sample\_hmm_*.mod -o $sample.gmhmmp -a -d -p 1 -f L $asseq\n";
            # convert and plot 
            $sh .= "$genemark_convert --final $sample"."GM --gcode $opt{gcode} --log --verbose $sample.gmhmmp $asseq\n";  ##yue
            $sh .= "$plot_length $sample.gmhmmp.cds  $sample.gmhmmp.cds 2000\n";
            $sh .= "$convert $sample.gmhmmp.cds.svg $sample.gmhmmp.cds.png\n";
            $sh .= "\n";
            $pep_list .= "$sample\t$out/$sample.gmhmmp.pep\n";
            $cds_list .= "$sample\t$out/$sample.gmhmmp.cds\n";
            $gff_list .= "$sample\t$out/$sample.gmhmmp.gff\n";
        }elsif ($opt{spe_type} =~ /F/) {
            my $PASA_flag = 0;
            if(-e "$out/trinity.fa"){$PASA_flag = 1;}else{$PASA_flag=0;}
            my $run_note = "$opt{shdir}/step1.gene_predict_fungi/$sample/step1.gene_predict_fungi";
            my $shdir = "$opt{shdir}/step1.gene_predict_fungi/$sample"; (-d $shdir)|| `mkdir -p $shdir`;
            if($PASA_flag==0){
                if(-e "$out/homo_ref.list"){
                    $sh .= "$gene_predict_F --homology --code $opt{gcode}  --ref $out/homo_ref.list ";
                }else{
                    chomp (my $augustus_species = `whoami`);
                    $augustus_species .= $$;
					$augustus_species .= $sample;
                    $sh .= "$gene_predict_F --augustus --code $opt{gcode}  --species $augustus_species --self ";
                }
                $sh .= "--verbose --prefix $sample --outdir $out $asseq --shdir $shdir > $run_note.log 2> $run_note.err  &\n";
                $pep_list .= "$sample\t$out/$sample.pep\n";
                $cds_list .= "$sample\t$out/$sample.cds\n";
                $gff_list .= "$sample\t$out/$sample.gff\n";
            }elsif($PASA_flag==1){
                chomp (my $augustus_species = `whoami`);
                $augustus_species .= $$;
				$augustus_species .= $sample;
                $sh .= "$gene_predict_F_pasa --augustus --species $augustus_species --self --cpu 10 --run qsub --prefix $sample --outdir $out --shdir $shdir --ass_path $asseq ";
                if(-e "$out/transcript.list"){ 
                    $sh .= "--transcript_reads $out/transcript.list ";
                }
                if(-e "$out/trinity.fa"){
                    $sh .= "--trinity_seq $out/trinity.fa ";
                }
                if(-e "$out/homo_ref.list"){
                    $sh .= "--homo_ref $out/homo_ref.list ";
                }
                $sh .= "&\n";
                $pep_list .= "$sample\t$out/$sample.pep\n";
                $cds_list .= "$sample\t$out/$sample.cds\n";
                $gff_list .= "$sample\t$out/$sample.gff\n";
            }
        }
    }
	$opt{spe_type} =~ /F/ && ($sh .= "wait\n");
    writesh("$opt{outdir}/02.stat/pep.list", $pep_list);
    writesh("$opt{outdir}/02.stat/cds.list", $cds_list);
    writesh("$opt{outdir}/02.stat/gff.list", $gff_list);

    writesh("$opt{shdir}/step1.gene_predict.sh", $sh);
    if ($opt{spe_type} =~ /B/) {
        $locate_run .= "sh step1.gene_predict.sh &\n";
        $qsub_run .= "$super_worker step1.gene_predict.sh --resource 1G  --prefix gene_predict --splits '$splits' &\n";
    }elsif($opt{spe_type} =~ /F/) {
        $locate_run .= "sh step1.gene_predict.sh &>step1.gene_predict.sh.log &\n";
#        $qsub_run .= "$super_worker  step1.gene_predict.sh &>step1.gene_predict.sh.log &\n";
        $qsub_run .= "sh  step1.gene_predict.sh &>step1.gene_predict.sh.log &\n";
    }
}
## step 2: repeat finding ====================================================================================================================================
if ($opt{step} =~ /2/) {
    foreach(@repeat_dir) {(-d $_) || `mkdir -p $_`}
    if ($opt{repbase}) {
        my $sh_name = "$opt{shdir}/step2.1.repbase.sh";
        foreach ("$sh_name.o", "$sh_name.e") {(-d $_) || `mkdir -p $_`}
        my $sh = "";
        for my $i (0..$#ass_info) {
            foreach("$repeat_dir[$i]/01.repbase", "$repeat_dir[$i]/01.repbase/cut"){(-d $_) || `mkdir -p $_`};
            foreach (@{$split_fa[$i]}) {
                $sh .= "$repeat_masker -lib $repeat_masker_lib $_ -dir $repeat_dir[$i]/01.repbase/cut  >$sh_name.o/${$ass_info[$i]}[0].o  2>$sh_name.e/${$ass_info[$i]}[0].e\n"; 
            } 
        }
        writesh($sh_name, $sh);
        $locate_run .= "sh tep2.1.repbase.sh & \n";
        $qsub_run .= "$super_worker step2.1.repbase.sh  --resource 3G  --prefix repbase --splits '\\n' &\n";
    }
### trf
    if ($opt{trf}) {
        my $sh = "";
        for my $i (0..$#ass_info) {
            foreach("$repeat_dir[$i]/02.trf","$repeat_dir[$i]/02.trf/cut"){(-d $_) || `mkdir -p $_`}
            foreach (@{$split_fa[$i]}) {
                $sh .= "cd $repeat_dir[$i]/02.trf/cut; $trf $_ $opt{trf_par}\n";
            }
        }
        writesh("$opt{shdir}/step2.2.trf.sh", $sh);
        $locate_run .= "sh step2.2.trf.sh &\n";
        $qsub_run .= "$super_worker step2.2.trf.sh --resource 1G  --prefix trf --splits '\\n' &\n";
    }
### protein masker
    if ($opt{protein_mask}) {
        my $sh = "";
        for my $i (0..$#ass_info) {
            foreach("$repeat_dir[$i]/03.protein_mask", "$repeat_dir[$i]/03.protein_mask/cut"){(-d $_) || `mkdir -p $_`};
            foreach (@{$split_fa[$i]}) {
                $sh .= "$prot_mask $_; mv $_.* $repeat_dir[$i]/03.protein_mask/cut/\n";
            }
        }
        writesh("$opt{shdir}/step2.3.protein_mask.sh", $sh);
        $locate_run .= "sh step2.3.protein_mask.sh &\n";
        $qsub_run .= "$super_worker step2.3.protein_mask.sh --resource 2G  --prefix prot_mask --splits '\\n' & \n";
    }
### denovo
    if ($opt{repeat_denovo}) {
        my $sh_name = "$opt{shdir}/step2.4.repeat_denovo.sh";
        foreach ("$sh_name.o", "$sh_name.e") {(-d $_) || `mkdir -p $_`;}
        my $sh = "";
        for my $i (0..$#ass_info) {
            foreach("$repeat_dir[$i]/04.repeat_denovo", "$repeat_dir[$i]/04.repeat_denovo/cut"){(-d $_) || `mkdir -p $_`;}
            foreach (@{$split_fa[$i]}) {
#### run repbase using denovo model in prepare step
                $sh .= "$repeat_masker $_ -lib $opt{outdir}/01.run_component/${$ass_info[$i]}[0]/00.Prepare/repeat_builddb/*/*classified -dir $repeat_dir[$i]/04.repeat_denovo/cut >$sh_name.o/${$ass_info[$i]}[0].o  2>$sh_name.e/${$ass_info[$i]}[0].e  \n "; 
            } 
            $sh .= "\n";
        }
        writesh($sh_name, $sh);
        $locate_run .= "sh step2.4.repeat_denovo.sh &\n";
        $qsub_run .= "$super_worker step2.4.repeat_denovo.sh --resource 3G  --prefix repeat_denov --splits '$splits' & \n";
    }
    $locate_run .= "wait\n";
    $qsub_run .= "wait\n";
### merge cut result into one file    
    if ($opt{repeat_stat}) {
        my $sh = "";
        for my $i (0..$#ass_info) {
            if (-d "$repeat_dir[$i]/01.repbase") {
                $sh .= "cd $repeat_dir[$i]/01.repbase\ncat cut/*.out |grep -v 'There were no repetitive sequence'|grep -v 'RepeatMasker quit'  >${$ass_info[$i]}[0].repbase.out\n$repeat_to_gff --prefix ${$ass_info[$i]}[0] ${$ass_info[$i]}[0].repbase.out\n\n";
            }
            if (-d "$repeat_dir[$i]/02.trf") {
                $sh .= "cd $repeat_dir[$i]/02.trf\ncat cut/*.dat >${$ass_info[$i]}[0].trf.dat\n$repeat_to_gff --prefix ${$ass_info[$i]}[0] ${$ass_info[$i]}[0].trf.dat\n\n";
            }
            if (-d "$repeat_dir[$i]/03.protein_mask") {
                $sh .= "cd $repeat_dir[$i]/03.protein_mask\ncat cut/*.annot >${$ass_info[$i]}[0].protein_mask.annot\n$repeat_to_gff --prefix ${$ass_info[$i]}[0] ${$ass_info[$i]}[0].protein_mask.annot\n\n";
            }
            if (-d "$repeat_dir[$i]/04.repeat_denovo") {
                $sh .= "cd $repeat_dir[$i]/04.repeat_denovo\ncat cut/*.out  |grep -v 'There were no repetitive sequence' | grep -v 'RepeatMasker quit' >${$ass_info[$i]}[0].denovo_repbase.out\n$repeat_to_gff --prefix ${$ass_info[$i]}[0] ${$ass_info[$i]}[0].denovo_repbase.out\n\n";
            }
        }
        writesh("$opt{shdir}/step2.5.repeat_stat.sh", $sh);
        $locate_run .= "sh step2.5.repeat_stat.sh & \n";
        $qsub_run .= "$super_worker step2.5.repeat_stat.sh --resource 1G  --prefix repeat_stat --splits '$splits' & \n";
    }
}

## step3: ncRNA====================================================================================================================================================

my %rRNA_ref;
if ($opt{step} =~ /3/) {
    foreach(@ncRNA_dir) { (-d $_) || `mkdir -p $_` }
### for rRNA by denovo method using software RNAmmer
    if ($opt{ncRNA_type} =~ /rRNAd/) {
        foreach(@ncRNA_dir) { (-d "$_/rRNA/denovo") || `mkdir -p $_/rRNA/denovo` }
        my $species = ($opt{spe_type} =~ /B/) ? "bac" : "euk";
        my $sh;
        for my $i (0..$#ass_info) {
            my $sample = ${$ass_info[$i]}[0];
            $sh .= "cd $ncRNA_dir[$i]/rRNA/denovo\n";
            $sh .= "$SOF_RNAmmer -S $species -m tsu,lsu,ssu -gff $sample.rRNAd.gff -f $sample.rRNAd.fa ${$ass_info[$i]}[1]\n";
            $sh .= "$delete_dupLine $sample.rRNAd.gff $sample.rRNAd.gff2 '^#'\n";
            $sh .= "mv -f $sample.rRNAd.gff2 $sample.rRNAd.gff\n";
            $sh .= "$delete_duprRNA $sample.rRNAd.fa $sample.rRNAd.fa2\n";
            $sh .= "mv -f $sample.rRNAd.fa2  $sample.rRNAd.fa\n";
            if ($species eq "euk"){
                $sh .= "sed \"s/[^\\.]\\b8s_rRNA\\b/\\t5s_rRNA/g\" $sample.rRNAd.gff > $sample.rRNAd.gff2\n";
                $sh .= "mv -f $sample.rRNAd.gff2 $sample.rRNAd.gff\n";
                $sh .= "sed \"s/=8s_rRNA\\b/=5s_rRNA/g\" $sample.rRNAd.fa >$sample.rRNAd.fa2\n";
                $sh .= "mv -f $sample.rRNAd.fa2  $sample.rRNAd.fa\n";
            }
            $sh .= "\n";
        }
        writesh("$opt{shdir}/step3.1.rRNAd.sh", $sh);
        $locate_run .= "sh step3.1.rRNAd.sh  &\n";
        $qsub_run .= "$super_worker step3.1.rRNAd.sh --resource 1G  --prefix rRNAd --splits '$splits' & \n";
    }
### for rRNA using homologous reference
    if ($opt{ncRNA_type} =~ /rRNAh/) {
        ($opt{rRNAh_ref} && -s $opt{rRNAh_ref}) || die "Error: Empty or not exist : $opt{rRNAh_ref}\n";
        #### read rRNAh_ref.list 
        for (`less $opt{rRNAh_ref}`) {
            chomp (my @l = split);
            foreach (2..$#l){
                (-s $l[$_]) || die "Error: empty or not exist : $l[$_].\n";
            }
            $rRNA_ref{$l[1]} = [@l[0,2..$#l]];
        }

        my ($sh1, $sh2);
        for my $i (0..$#ass_info) {
            my $sample = ${$ass_info[$i]}[0];
            (defined $rRNA_ref{$sample}) || next;
            (-d "$ncRNA_dir[$i]/rRNA/homology/cut") || `mkdir -p $ncRNA_dir[$i]/rRNA/homology/cut`;
            $sh1 .= "cd $ncRNA_dir[$i]/rRNA/homology\n";
            $sh2 .= "cd $ncRNA_dir[$i]/rRNA/homology\n";
####  get refs' rRNA seq
            (-s "$ncRNA_dir[$i]/rRNA/homology/all_ref.rRNA.fa") || `rm -f $ncRNA_dir[$i]/rRNA/homology/all_ref.rRNA.fa`;
            if (${$rRNA_ref{$sample}}[0] =~ /gbk/) {
                foreach( @{$rRNA_ref{$sample}}[1..$#{$rRNA_ref{$sample}}] ) {
                    my $ref_base = basename($_);
                    $sh1 .= "$gbk_get_rRNA $_ --outdir $ref_base.rRNA.fa\n";
                }
                $sh1 .= "cat *.rRNA.fa >all_ref.rRNA.fa\n";
            }elsif(${$rRNA_ref{$sample}}[0] =~ /rRNA/) {
                $sh1 .= "cp -f ${$rRNA_ref{$sample}}[1] all_ref.rRNA.fa\n";
            }
            $sh1 .= "$delet_dupli_rRNA all_ref.rRNA.fa all_ref.rRNA.fa.nr\n";
#### blast
            foreach(@{$split_fa[$i]}) {
                my $split_base = basename ($_);
                $sh2 .= "$formatdb -p F -o T -i $_\n";
                $sh2 .= "$blast -p blastn -e 1e-5 -v 10000 -b 10000  -d $_ -i all_ref.rRNA.fa.nr  -o cut/$split_base.blast\n";
                $sh2 .= "$blast_parser -nohead cut/$split_base.blast > cut/$split_base.blast.tab\n";
            }
            $sh1 .= "\n";
            $sh2 .= "\n";
        }
        writesh("$opt{shdir}/step3.1.rRNAh_refrRNA.sh", $sh1);
        $locate_run .= "sh step3.1.rRNAh_refrRNA.sh \n";
        $qsub_run .= "$super_worker step3.1.rRNAh_refrRNA.sh --resource 1G  --prefix rRNAh_ref --splits '$splits' \n";

        writesh("$opt{shdir}/step3.1.rRNAh_blast.sh", $sh2);
        $locate_run .= "sh step3.1.rRNAh_blast.sh & \n";
        $qsub_run .= "$super_worker step3.1.rRNAh_blast.sh --resource 1G  --prefix rRNAh_blast --splits '$splits'  &\n";
    }
### for tRNA using tRNAscan
    if ($opt{ncRNA_type} =~ /tRNA/) {
        foreach(@ncRNA_dir) { (-d "$_/tRNA") || `mkdir -p $_/tRNA` }
        my $species = ($opt{spe_type} =~ /B/) ? "-B" : ($opt{spe_type} =~ /F/) ? "" : "O";
        my $sh;
        for my $i (0..$#ass_info) {
            my $sample = ${$ass_info[$i]}[0];
            (-d "$ncRNA_dir[$i]/tRNA/cut") && `rm -rf $ncRNA_dir[$i]/tRNA/cut`;
            `mkdir -p $ncRNA_dir[$i]/tRNA/cut`;
            foreach(@{$split_fa[$i]}) {
                my $split_base = basename ($_);
                $sh .= "rm -f $ncRNA_dir[$i]/tRNA/cut/$split_base.tRNA $ncRNA_dir[$i]/tRNA/cut/$split_base.tRNA.structure\n$tRNAscan $species -o $ncRNA_dir[$i]/tRNA/cut/$split_base.tRNA -f $ncRNA_dir[$i]/tRNA/cut/$split_base.tRNA.structure $_\n\n";
            }
        }
        writesh("$opt{shdir}/step3.2.tRNA.sh", $sh);
        $locate_run .= "sh step3.2.tRNA.sh & \n";
        $qsub_run .= "$super_worker step3.2.tRNA.sh --resource 1G  --prefix tRNA --splits '$splits' &\n";
    }
    ### sRNA, miRNA(fungi), snRNA(fungi)
    my @types;  my %sh_name;   my $i = 3;
    foreach (qw(sRNA miRNA snRNA)) {
        ($opt{ncRNA_type} =~ /$_/) && push @types, $_;
        @{$sh_name{$_}} = ("step3.$i.1.$_\_blast.sh", "step3.$i.2.$_\_createcm.sh","step3.$i.3.$_\_cmsearch.sh");
        $i++;
    }

    foreach my $type (@types) {
        foreach(@ncRNA_dir) { (-d "$_/$type/cut") || `mkdir -p $_/$type/cut` }
		my ($sh1,$sh2);
		$sh2 = "rm -f $opt{shdir}/${$sh_name{$type}}[2]\n";
        for my $i (0..$#ass_info) {
            my $sample = ${$ass_info[$i]}[0];
            foreach(@{$split_fa[$i]}) {  
                my $split_base = basename ($_);
                $sh1 .= "$blast  -p blastn -W 7 -e 1 -v 10000 -b 10000 -m8 -d $ncRNA_database/$type/Rfam.fasta.$type -i $_ -o $ncRNA_dir[$i]/$type/cut/$split_base.$type.blast.m8\n";
            }
            $sh2 .= "cd $ncRNA_dir[$i]/$type\n";
            $sh2 .= "cat cut/*.$type.blast.m8 > $sample.$type.blast.m8\n";
            $sh2 .= "$filter_blast_hit $sample.$type.blast.m8 >> $sample.$type.blast.m8.filter\n"; #$filter_blast_hit
#                 the second-pass Rfam searching
            $sh2 .= "$creat_cmfile $sample.$type.blast.m8.filter ${$ass_info[$i]}[1]  $sample\_$type.cmsearch\n";
            $sh2 .= "perl -e 'foreach(glob \"$ncRNA_dir[$i]/$type/$sample\_$type.cmsearch/*/*\") {my \$rfam_id = \$1 if(\$_ =~ /(RF\\d+)\$/);\$rfam_id || next; print \"$cmsearch $Rfam_cm_dir/\$rfam_id.cm \$_ >\$_.cmsearch \\n\";} ' >> $opt{shdir}/${$sh_name{$type}}[2]\n";
        }
        writesh("$opt{shdir}/${$sh_name{$type}}[0]", $sh1);
        writesh("$opt{shdir}/${$sh_name{$type}}[1]", $sh2);
        $locate_run .= "sh ${$sh_name{$type}}[0]\nsh $opt{shdir}/${$sh_name{$type}}[1]";
        $qsub_run .= "$super_worker ${$sh_name{$type}}[0] --resource 1G  --prefix $type\_blast --splits '\\n' \n";
        $qsub_run .= "$super_worker ${$sh_name{$type}}[1] --resource 1G  --prefix $type\_getcm --splits '$splits'\n";

        $locate_run .= "sh ${$sh_name{$type}}[2] &\n";
        $qsub_run .= "$super_worker ${$sh_name{$type}}[2] --resource 1G  --prefix $type\_cmsearch --splitn 10 &\n";
    }
    $locate_run .= "wait\n";
    $qsub_run .= "wait\n";
    ### ncRNA stat for each sample
    if ($opt{ncRNA_stat}) {
        my $sh;
        for my $i (0..$#ass_info) {
            my $sample = ${$ass_info[$i]}[0];
            if (-d "$ncRNA_dir[$i]/rRNA/homology") {    #$opt{outdir}/01.run_component/$l[0]/03.ncRNA-Finding";
                $sh .= "cd $ncRNA_dir[$i]/rRNA/homology\n";
                $sh .= "cat cut/*.blast >$sample.rRNA.blast\n";
                $sh .= "cat cut/*.blast.tab > $sample.rRNA.blast.tab.org\n";
                $sh .= "$homology_rRNA_sim --rRNA $sample.rRNA.blast.tab.org --sequence ${$ass_info[$i]}[1] --out $sample.rRNA.blast.tab\n";
                $sh .= "$tab_to_gff3  $sample.rRNA.blast.tab $sample\n";
            }
            if (-d "$ncRNA_dir[$i]/tRNA") {
                $sh .= "cd $ncRNA_dir[$i]/tRNA\n";
                $sh .= "cat cut/*.tRNA >$sample.tRNA\n";
                $sh .= "cat cut/*.tRNA.structure >$sample.tRNA.structure\n";
                $sh .= "$tRNAscan_to_gff3 --prefix $sample $sample.tRNA $sample.tRNA.structure >$sample.tRNA.gff\n";
            }
            foreach my $type (qw(sRNA miRNA snRNA)) {
                if (-d "$ncRNA_dir[$i]/$type") {
                    $sh .= "cd $ncRNA_dir[$i]/$type\n";
                    $sh .= "$cmsearch_combine $sample\_$type.cmsearch $type . $sample\n";
                    $sh .= "$filter_ncRNA_gff $sample.$type.cmsearch.confident.gff >$sample.$type.cmsearch.confident.nr.gff\n";
                }
            }
            $sh .= "$ncRNA_merge $opt{ncRNA_type} $ncRNA_dir[$i]\n\n";
        }
        writesh("$opt{shdir}/step3.6.ncRNA_stat.sh", $sh);
        $locate_run .= "sh step3.6.ncRNA_stat.sh & \n";
        $qsub_run .= "$super_worker step3.6.ncRNA_stat.sh --resource 1G  --prefix ncRNA_stat  --splits '$splits'  &\n";
    }
    ### write list
    my $ncRNA_list;
    for my $i (0..$#ass_info) {
        $ncRNA_list .= "${$ass_info[$i]}[0]\t$ncRNA_dir[$i]/ncRNA.merge.xls\n";
    }
    writesh("$opt{outdir}/02.stat/ncRNA.list", $ncRNA_list);
}  
# ==============================================================================================================================
## step4: pseudo_gene prediction
if ($opt{step} =~ /4/) {
    $opt{pseudo_ref} && -s $opt{pseudo_ref} || die"Error: --pseudo_ref must be set if run step4 pseudogene.\n";
### read pseudo_ref pep.list
    my %ref_pep;
    for (`less  $opt{pseudo_ref}`) {
        chomp(my @l = split /\s+/, $_);
        (-s $l[2]) || die"Error: Empty or not exist: reference's pep file: $l[2]\n"; 
        push @{$ref_pep{$l[0]}}, [@l[1,2]];
    }
### write shell
    foreach(@pseudo_dir) { (-d "$_") || `mkdir -p $_` }
    my ($sh1, $sh2, $sh4);
	`rm -f $opt{shdir}/step3.pseudo_genewise.*.sh`;
    for my $i (0..$#ass_info) {
        my ($sample, $asseq) = @{$ass_info[$i]};
        ($ref_pep{$sample}) && (@{$ref_pep{$sample}} != 0) || next;
        foreach (@{$ref_pep{$sample}}) {
            my ($ref, $pep) = @{$_};
            (-d "$pseudo_dir[$i]/$ref/{01.blast_solar,02.gene_wise,03.result}") || `mkdir -p $pseudo_dir[$i]/$ref/{01.blast_solar,02.gene_wise,03.result}`;
            $sh1 .= "cd $pseudo_dir[$i]/$ref/01.blast_solar\n";
            $sh1 .= "ln -sf $asseq spe.fa\n";
            $sh1 .= "ln -sf $pep $ref.fa\n";
            $sh1 .= "$formatdb -p F -i spe.fa\n";
            $sh1 .= "$blast -p tblastn -m 8 -F F -e 1e-05 -i $ref.fa -d spe.fa -o spe.m8";
            $sh1 .= ($opt{spe_type} =~ /F/) ? "\n" : " -D 11\n";
            $sh1 .= "$solar -a prot2genome2 -f m8 spe.m8 >spe.m8.solar\n";
            $sh1 .= "$solar_add_realLen spe.m8.solar $ref.fa >spe.m8.solar.cor\n";
            $sh1 .= "$solar_add_identity --solar spe.m8.solar.cor --m8 spe.m8 -best >spe.m8.solar.cor.idadd\n";
            $sh1 .= "awk '\$5>$opt{solar_cut}' spe.m8.solar.cor.idadd >spe.m8.solar.cor.idadd.filter\n";
            $sh1 .= "$get_pos spe.m8.solar.cor.idadd.filter >spe.pos\n";
            $sh1 .= "$extract_seq --pos spe.pos --fasta spe.fa --extent $opt{extent} >spe.nuc\n";
            $sh1 .= "$prepare_pep spe.pos $ref.fa >spe.pep\n";
            $sh1 .= "awk '{print \$1 \"  \"\$3}' spe.pos > spe.strandList\n";
            $sh1 .= "$gwise_file_sh spe.nuc spe.pep spe.strandList $pseudo_dir[$i]/$ref/02.gene_wise/ '$gene_wise' >$opt{shdir}/step4.3.pseudo_genewise.$ref\_$sample.sh\n\n";

            $sh4 .= "cd $pseudo_dir[$i]/$ref/03.result/\n";
            $sh4 .= "$cat_dir '../02.gene_wise/result/*.gw' spe.gw\n";
            $sh4 .= ($opt{spe_type} =~ /F/) ? $gw_parser : $gw_parser_proka;
            $sh4 .= " --gw spe.gw -pep ../01.blast_solar/spe.pep --ac 0 --id 0 --type 1 >spe.gw.alg\n";
            $sh4 .= ($opt{spe_type} =~ /F/) ? $gw_parser : $gw_parser_proka;
            $sh4 .= " --gw spe.gw -pep ../01.blast_solar/spe.pep --ac 0 --id 0 --type 2 >spe.gw.mut\n";
            $sh4 .= "$merge_overlap spe.gw.alg 0.1 >spe.gw.alg.nr\n";
            $sh4 .= "awk '\$9>$opt{genewise_cut}' spe.gw.alg.nr >spe.gw.alg.nr.filter\n";

            $sh4 .= "$cat_file ../02.gene_wise/result/ spe.gw.alg.nr.filter >spe.$ref.gw\n";
            $sh4 .= ($opt{spe_type} =~ /F/) ? $gw_parser : $gw_parser_proka;
            $sh4 .= " --gw spe.gw spe.$ref.gw --pep ../01.blast_solar/spe.pep --ac 0 --id 0 --type 1 >spe.$ref.gw.alg\n";
            $sh4 .= ($opt{spe_type} =~ /F/) ? $gw_parser : $gw_parser_proka;
            $sh4 .= " --gw spe.gw  spe.$ref.gw --pep ../01.blast_solar/spe.pep --ac 0 --id 0 --type 2 >spe.$ref.gw.mut\n";
            $sh4 .= "$gw_to_gff spe.$ref.gw ../01.blast_solar/spe.pep >spe.$ref.gw.gff\n";
            $sh4 .= "$getGene spe.$ref.gw.gff ../01.blast_solar/spe.fa >spe.$ref.gw.cds\n";
            $sh4 .= "$cds2pep_zy spe.$ref.gw.cds spe.$ref.gw.pep";
            $sh4 .= ($opt{spe_type} =~ /F/) ? " 1\n\n" : " 11\n\n";
        }
    }
	$sh2 .= "cat $opt{shdir}/step4.3.pseudo_genewise.*.sh >$opt{shdir}/step4.3.pseudo_genewise.sh;rm $opt{shdir}/step4.3.pseudo_genewise.*.sh\n";
    writesh("$opt{shdir}/step4.1.pseudo_blast_solar.sh", $sh1);
    writesh("$opt{shdir}/step4.2.pseudo_blast_solar_cat.sh", $sh2);
    $locate_run .= "sh step4.1.pseudo_blast_solar.sh\nsh step4.2.pseudo_blast_solar_cat.sh\n";
    $qsub_run .= "$super_worker step4.1.pseudo_blast_solar.sh --resource 1G  --prefix pseu_solar --splits '$splits'\n$super_worker step4.2.pseudo_blast_solar_cat.sh -resource 1G --prefix solar_write --splits '$splits'\n";

    $locate_run .= "sh step4.3.pseudo_genewise.sh\n";
    $qsub_run .= "$super_worker step4.3.pseudo_genewise.sh --resource 1G  --prefix pseu_gwise --splits '\\n' --line 3000\n";

    writesh("$opt{shdir}/step4.4.pseudo_result.sh", $sh4);
    $locate_run .= "sh step4.4.pseudo_result.sh &\n";
    $qsub_run .= "$super_worker step4.4.pseudo_result.sh --resource 1G  --prefix pseu_resul --splits '$splits' &\n";
}

# ==============================================================================================================================
## step5: transposon
if ($opt{step} =~ /5/) {
    foreach(@transposon_dir) { (-d "$_/nuc") || `mkdir -p $_/nuc` }
#### nuc
    if ($opt{transpo_type} =~ /nuc/) {
        my $sh;
        for my $i (0..$#ass_info) {
            my ($sample, $asseq) = (${$ass_info[$i]}[0], ${$ass_info[$i]}[1]); 
            $sh .= "cd $transposon_dir[$i]/nuc\n";
            $sh .= "$transposonPSI $asseq nuc\n";
            $sh .= "$tpsi_stat *bestPerLocus.gff3 $sample >$sample.tpsi.nuc.stat\n\n";
        }
        writesh("$opt{shdir}/step5.1.transposon_nuc.sh", $sh);
        $locate_run .= "sh step5.1.transposon_nuc.sh &\n";
        $qsub_run .= "$super_worker step5.1.transposon_nuc.sh --resource 1G  --prefix transpo_nuc --splits '$splits' &\n";
    }
#### pep
    if ($opt{transpo_type} =~ /pep/) {
        my $pep_file = $opt{pep_list} ? $opt{pep_list} : "$opt{outdir}/02.stat/pep.list";
        my %pep = split /\s+/, `awk '{print \$1, \$2}' $pep_file`;
        my ($sh1,$sh3);
		$sh1 = "rm -f $opt{shdir}/step5.2.2.transposon_pep_run.sh\n";
        for my $i (0..$#ass_info) {
            ($pep{${$ass_info[$i]}[0]}) || next;
            (-d "$transposon_dir[$i]/pep/split") || `mkdir -p $transposon_dir[$i]/pep/split`;
			$sh1 .= "$split_pep $pep{${$ass_info[$i]}[0]} 300 $transposon_dir[$i]/pep/split/ split\nperl -e 'foreach(glob \"$transposon_dir[$i]/pep/split/*.fa\"){print \"cd $transposon_dir[$i]/pep/split; $transposonPSI \$_ prot\\n\"}' >>$opt{shdir}/step5.2.2.transposon_pep_run.sh\n";##get step5.2.2.transposon_pep.sh

            my $sample = ${$ass_info[$i]}[0];
            $sh3 .= "cd $transposon_dir[$i]/pep\n";
            $sh3 .= "cat split/*.TPSI.allHits >$sample.TPSI.allHits\n";
            $sh3 .= "$TPSI_btab_to_gff3 $sample.TPSI.allHits >$sample.tpsi.allHits.gff3\n";
            $sh3 .= "$tpsi_stat $sample.tpsi.allHits.gff3 $sample >$sample.tpsi.pep.stat\n\n";
        }
		$sh1 .= "sleep 60\n";
        writesh("$opt{shdir}/step5.2.1.transposon_pep_pre.sh", $sh1);
        writesh("$opt{shdir}/step5.2.3.transposon_pep_stat.sh", $sh3);
        $locate_run .= "sh step5.2.1.transposon_pep_pre.sh\nsh step5.2.2.transposon_pep_run.sh\nsh step5.2.3.transposon_pep_stat.sh\n";
        $qsub_run .= "$super_worker step5.2.1.transposon_pep_pre.sh --resource 1G  --prefix transpo_pep --splits '$splits'\n$super_worker step5.2.2.transposon_pep_run.sh  --resource 1G --prefix transpo_pep --splits '\\n' --line 1\n$super_worker step5.2.3.transposon_pep_stat.sh --resource 1G --prefix transpo_pep  --splits '$splits'\n";
    }    
}
$locate_run .= "wait\n";
$qsub_run .= "wait\n";
# ==============================================================================================================================
## step6 : stat for all results
if ($opt{step} =~ /6/) {
    my $sh;
    for my $i (0..$#ass_info) {
        my $stat_arg;
        my $sample = ${$ass_info[$i]}[0];
        ($opt{step} =~ /1/) && ($stat_arg .= " --gene $opt{outdir}/01.run_component/$sample/01.Gene_Prediction/$sample*cds");
        ($opt{repbase}) && ($stat_arg .= " --repbase $repeat_dir[$i]/01.repbase/$sample.repbase.out.gff");
        ($opt{trf}) && ($stat_arg .= " --trf $repeat_dir[$i]/02.trf/$sample.trf.dat.gff");
        ($opt{step} =~ /3/) && ($stat_arg .= " --ncRNA $ncRNA_dir[$i]");
        ($opt{ncRNA_type} =~ /rRNAd/) && ($stat_arg .= " --rRNA_denovo $ncRNA_dir[$i]/rRNA/denovo/$sample.rRNAd.gff");
        ($opt{ncRNA_type} =~ /rRNAh/ &&  defined $rRNA_ref{$sample}) && ($stat_arg .= " --rRNA_homology $ncRNA_dir[$i]/rRNA/homology/$sample.rRNA.blast.tab");
        ($opt{ncRNA_type} =~ /tRNA/) && ($stat_arg .= " --tRNA $ncRNA_dir[$i]/tRNA/$sample.tRNA.gff");
        foreach(qw(sRNA miRNA snRNA)) {($opt{ncRNA_type} =~ /$_/) && ($stat_arg .= " --$_ $ncRNA_dir[$i]/$_/$sample.$_.cmsearch.confident.nr.gff");}
        $sh .= "$component_stat $stat_arg --SpeType $opt{spe_type} --prefix $sample ${$ass_info[$i]}[1] &\n";
    }
    $sh .= "wait\n$sample_stat $opt{ass_list} $opt{outdir}/01.run_component $opt{spe_type} $opt{outdir}/02.stat\n";

    writesh("$opt{shdir}/step6.component_stat.sh", $sh);
    $locate_run .= "sh step6.component_stat.sh\n";
    $qsub_run .= "$super_worker step6.component_stat.sh --resource 1G  --prefix compone_stat --splits '$splits'\n";
}

open OUT, ">$opt{shdir}/qsub_Step3.genome_component.sh.sh"|| die"Error:cannot create $opt{shdir}/qsub_Step3.genome_component.sh.sh";
print OUT $qsub_run;
close OUT;

$opt{notrun} && exit;
$opt{locate} ? system "cd $opt{shdir}\n$locate_run" : system"cd $opt{shdir}\n$qsub_run";

# ==============================================================================================================================
# sub function
## used to write shell
sub writesh {
    my ($sh_name, $sh) = @_;
    open SH, ">$sh_name" || die "Error: Cannot create $sh_name.\n";
    print SH $sh;
    close SH;
}
