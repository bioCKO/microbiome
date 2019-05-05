#!/usr/bin/perl

#===============================================================================

=head1 Name

stat4krst_v1.1.pl

=head1 Description

This program is used to process the meryl xls for kmer analyzed result. Four methods are applied, including gce software (gce), Genomeye software (Ge), perl program using kmer individual number (kn) and kmer species number (ksp) separately

Results files are:
	k*_gce.log          gce result for Genome size and Coverage
k*_gce_H.log        gce result for Genome size, Coverage and Heterozygous rate (a[1/2])
	k*_Genomeye.log     Genomeye result Genome size, Coverage and Heterozygous rate
	k*_knum_stdR.png    R figure for kmer number data and standard Poisson distribution
	k*_knum_poisR.png   R figure for only kmer number data Poisson distribution
	k*_ksp_poisR.png    R figure for only kmer species data Poisson distribution
	k*_result.xls       gce/Genomeye/perl original results summary for one kmer in result directory
	*.survey.xls        restricted results summary for all kmers in outdir directory

=head1 Version

	Author:   Xin Ying,xinying@novogene.cn
	Company:  NOVOGENE                                  
	Version:  1.0                                  
	Created:  08/10/2012 11:11:38 AM
	Updated:  Reading bases.cnt instead of orginal data files

=head1 Usage

	Parameters Options:
	-h|help                      description for this program
	-k|kmer    <int> [required]  set a kmer number
	-l|list    <str> [optional]  set a list containing fasta files to calculate number of bases, default is undefined
	-m|methods <str> [optional]  set a method, default is 4 methods containing "kn,ksp,gce,Ge"
	-n|name    <str> [optional]  set a species name, default is the outdir name
	-c|cvg     <int> [optional]  set a coverage number only used for gce software when the peak is inclined to one side, default is max depth calculated by kn method
	perl kmer_result.pl -k <kmer> <input.xls> <outdir> <result> [-l list] [-m kn,gce] [-n species] [-c 50]

=head1 Example

	perl kmer_result.pl -k 17 k17_merge.xls outdir result

=cut
#===============================================================================

use strict;
use warnings;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;
use Math::CDF qw(ppois);
use FindBin qw($Bin $Script);
use lib "$Bin";
use PGAP qw(parse_config);

my ($help,$kmer,$list,$methods,$name,$cvg);

GetOptions(
		"h|?|help"    =>\$help,
		"k|kmer=i"    =>\$kmer,
		"l|list:s"    =>\$list,
		"m|methods:s" =>\$methods,
		"n|name:s"    =>\$name,
		"c|cvg:i"     =>\$cvg,
	  );

die `pod2text $0` if $help;
die `pod2text $0` unless ($kmer and @ARGV == 3);
print STDERR "Program begin at:\t".`date`."\n";



## input & output files and directories
$methods||= "gce,Ge,kn,ksp";
my $xls   = shift;               #input xls
my $outdir= shift;               #output outdir
$outdir   = abs_path ($outdir);
$name   ||= basename $outdir;
(-s "$Bin/config.txt") || die "Error: not exit $Bin/config.txt.\n";
my ($R_SW, $gce, $Genomeye) = parse_config ("$Bin/config.txt", "$Bin/..", "R", "gce", "Genomeye");

#my $result= "$outdir/result";    #outdir to store results
#`mkdir $result` unless (-d $result);
my $result = shift;
$result = abs_path ($result);

## defined global varialbes and initial values
my $rep_ref =4**$kmer; #used to calculate probability having the same kmer
my $bases   =0;    #number of used bases
my $sum     =0;    #total kmer individuals number
my $sum_ksp =0;    #total kmer species number
my $more_kn =0;    #kmer individuals number >255
my @kn      =qw(); #kmer individuals number (1..>255)
my @ksp     =qw(); #kmer species number (1..>255)
my @kn_out  =qw(); #perl individuals results,[0]method,[1]sum,[2]peak,[3]Gsize,[4]Hr
my $title   ="#####################  $name k$kmer result  #####################\nMethod\tK-mer\tK-mer individual number\tDepth\tGenome size\tRevised genome size\tHeterozygous rate\tRepeat\tProbability having the same kmer\tAccuracy rate";
my $title_RS="#####################  $name k$kmer result  #####################\nMethod\tK-mer\tK-mer individual number\tDepth\tGenome size (M)\tRevised genome size (M)\tHeterozygous rate\tRepeat\tProbability having the same kmer\tAccuracy rate";
my $out_prefix = "$outdir/k$kmer\_$name";
my $result_pref = "$result/k$kmer\_$name";

## caculate used bases
if (defined $list){
	open IN_LST, "<$list" or die $!;
## read list
	while(<IN_LST>){
		chomp;
		$bases += $1 if ($_=~/base=\s+(\d+)/);
	}
	close IN_LST;
	$title .= "\tUsed bases\tX";
	$title_RS .= "\tUsed bases (G)\tX";
}

## output
open OUT,">$out_prefix\_result.xls" or die $!; #output original results to k*_result.xls in result directory
# open OUT_RS, ">>$outdir/Result_summary.xls" or die $!; #output restrict point results to Result_summary.xls in outdir directory
print STDERR `date`, "write to file $result/$name.survey.xls\n";
open OUT_RS, ">$result/$name.survey.xls" or die $!; #output restrict point results to $name.survey.xls in outdir directory
open R,"|$R_SW --vanilla --slave" or die $!; #output figures withi R
print OUT "$title\n";
print OUT_RS "$title_RS\n";

## read input xls
open IN_XLS, "$xls" or die $!;
while (<IN_XLS>){
	chomp;
	my @arr = split(/\s+/,$_);
	my $numb = $arr[0]*$arr[1]; #caculate kmer individuals number
		$sum += $numb;
	$sum_ksp += $arr[1];
	if ($arr[0]<255) {
		push (@kn,$numb);
		push (@ksp,$arr[1]);
	}else{
		$more_kn += $numb;
	}
}
close IN_XLS;
push (@kn,$more_kn);

my $acc_rate=1-$kn[0]/$sum; #accuracy rate (consider kmer_depth=1 is error number)

## perl program for kn
@kn_out  = &est_freq_Hr(1,@kn); #kn_out[5] is max_num
my $rep = &est_repeat ($kn_out[2],@kn);
&output (@kn_out) if ($methods=~/kn/i);

## perl program for ksp
if ($methods=~/ksp/i){
	my @ksp_out = &est_freq_Hr(0,@ksp); #kmer species results
		&output (@ksp_out);
	my $ksp_pois = &plot_R(0,"$result_pref\_ksp_pois",$ksp_out[2],$ksp_out[5],$sum_ksp,@ksp);
	print R $ksp_pois;
}

## estimate max_freq and calculate heterozygous rate
sub est_freq_Hr{
	my ($flag,@in) = @_;
	my ($max_freq,$half_freq,$max_mean,$half_mean,$Hr);
	my $max_num = 0;
## compare to find the max freq
	for my $i(1..@in-2){
		if ($in[$i-1] < $in[$i] && $in[$i] > $in[$i+1]){
			if ($max_num < $in[$i]){
				$max_num = $in[$i];
				$max_freq = $i+1;
			}
		}
	}

	my $Gsize = $sum/$max_freq;

## estimate the average of heterozygous and homozygous peak
	if ($max_freq %2 ==0) {
		$half_freq = $max_freq/2;
		$half_mean = &mean($half_freq,@in);
	}else {
		$half_freq = ($max_freq-1)/2;
		$half_mean = &mean($half_freq,@in);
	}	
	$max_mean = &mean($max_freq,@in); 

## Calculate heterozygous rate
	if ($flag == 1){
		$Hr = $half_mean/$kmer/($half_mean + $max_mean); #kn Hr
			return ("perl_knum",$sum,$max_freq,$Gsize,$Hr,$max_num);
	}else {
		$Hr = $half_mean/$kmer/($half_mean + 2*$max_mean); #ksp Hr
			return ("perl_ksp",$sum,$max_freq,$Gsize,$Hr,$max_num);
	}	
}

## calculate mean of three numbers
sub mean{
	my ($mid,@mean_in) = @_;
	my $avg = ($mean_in[$mid-2]+$mean_in[$mid-1]+$mean_in[$mid])/3;
	return $avg;
}

## calculate repeat using area
sub est_repeat{
	my ($peak,@repeat_in) = @_;
	my $eq = $peak;
	my $cumul_pois = 0;
	for my $i($peak..@repeat_in){
		my $std0 = &ppois($i-1,$peak);
		my $std1 = &ppois($i,$peak);
		my $dif  = $std1 - $std0;
		my $pois = $repeat_in[$i-1]/$sum;
		if ($pois < $dif){
			$eq = $i;
		}else {$cumul_pois += $pois;}
	}
	my $cumul_std = 1- &ppois ($eq,$peak);
	return $cumul_pois - $cumul_std;
}

## gce
if ($methods=~/gce/i){
	my $gce_prefix = "$out_prefix\_gce"; #gce output file prefix
		my $len_xls  = (split/\s+/,`wc -l $xls`)[0];
	my $gce_path = "$gce -f $xls -M $len_xls -g $sum";
	if(!defined $cvg){$cvg=$kn_out[2];}
	`$gce_path -c $cvg -H 1 >$gce_prefix\_H.table 2>$gce_prefix\_H.log`;
	&read_gce("$gce_prefix\_H.log",1);
#my $len_gce_out = @gce_out;
## run again gce if no results when using -H
#	if ($len_gce_out != 5){
	`$gce_path >$gce_prefix.table 2>$gce_prefix.log`;
	&read_gce("$gce_prefix.log",0);
#	}

	sub read_gce{
		my ($gce_log,$H_flag) = @_;
		my @gce_out; #gce results
			open IN_GCE, "<$gce_log" or die $!;
		while (<IN_GCE>){
			if ($_=~/^raw_peak/){
				my $line = <IN_GCE>;
				$gce_out[1] = $sum-(split/\s+/,$line)[2]; #sum kmer number
					$gce_out[2] = (split/\s+/,$line)[4]; #cvg
					$gce_out[3] = (split/\s+/,$line)[5]; #Gsize
					if ($H_flag==1){
						$gce_out[0] = "gce1.0.0_H";
						my $a = (split/\s+/,$line)[6]; #a1/2
							$gce_out[4] = $a/$kmer/(2-$a); #heterozygous rate
					}else {
						$gce_out[0] = "gce1.0.0";
						$gce_out[4] = "N/A";
					}
			}
		}
		close IN_GCE;
		my $len_gce_out = @gce_out;
		&output(@gce_out)if ($len_gce_out == 5);
	}
}

## Genomeye
if ($methods=~/Ge/i){
	my @Ge_out  =qw(); #Genomeye results
		$Ge_out[0]="Genomeye";
	`$Genomeye -k $kmer $xls >$out_prefix\_Genomeye.log`;
	open IN_Ge, "<$out_prefix\_Genomeye.log" or die $!;
	while (<IN_Ge>){
		$Ge_out[1]=$1 if ($_=~/n_kmer:\s+(\S+)/); #sum kmer number 
			$Ge_out[2]=$1 if ($_=~/Coverage\s+:\s+(\S+)/); #coverage 
			$Ge_out[3]=$1 if ($_=~/Genome size1\s+:\s+(\S+)/); #Gsize
			$Ge_out[4]=$1 if ($_=~/heterozygous\s+rate\s+:\s+(\S+)/); #heterozygous rate
	}
	close IN_Ge;
	&output(@Ge_out);
}

## print out
sub output {
	my @out = @_;
	$out[5] = $out[3]*$acc_rate; #revised Gsize
		$out[6] = $out[5]/$rep_ref; #probability having the same kmer
		my $out_str="$out[0]\tk$kmer\t$out[1]\t$out[2]\t$out[3]\t$out[5]\t$out[4]\t$rep\t$out[6]\t$acc_rate";
	if (defined $list){
		my $X = $bases/$out[5];
		$out_str .= "\t$bases\t$X";
	}
	my @out_RS = split (/\s+/,$out_str);
	for my $i(0..@out_RS-1){
		next if ($out_RS[$i]=~/^\D+/); #filter non numeric element
			if ($i==3 && $out_RS[$i]=~/[\.]/){$out_RS[$i]=sprintf("%.2f",$out_RS[$i]);} #[2]peak
				if ($i==4||$i==5) {$out_RS[$i]=sprintf("%.2f",$out_RS[$i]/1000000);}#Gsize,Revised Gsize
#[6]Hr,[7]rep,[8]probability,[9]acc_rate
					if ($i==6||$i==7||$i==8||$i==9) {
						$out_RS[$i]=sprintf("%.2f",$out_RS[$i]*100);
						$out_RS[$i].="%";
					} 
		if ($i==10){$out_RS[$i]=sprintf("%.2f",$out_RS[$i]/1000000000);} #[10]Used bases
			if ($i==11){$out_RS[$i]=sprintf("%.2f",$out_RS[$i]);} #[11]X
	}
	my $out_RS_str = join "\t",@out_RS;
	print OUT "$out_str\n";
	print OUT_RS "$out_RS_str\n";
}

#R plot poisson figure with standard poisson
my $kn_stdR  = &plot_R(1,"$result_pref\_knum_stdR",$kn_out[2],$kn_out[5],$sum,@kn);

#R plot poisson figure without standard poisson
my $kn_pois  = &plot_R(0,"$result_pref\_knum_pois",$kn_out[2],$kn_out[5],$sum,@kn);

sub plot_R{
	my ($flag,$file,$peak,$max_num,$sum_num,@R_in) = @_;
	my $len = @R_in;
	my $num = join ",",@R_in; #y value for R plot 
		my $R_xlim = 4*$peak;     #x max length 
		if ($R_xlim >= 255) {$R_xlim = 254;}
	my $R=<<END;
#pdf(file="$file.pdf")
png("$file.png",type = "cairo")
x=1:$len
y=c($num)
freq<-data.frame(INDEX=x,VALUE=y)
max_x=$R_xlim
max_y=($max_num/$sum_num)*1.1
flag=$flag
if (flag==1){   
max_y=max(dpois($peak,$peak),$max_num/$sum_num)*1.1
plot((0:max_x),dpois(0:max_x,$peak),
type="l",ylim=c(0,max_y),xlim=c(0,max_x),lwd=5,ylab='',xlab='')
legend("topright",lty=1,lwd=5,
legend=c("K-mer Poisson","Standard Poisson"),col=c("red","black"))
par(new=T,ann=T)
}
plot(freq[1:max_x,1],freq[1:max_x,2]/$sum_num,
main="K-mer=$kmer Depth-Frequence Distribution",ylab='Frequence(%)',xlab='Depth',
type='l',ylim=c(0,max_y),xlim=c(0,max_x),lwd=5,col='red',cex.lab=1.2,cex.main=1.5)
if (flag!=1) {legend("topright",lty=1,lwd=5,legend=c("K-mer Poisson"),col=c("red"))}
dev.off()
END
		return $R;
}
print R $kn_stdR;
print R $kn_pois;
close R;
close OUT;
close OUT_RS;

print STDERR "Program finally at:\t".`date`."\n";

__END__
