#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use List::Util qw(max min);
my($mf,$indir,$result);
my %opt;
GetOptions(\%opt,"host","lefse","mf:s","indir:s","outdir:s");
$mf=$opt{mf};
$indir=$opt{indir};
$result=$opt{outdir};
($indir && -s $indir && $mf && -s $mf)||die"perl $0 --mf <all.mf> --indir <work_dir> --outdir <result> [--host] [--lefse]";
$result ||= "Result";
#(-d $result) && `rm -r $result`;
(-d $result) || mkdir($result);
($indir && -s $indir)||die "no work dir";
$indir=abs_path($indir);
$result=abs_path($result);
my @level=qw(phylum class order family genus species);
my @dir=qw(01.Rawdata 02.MetaPhlAn 03.Diversity);
for(@dir){
	 $_ = "$result/$_";
}
#get sample name and check the sample number of each group
my (%hash,@name,$count,@c);
open IN,"$mf";
while(<IN>){
	next if(/^#/);
	chomp;
	my @tmp=split /\t/,$_;
	push @name,$tmp[0];
	push @{$hash{$tmp[1]}},$tmp[0];
}
foreach(keys %hash){
	$count=@{$hash{$_}};
	push @c,$count;
}
my $mg=max(@c);
#================get 01.cleandata====================#
my ($md5list,%name_insize);
if (-s "$indir/01.DataClean/"){
  if(-s "$indir/01.DataClean/Dataclean.total.list"){
	(-d $dir[0]) && `rm $dir[0]`;
	(-d $dir[0])||`mkdir $dir[0]`;
	for(`less $indir/01.DataClean/Dataclean.total.list`){
		chomp;
		my $name= (split /\t/)[0];
		my @fq=(split /\//)[1];
		(-d $dir[0]/$name)||mkdir -p "$dir[0]/$name";
		$fq[0]=~/\/($name\_\d+)/;
		$name_insize{$name}=$1;
		if($fq[0]=~/nohost/){
			system "ln -s $fq[0] $dir[0]/$name/$name_insize{$name}\.nohost.fq1.gz" || die "$!";
			system "ln -s $fq[1] $dir[0]/$name/$name_insize{$name}\.nohost.fq2.gz" || die "$!";
			system "ln -s $indir/01.DataClean/SystemClean/$name/{*.fq1.gz,*.fq2.gz} $dir[0]/$name" || die "$!";
			system "ls $result/01.CleanData/$_/$name_insize{$_}\.nohost\.{fq1.gz,fq2.gz} >> $md5list";
			system "ls $result/01.CleanData/$_/$name_insize{$_}\.{fq1.gz,fq2.gz} >> $md5list";
		}else{
			system "ln -s $indir/01.DataClean/SystemClean/$name/{*.fq1.gz,*.fq2.gz} $dir[0]/$name" || die "$!";
			system "ls $result/01.CleanData/$_/$name_insize{$_}\.{fq1.gz,fq2.gz} >> $md5list";
		}
	}
	cp_datalist("$indir/01.DataClean/png.list","$dir[0]");
	system "ln -s $indir/01.DataClean/{novototal.QCstat.info.xls,total.QCstat.info.xls} $dir[0]";
	$opt{host} && system "ln -s $indir/01.DataClean/*.NonHostQCstat.info.xls $dir[0]";
	(-s "$indir/01.DataClean/QC_raw_report") || warn "$indir/01.DataClean/QC_raw_report does not exist!\n";
	system "cp -r $indir/01.DataClean/QC_raw_report/ $dir[0]/QC_raw_report ";
	system "rm $dir[0]/QC_raw_report/novo.html";
	}else{
		warn "[Warnning]The file '01.DataClean/Dataclean.total.list' does not exist!\n";
  }
}

#================get 02.MetaPhlAn====================#
if(-s "$indir/02.MetaPhlAn"){
		for (@name){
		(-d "$dir[1]/$_")||`mkdir -p $dir[1]/$_/`;
		system "cp $indir/02.MetaPhlAn/01.bowtie/$_.bt2out $dir[1]/$_/";
		system "cp $indir/02.MetaPhlAn/02.profiled_samples/$_.txt $dir[1]/$_/";
		system "cp -r $indir/02.MetaPhlAn/03.Stat/Relative/ $dir[1]/";
		system "cp $indir/02.MetaPhlAn/03.Stat/merged_abundance_table.txt $dir[1]/";
		system "cp $indir/02.MetaPhlAn/03.Stat/abundance_heatmap.png $dir[1]/";
		}
}else{
	warn "$indir/02.MetaPhlAn does not exist!\n";
}
#================get 03.Diversity====================#
if(-s "$indir/03.Diversity"){
	(-d "$indir/03.Diversity/01.barplot/") && `mkdir -p $dir[2]/barplot`;
	system "cp $indir/03.Diversity/01.barplot/*.relative.xls $dir[2]/barplot";
	system "cp $indir/03.Diversity/01.barplot/*.png $dir[2]/barplot";
	system "cp $indir/03.Diversity/01.barplot/*.svg $dir[2]/barplot";
	(-d "$indir/03.Diversity/02.heatmap/") && `mkdir -p $dir[2]/heatmap`;
	system "cp $indir/03.Diversity/02.heatmap/*.txt $dir[2]/heatmap";
	system "cp $indir/03.Diversity/02.heatmap/*.png $dir[2]/heatmap";
	system "cp $indir/03.Diversity/02.heatmap/*.pdf $dir[2]/heatmap";
	(-d "$indir/03.Diversity/03.Graphlan/") && `mkdir -p $dir[2]/Graphlan`;
	system "cp $indir/03.Diversity/03.Graphlan/*.pdf $dir[2]/Graphlan/";
	system "cp $indir/03.Diversity/03.Graphlan/*.png $dir[2]/Graphlan/";
	system "cp $indir/03.Diversity/03.Graphlan/*.svg $dir[2]/Graphlan/";
	(-d "$indir/03.Diversity/04.Krona/") && `mkdir -p $dir[2]/Krona`;
	system "cp $indir/03.Diversity/04.Krona/*.txt $dir[2]/Krona";
	system "cp -r $indir/03.Diversity/04.Krona/{img,src,taxonomy.krona.html} $dir[2]/Krona";
	if($opt{lefse}){
		(-d "$indir/03.Diversity/05.LEfSe/") ||warn "we should get the lefse analysis but something is wrong\n";
		for my $d(`ls $indir/03.Diversity/05.LEfSe/`){
			chomp $d;
			(-d  "$dir[2]/LEfSe/$d") || `mkdir -p $dir[2]/LEfSe/$d`;
				for my $temp(`ls $indir/03.Diversity/05.LEfSe/$d/{*.png,*.pdf,*.res}`){
					chomp $temp;
					system "cp $temp $dir[2]/LEfSe/$d";
				}
		}
	}else{
		warn "No lefse analysis\n";
	}
	if($mg >=3 && (-d "$indir/03.Diversity/06.t.wilcox/")){
		for my $level (@level){
			(-d "$dir[2]/06.t.wilcox/$level")||`mkdir -p $dir[2]/t.wilcox/$level`;
			for my $temp(`ls $indir/03.Diversity/06.t.wilcox/$level/{*.png,*.svg,*.qsig.xls,*.test.xls,*.psig.xls}`){
					chomp $temp;
					system "cp $temp $dir[2]/t.wilcox/$level";	
			}
		}
	}else{
		warn "No t.wilcox test or see the error.log in $indir/03.Diversity/06.t.wilcox/\n";
	}
}
