#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
my %opt = (sd=>"0.2,0.3",run=>"qsub",soap_vf=>"1g","bwt_vf"=>"500M",soap_opts=>" -l 32 -s 40 -v 3 -r 1 -p 6",
    cover_opts=>"-p 8",outdir=>".",maxjob=>400,syn_vf=>'1g',repeat_vf=>'0.5g'); #,qopts=>'-P mgtest -q bc.q');
GetOptions(\%opt,"sd:s","run:s","soap_vf:s","bwt_vf:s","soap_opts:s","cover_opts:s","outdir:s","subdir:s",
    "gzip","verbose","maxjob:i","qopts:s","insert:s","workdir:s","sort","clean","multiref","synteny:s",
    "syn_opts:s","lisdir:s","syn_vf:s","repeat_vf:s","cds:s","kmer:s","hasreads","ref_repeat", "onesample");
#==============================================================================================================
foreach("run_soap.pl","2bwt-builder","soap2.21","soap.coverage","super_worker.pl","line_diagram.pl",
    "base.revision","soap2_insert.pl","../synteny/synteny.pl","../Ref_coverage/ref_repeat_analysis.pl",
    "../Ref_coverage/ref_cover.pl"){
    (-s "$Bin/$_") || die"error can't find $_ at $Bin, $!\n";
}
#==============================================================================================================
(@ARGV != 2) && die"Name: Ref_cover.pl
Describe: script to run SOAP2, soap.coverage, synteny.pl for onesample or population
Author: liuwenbin, liuwenbin\@genomic.org.cn
Version: 1.0, Date: 2012-07-20
Usage: perl Ref_cover.pl <reads.lis> <reference>  [-option]
    reads.lis           reads pathway list
    reference           reference fasta, when not end with .index, index lib will build for SOAP2
    --outdir <dir>      output directory, default=./
    --lisdir <dir>      directory to store mega file, default=outdir
    --subdir <str>      to set subdir name at outdir/samp_name, default not set
    --workdir <dir>     shell running directory, defualt=outdir/Shell
    --onesample         only one sample, default population
    --insert <str>      insert lst: name avg_ins, set to caculate -m -x, when PE reads
    --sd <str>          sd to caculate -m -x for small,big lane, default=0.2,0.3
    --qopts <str>       option for qsub, e.g. '-P mgtest -q bc.q', default not set
    --run <srt>         parallel type, qsub, or multi, default=qsub
    --maxjob <num>      maxjob, default=400
    --soap_vf <str>     resource for SOAP, default 'vf=1g'
    --bwt_vf <str>      resource for 2bwt-builder, default vf=500M
    --soap_opts <str>   other soap option, default ' -l 32 -s 40 -v 3 -r 1 -p 6'
    --cover_opts <str>  soap.coverage option, default '-p 8'
    --sort              to sort the soap result
    --synteny <file>    set assembly fasta list to run synteny, form: sample_name fasta_pathway
    --syn_opts <str>    synteny.pl options, default not set
    --syn_vf <str>      resource for qsub synteny, default=1g
    --cds <file>        set reference cds file(list) for gene region coverage stat
    --kmer <str>        set kmer stat table, or kmer analysis Gsize(bp)
    --ref_repeat        run reference repeat analys
    --repeat_vf <str>   resource for qsub ref repeat, default=0.5g
    --verbose           output running information to screen.
    --clean             clean temp file after process
    --gzip              gzip soap result
\nNote:
    1 you had better set --insert, or eatch reads file seen as single reads.
    2 Under set outdir of eatch sample contin: 01.Soapalign/ 02.Coverage/, all process shell at Shell/
    3 The result for SOAP2 and soap.coverage are the same, set by -soap_vf option.
\nExample:
    nohup perl Ref_cover.pl reads.lst ref.lst -kmer kmer.table -synteny ass.fasta.lst  -gzip -insert InsertSize.txt --ref_repeat &\n\n";

#    -multiref           reference is multiref list
###   check error   ===========================================================================================
foreach(@ARGV,$opt{insert}){$_ &&= abs_path($_);}
my ($reads_lst, $index_lib0) = @ARGV;
(-s $reads_lst) || die"error can't fine valid file: $reads_lst, $!\n";
my ($bwt_builder,$run_soap,$super_worker,$run_synteny,$run_repeat,$ref_stat_pl) = (
    "$Bin/2bwt-builder",
    "perl $Bin/run_soap.pl",
    "perl $Bin/super_worker.pl",
    "perl $Bin/../synteny/synteny.pl --locate ",
    "perl $Bin/../Ref_coverage/ref_repeat_analysis.pl",
    "perl $Bin/../Ref_coverage/ref_cover.pl"
);
$opt{qopts} && ($super_worker .= " --qopts=\"$opt{qopts}\"");
$opt{syn_opts} && ($run_synteny .= $opt{syn_opts});
####   bwt index   ===========================================================================================
(-d $opt{outdir}) || mkdir($opt{outdir});
$opt{outdir} = &abs_path($opt{outdir});
my $shdir = ($opt{workdir} || "$opt{outdir}/Shell");
$opt{lisdir} ||= $opt{outdir};
(-d $opt{lisdir}) || mkdir($opt{lisdir});
(-d $shdir) || mkdir($shdir);
my (@index_lib,@ref_name);
get_index(\@index_lib,$index_lib0,\@ref_name);
$opt{multiref} ||= (@index_lib == 1) ? 0 : 1;
my @org_ref = @index_lib;
my $run_bwt;
my $n = 0;
foreach my $index_lib (@index_lib){
    if(!(-s "$index_lib.index") && (-s "$index_lib.index.sai")){
	    $index_lib .= ".index";
    }elsif($index_lib !~ /\.index$/ || !(-s "$index_lib.sai")){
	    my $indir = "$opt{lisdir}/00.Index";
        $opt{multiref} && ($indir .= "/$n");
        (-d $indir) || `mkdir -p $indir`;
	    my $lin_lib = "$indir/" . (split/\//,$index_lib)[-1];
        (-s $lin_lib) || `ln -s $index_lib $indir`;
        $index_lib = $lin_lib;
        if(!(-s "$index_lib.index.sai")){
            $run_bwt .= "cd $indir; $bwt_builder $index_lib\n";
        }
        $index_lib .= ".index";
    }
    $n++;
}
$n--;
#$opt{multiref} || ($n = 0);
if($run_bwt){
    open BSH,">$shdir/bul_bwt.sh" || die$!;
    print  BSH $run_bwt;
    close BSH;
    $run_bwt = "";
    $opt{verbous} && (print STDERR localtime() . " --> building bwt\n");
	system"cd $shdir;$super_worker -resource $opt{bwt_vf} -prefix bwt -sleept 60 bul_bwt.sh";
	$opt{verbous} && (print STDERR localtime() . " --> finish building bwt\n");
}
####   run soap2 and soap.coverage  =============================================================================
my $soap2_opts = " -step 12 -sd $opt{sd} -r mutil -p $opt{maxjob} -v $opt{soap_vf} -w $opt{bwt_vf} -s=\"$opt{soap_opts}\" -cp=\"$opt{cover_opts}\"";
$opt{gzip} && ($soap2_opts .= " -z");
$opt{insert} && (-s $opt{insert}) && ($soap2_opts .= " -l $opt{insert}");
my %inserth;
$opt{insert} && (-s $opt{insert}) && (%inserth = split/\s+/,`awk '{print \$1,\$NF}' $opt{insert}`);
my @dir;
my @sample_name = &get_sample($opt{outdir},$reads_lst,$opt{onesample},\@dir,'reads.lst',$opt{subdir},$opt{hasreads});#sub2
open SH,">$shdir/run_soapcover.sh" || die$!;
foreach(@dir){
    if($opt{multiref}){
        foreach my $i(0..$n){
            my $sdir = "$_/$i.ref";
            (-d $sdir) || mkdir($sdir);
            print SH "cd $sdir; $run_soap ../reads.lst $index_lib[$i] $soap2_opts\n";
        }
    }else{
        print SH "cd $_; $run_soap reads.lst $index_lib[0] $soap2_opts\n";
    }
}
close SH;
$opt{verbous} && (print STDERR localtime() . " --> start running saop2 and soap.coverage\n");
system"cd $shdir;$super_worker --maxjob $opt{maxjob} --resource $opt{soap_vf} --prefix soapcover run_soapcover.sh";
$opt{verbous} && (print STDERR localtime() . " --> finish running saop2 and soap.coverage\n");
my (@max_ref,@max_name);
foreach(@org_ref){s/\.index$//;}
if($opt{multiref}){
    foreach(@dir){
        my @sub_dir;
        foreach my $i(0..$n){push @sub_dir,"$_/$i.ref";}
        my ($sel_ref,$sel_num) = mega_coverage(\@sub_dir,"$_/ref_coverage.table",\@ref_name,'Ref_name',1,"$_/ref_reads_mapped.stat.xls",0,\%inserth);#sub4
        system"mv $_/$sel_num.ref/* $_";
        $opt{clean} && system"rm -r $_/*.ref/";
        push @max_ref,$org_ref[$sel_num];
        push @max_name,$sel_ref;
    }
}
mega_coverage(\@dir,"$opt{lisdir}/all_ref_coverage.stat.xls",\@sample_name,0,0,"$opt{lisdir}/all_ref_reads_mapped.stat.xls",\@max_name,\%inserth);#sub4
#==================================================================================================================
# run repeat for the best reference
my %best_ref;
my @out_repeat;
if($opt{ref_repeat}){
    @max_ref || (@max_ref = @org_ref);
    $max_name[0] ||= ".";
    open SH,">$shdir/refcov_repeat.sh" || die$!;
    foreach(0..$#max_ref){
        $best_ref{$max_name[$_]}++;
        my $rp_dir = "$opt{outdir}/Ref_repeat/$max_name[$_]";
        push @out_repeat,$rp_dir;
        ($best_ref{$max_name[$_]} > 1) && next;
        (-d $rp_dir) || `mkdir -p $rp_dir`;
        print SH "cd $rp_dir ; $run_repeat $max_ref[$_]\n";
    }
    close SH;
    (-s "$shdir/refcov_rp.frec") && `rm $shdir/refcov_rp.frec`;
    open SH,">$shdir/run_refcov_repeat.sh" || die$!;
    print SH "cd $shdir;$super_worker --resource $opt{repeat_vf} --prefix refrp refcov_repeat.sh\ndate > refcov_rp.frec\n";
    close SH;
    $opt{verbous} && (print STDERR localtime() . " --> start running reference repeat\n");
    system"cd $shdir;sh run_refcov_repeat.sh &";
}

#==================================================================================================================
#run synsteny and state reference coverage
$opt{clean} && (-d "$opt{lisdir}/00.Index") && `rm -r $opt{lisdir}/00.Index`;
my (%s_num,%r_num);
foreach (0..$#sample_name){$s_num{$sample_name[$_]} = $_;}
foreach (0..$#ref_name){$r_num{$ref_name[$_]} = $_;}
my (@cds,@kmer);
if($opt{cds} && -s $opt{cds}){
    (`head -1 $opt{cds}`=~/>\S+/) ? (push @cds,$opt{cds}) : chomp(@cds = `awk '{print \$NF}' $opt{cds}`);
}
if($opt{kmer}){
    if(!(-s $opt{kmer})){
        push @kmer,$opt{kmer};
    }else{
        foreach(`less $opt{kmer}`){
            /^Sample_name/ && next;
            my @t = split;
            $kmer[$s_num{$t[0]} || 0] = $t[4] * 10**6;
        }
    }
}
if($opt{synteny} && -s $opt{synteny}){
    my @ass;
    foreach(`less $opt{synteny}`){
        my @t = split/[\s=]+/;
        $s_num{$t[0]} ||= 0;
        $ass[$s_num{$t[0]}] = $t[1];
    }
    my $ass_cover_stat;
    open SH,">$shdir/run_synteny.sh" || die$!;
    foreach my $i(0..$#dir){
        my $sel_ref_name = ($max_name[$i] || 'Reference');
        my $sel_ref_fasta = ($max_ref[$i] || $org_ref[0]);
        if($cds[$r_num{$max_name[$i]}]){
            my $cdsf = $cds[$r_num{$max_name[$i]}];
            $sel_ref_fasta .= " -cds $cdsf";
            my $sdir = "$dir[$i]/04.Refgene_cover";
            (-d $sdir) || mkdir($sdir);
            my $result_dir = "Refcover_result";
            print SH "cd $sdir; $run_soap ../reads.lst $cdsf $soap2_opts\n";
            (-d "$dir[$i]/$result_dir") || `mkdir -p $dir[$i]/$result_dir`;
            $ass_cover_stat .= "cd $dir[$i]; $ref_stat_pl -name $sel_ref_name 02.Coverage/coverage_depth.table ".
                " 03.Synteny/synteny/a-b.cover.stat -cds_depth 04.Refgene_cover/02.Coverage/coverage_depth.table ".
                " -cds_blast 03.Synteny/synteny/a-b.cds.cover.stat " . ($kmer[$i] ? " -K $kmer[$i]" : " ") . 
                " > $result_dir/Ref_coverage.stat.xls\n".
                "cp 02.Coverage/coverage_depth.table $result_dir/Reads_Mapped.cover.xls\n".
                "cp 03.Synteny/synteny/a-b.cover.lst $result_dir/Scaf_aligned.cover.xls\n".
                "cp 04.Refgene_cover/02.Coverage/coverage_depth.table $result_dir/Gene_Reads_Mapped.cover.xls\n".
                "cp 03.Synteny/synteny/a-b.cds.cover.stat $result_dir/Gene_Scaf_aligned.cover.xls\n".
                "cp 03.Synteny/figure/*.png $result_dir/\n";
            $opt{ref_repeat} && 
            ($ass_cover_stat .= "`convert 00.Ref_repeat/repeat.len.pdf $result_dir/Ref_repeat.len.dis.png`\n".
                "cp 00.Ref_repeat/repeat.potion $result_dir/Ref_repeat.potion\n".
                "cp 00.Ref_repeat/repeat.stat $result_dir/Ref_repeat.stat.xls\n");
        }
        print SH "cd $dir[$i]; $run_synteny $sel_ref_fasta $ass[$i] -name $sel_ref_name,$sample_name[$i] -outdir 03.Synteny ;",
             " cp 03.Synteny/filter/$sample_name[$i].len.sort Scaffold_turn\n";
    }
    close SH;
    if($ass_cover_stat){
        open SH,">$shdir/ref_cover_stat.sh" || die$!;
        print SH $ass_cover_stat;
        close SH;
        $ass_cover_stat = "";
    }
    $opt{verbous} && (print STDERR localtime() . " --> start running synteny\n");
    system"cd $shdir;$super_worker --resource $opt{syn_vf} --prefix synteny run_synteny.sh";
    $opt{verbous} && (print STDERR localtime() . " --> finish running synteny\n");
}
#=============================================================================================================================
# to sort the soap result
if($opt{sort}){
    open SH,">$shdir/sortSoap.sh" || die$!;
    open SL,">$opt{lisdir}/ref_sortSoap.lst" || die$!;
    foreach my $i(0..$#dir){
        print SH "cd $dir[$i]/01.Soapalign;less ./* | $Bin/msort -k m8,n9 > $sample_name[$i].soap.sort\n";
        print SL "$sample_name[$i]=$dir[$i]/01.Soapalign/$sample_name[$i].soap.sort\n";
    }
    close SH; close SL;
    $opt{verbous} && (print STDERR localtime() . " --> start to sort soap2 result\n");
    system"cd $shdir;$super_worker --maxjob $opt{maxjob} --resource $opt{soap_vf} --prefix sort sortSoap.sh";
    $opt{verbous} && (print STDERR localtime() . " --> finish running sort soap2 result\n");
}
#=============================================================================================================================
## to check the finish of the reference repeat
if($opt{ref_repeat}){
    `perl -e 'until(-s \"$shdir/refcov_rp.frec\"){sleep(1);}'`;
    foreach(0..$#max_ref){
#        my $cmd = ($best_ref{$max_name[$_]} == 1) ? "mv" : "cp -r";
#        system"$cmd $out_repeat[$_] $dir[$_]/00.Ref_repeat";
#        $best_ref{$max_name[$_]}--;
        system"cp -r $out_repeat[$_] $dir[$_]/00.Ref_repeat";
    }
#    $opt{clean} && (-d "$opt{outdir}/Ref_repeat") && `rm -r $opt{outdir}/Ref_repeat`;
    $opt{verbous} && (print STDERR localtime() . " --> finish running reference repeat\n");
}
if(-s "$shdir/ref_cover_stat.sh"){
    system"sh $shdir/ref_cover_stat.sh";
}
our $err_num = 1;
#=============================================================================================================================
#sub4
sub mega_coverage{
	my ($dir,$stat_tab,$sample_name,$sign,$find_max,$map_file,$ref_name,$inserth) = @_;
	$sign ||= "Sample_name";
	$ref_name && @{$ref_name} && ($sign .= "\tRef_name");
	my @sel;
	my $get_map = 'perl -ne \'if(/^(Total Reads:|Alignment:|Total Pairs:|Paired:|Singled:)\s+(\d+)/){print $2,"\n";}\'';
	my $get_dis = 'perl -ne \'if(/Peak:\s+(\S+)/){print abs($1),"\n";}elsif(/SD:\s+(\S+)/){print $1;exit;}\'';
	my $has_dis = 0;
	my %map_rate;
	open STAT,">$stat_tab" || die$!;
	print STAT "$sign\tRef_len(bp)\tCover_length\tCoverage(%)\tDeapth(X)\n";
	foreach my $i(0..$#$dir){
		my $covst;
		my $samp_name = $sample_name->[$i];
		$ref_name && $ref_name->[$i] && ($samp_name .= "\t$ref_name->[$i]");
		if(-s "$dir->[$i]/02.Coverage/coverage_depth.table"){
			$covst = `tail -1 $dir->[$i]/02.Coverage/coverage_depth.table`;
			$covst =~ s/^\S+/$samp_name/;
		}else{
			$covst = join("\t",$samp_name,0,0,0,0)."\n";
		}
	
		if($find_max){
			my @aa = split/\s+/,$covst;
			push @sel,[@aa[0,-2],$aa[-1]*$aa[-4],$i];
		}
		print STAT $covst;
		($map_file && -d "$dir->[$i]/01.Soapalign/" && `ls $dir->[$i]/01.Soapalign/*.log`) || next;
		foreach(`ls $dir->[$i]/01.Soapalign/*.log`){
			chomp;
			/L(\d+)_(\S+)\.extendedFrags/ || /L(\d+)_([^_]+)\.notCombined/ || /L(\d+)_([^_]+)/ || next;
			my ($lib_len, $lib) = ($1, $2);
			my @a = split/\s+/,`$get_map $_`;
			s/01\.Soapalign/04.Insert/;
			s/log$/PE.soap.insert/;
			if($inserth->{$lib}){
				$lib_len = $inserth->{$lib};
			}
			if(-s $_){
				$has_dis = 1;
				my @dis_len = split/\s+/,`$get_dis $_`;
				$lib_len .= sprintf("\t%d\t%s\t%.2f",@dis_len,100*abs($dis_len[0]-$lib_len)/$lib_len);
			}
			(@a == 2) ?
			(push @{$map_rate{single}},[$samp_name,$lib_len,sprintf("%s\t%s\t%s\t%d\t%d\t%.2f\n",$samp_name,$lib,$lib_len,$a[0],$a[1],100*$a[1]/$a[0])]) : #single soap
			(push @{$map_rate{pair}},[$samp_name,$lib_len,sprintf("%s\t%s\t%s\t%d\t%.2f\t%d\t%.2f\t%d\t%.2f\n",$samp_name,$lib,$lib_len,$a[0],100*($a[1]+$a[2]/2)/$a[0],$a[1],100*$a[1]/$a[0],$a[2],100*$a[2]/$a[0]/2)]); #pair soap
		}
	}
	close STAT;
	`rm $map_file` if (-e $map_file);
	if($map_file && exists $map_rate{single} && @{$map_rate{single}}){
		my $cur_sign = "$sign\tLib_name\tInsertSize(bp)";
		open MP,">$map_file" || die$!;
		print MP "$cur_sign\tTotal_Reads(#)\tTotal_map(#)\tMap_rate(%)\n";
		foreach(sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @{$map_rate{single}}){
			print MP $_->[-1];
		}
		close MP;
	}
	if($map_file && exists $map_rate{pair} && @{$map_rate{pair}}){
		my $cur_sign = "$sign\tLib_name\tInsertSize(bp)";
		$has_dis && ($cur_sign .= "Peak(bp)\tSD\tInsert(%)");
		((-e $map_file && -s $map_file) ? (open MP,">>$map_file") : (open MP,">$map_file")) || die$!;
		print MP "$cur_sign\tTotal_PE(#)\tMap_rate(%)\tMap_PE(#)\tPE_rate(%)\tMap_SE(#)\tSE_rate(%)\n";
		foreach(sort {$a->[0] cmp $b->[0] || $a->[1] <=> $b->[1]} @{$map_rate{pair}}){
			print MP $_->[-1];
		}
		close MP;
	}
	if($find_max){
		@sel = sort {$b->[1] <=> $a->[1] || $b->[2] <=> $a->[2]} @sel;
		return(@{$sel[0]}[0,3]);
	}
}

## ================================================================================================================
#sub1
sub abs_path{chomp(my $tem=`pwd`);($_[0]=~/^\//) ? $_[0] : "$tem/$_[0]";}
#sub2
#==============
sub get_sample{
#==============
    my ($outdir,$readl,$onesample,$dir,$fname,$subdir,$hasreads) = @_;
    open IN,$readl;
    my (%readh,%dirh);
    if($onesample){
       $dirh{all} = $outdir;
    }
    while(<IN>){
        if($onesample){
            $readh{all} .= $_;
        }else{
            my $temdir;
            if(/(\S+)[\s=]+(\S+\n)/){
                ($temdir,$_) = ($1, $2);
            }else{
                $temdir = (split/\//)[-2];
            }
            $readh{$temdir} .= $_;
            $dirh{$temdir} = $outdir . '/' . $temdir;
            $subdir && ($dirh{$temdir} .= "/$subdir");
        }
    }
    close IN;
    my @sample_name;
    foreach my $d(keys %readh){
        (-d $dirh{$d}) || `mkdir -p $dirh{$d}`;
        if(!($hasreads || -s "$dirh{$d}/$fname")){
            if($readh{$d} =~ /\.list$|\.lst$/){
                chomp($readh{$d});
                `cp $readh{$d} $dirh{$d}/$fname`;
            }else{
                open RE,">$dirh{$d}/$fname" || die"$!\n";
                print RE $readh{$d};
                close RE;
            }
        }
        push @$dir,$dirh{$d};
        push @sample_name,$d;
    }
    @sample_name;
}
#sub3
sub get_index{
    my ($ind_arr,$ref,$ref_name) = @_;
    my $sref = $ref;
    $sref =~ s/\.index$//;
    if((-s $ref && `head -1 $ref`=~/>\S+/) || (-s $sref && `head -1 $sref`=~/>\S+/)){
        push @{$ind_arr},$ref;
    }else{
        foreach(`less $ref`){
            /\S/ || next;
            my @l = split/[\s=]+/;
            if(@l==1){
                $l[1] = (split/\//,$l[0])[-1];
                $l[1] =~ s/\.index$//;
                $l[1] =~ s/\.fa$|\.fna$|\.fasta$//;
                @l = @l[1,0];
            }
            push @{$ind_arr},$l[1];
            push @{$ref_name},$l[0];
        }
    }
}
