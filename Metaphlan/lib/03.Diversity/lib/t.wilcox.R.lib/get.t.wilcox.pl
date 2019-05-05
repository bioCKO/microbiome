#!/usr/bin/perl 
use strict;
use Getopt::Long;
use Cwd qw(abs_path getcwd);
use FindBin qw($Bin);
my %opt=("min_mean"=>0.001, "threshold"=>0.95, "method"=>"t","outdir"=>"./");
GetOptions(\%opt,"Vslist:s", "method:s","threshold:f", "infilepath:s", "group:s", "outdir:s" ,"min_mean:f");
($opt{infilepath} && $opt{group}) || die "usage:perl $0 
-threshold[float]	 	confident interval for t.test , wilcox test has no confident interval, defalut 0.95
--infilepath<dir>   	eg:05.Stat_test/t.test_bar_plot/Relative
--group<dir>  			group file: sample group
--outdir<dir>	    	defalt ./
--Vslist<file>  		set groups to do analyze,format: group1 group2
--method<string> 		t or wilcox
--tworksh<dir> 		set t test's work.sh's directory 
--min_mean  			if the mean of some group < min_mean, it will not be drawed in the picture.defualt:0.001
--qopts					set super_work qsub options
\n";

my $super_worker = "perl /PUBLIC/software/MICRO/share/16S_pipeline/16S_pipeline_V3.2/lib/00.Commbin/super_worker.pl" ;
$opt{qopts} && ($super_worker .= " --qopts='$opt{qopts}'");
#my $dir = getcwd;
#$opt{outdir} ||= $dir;
$opt{tworksh} ||= "$opt{outdir}/twork.sh";
my @file_input = qw(class family genus  order  phylum  species);
for( qw(infilepath group outdir  tworksh)){
	$opt{$_}= abs_path($opt{$_});
}
open SH,">$opt{tworksh}" || die $!;
if($opt{Vslist}){
    $opt{Vslist} = abs_path($opt{Vslist});
    print SH "/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[0]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[1]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[2]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[3]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[4]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[5]  --group $opt{group} --outdir  $opt{outdir}  --Vslist $opt{Vslist} --method $opt{method} \& wait\n";
}else{
    print SH "/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[0]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[1]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[2]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[3]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[4]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\&
/PUBLIC/software/public/System/R-2.15.3/bin/Rscript $Bin/ttest.main.R  --threshold $opt{threshold} --infilepath  $opt{infilepath}/$file_input[5]  --group $opt{group} --outdir  $opt{outdir} --method $opt{method}\& wait\n";
}
close SH;
#my $splits = '\n\n';
#system("$super_worker --splits $splits $opt{outdir}/twork.sh");
system("cd $opt{outdir}
        sh twork.sh");
if($opt{method} eq "t"){
	my @levels = qw(class family genus  order  phylum  species);
	for my $level(@levels){
		my $temp_outdir = "$opt{outdir}/$level";
		chomp( my @files = (split/\s+/,`ls $temp_outdir/*.psig.xls`));
		for my $filename(@files){
		 	my $file_line =(split/\s+/,`wc -l $filename`)[0];
		 	if( $file_line >1 ){
            	system("perl $Bin/draw.interval.pl $filename --min_mean $opt{min_mean} --outfile $filename.svg 2> error.log");
            	(-s "$filename.svg") && system("/usr/bin/convert  -density 300 $filename.svg  $filename.png");
         	}
		}
	}
}


__END__
#print SH "/PUBLIC/software/public/System/R-2.15.3/bin/Rscript ttest.main.R  --threshold 0.05 --infilepath  /TJPROJ1/MICRO/hanyuqiao/16s/NH150270_73_16sv34_20150504/109/03.Make_OTU/otu97/Relative  --group group.list --outdir  /TJPROJ1/MICRO/hanyuqiao/16s/test/t.test/output  --Vslist vs.list --method wilcox"
