#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $usage=<<"USAGE";

	Script   : draw distribution of base and quality along reads from .fqcheck file
	Usage    : perl $0 <read1_fqcheck_file> [read2_fqcheck_file] -id <str> -o <out_file_prefix>
	Exmple   : perl $0 ./s_1_1.fqcheck ./s_1_2.fqcheck -o ./s_1

USAGE
my ($out, $ID);
GetOptions("o=s"=>\$out, "id=s"=>\$ID);
die $usage unless ($out && $ARGV[0]);
my @fqcheck_files = @ARGV;
$ID ||= "";
my $ID_o = $ID ? "($ID)" : "";
#my $gnuplot = find_gnuplot ();
my $rscript = find_rscript ();

my @last_cycle = (0);
#open OUT1, ">$out.base";
#open OUT2, ">$out.qual";
open GC,">","$out.GC";
open QD,">","$out.QD";
open QM,">","$out.QM";
my %quality;
for (my $i=0; $i<@fqcheck_files; $i++) {
	open IN, "<$fqcheck_files[$i]" or die "Error: cannot open $fqcheck_files[$i]";
	$last_cycle[$i+1]=$last_cycle[$i];
	while (my $line = <IN>) {
		next unless ($line =~ /^base/);
		my @value = split /\s+/, $line;
		$value[1] += $last_cycle[$i];
		$last_cycle[$i+1] = $value[1] if ($value[1]>$last_cycle[$i+1]);
		print GC join("\t",$value[1],'A',$value[3],'T',$value[6],'G',$value[5],'C',$value[4],'N',$value[7]),"\n";
		my $tot_qual = 0;
		my $csum = 0;
		for (my $i=8; $i<@value; $i++) {
			my $cqual = $i-8;
			$quality{$cqual} += $value[$i];
			$csum += $value[$i];
			$tot_qual += $value[$i]*$cqual;
		}
		my $avg_qual = $tot_qual/$csum;
		my $erate = 10 ** (-$avg_qual/10);
		$erate = $erate*100; # fix for %
		print QM "$value[1]\t$avg_qual\t$erate\n";
	}
	close IN;
}
foreach my $qual (sort {$a<=>$b} keys %quality) {
	print QD "$qual\t$quality{$qual}\n";
}
close GC;
close QM;
close QD;

# Rscript
## gc plot
my $rs_str = <<RGC;
#!$rscript
gc<-read.table(\"$out.GC\")
gcx<-gc[,1]
gcy<-gc[,3]
png(\"$out.GC.png\",type=\"cairo\")
plot(gcx,gcy,xlim=c(0,$last_cycle[-1]),ylim=c(0,50),col=\"red\",type=\"l\",xlab=\"Position along reads\",ylab=\"percent\",main=\"Base percentage composition$ID_o\",lty=1,lwd=1.5)
gcp<-gc[,5]
gcq<-gc[,7]
gcs<-gc[,9]
gcm<-gc[,11]
lines(gcx,gcp,col=\"magenta\",type=\"l\",lty=2,lwd=1.5)
lines(gcx,gcq,col=\"darkblue\",type=\"l\",lty=4,lwd=1.5)
lines(gcx,gcs,col=\"green\",type=\"l\",lty=5,lwd=1.5)
lines(gcx,gcm,col=\"cyan3\",type=\"l\",lty=6,lwd=1.5)
legend(\"topright\",legend=c(\"A\",\"T\",\"G\",\"C\",\"N\"),col=c(\"red\",\"magenta\",\"darkblue\",\"green\",\"cyan3\"),lty=c(1,2,4,5,6))
RGC
for (my $i=1; $i<@last_cycle-1; $i++) {
	$rs_str .= "abline(v=$last_cycle[$i],col=\"darkblue\",lty=2)\n";
}
$rs_str.="dev.off()\n\n";

## qd plot
$rs_str.=<<RQD;
qd<-read.table(\"$out.QD\")
qdx<-qd[,1]
qdy<-qd[,2]
png(\"$out.QD.png\",type=\"cairo\");
plot(qdx,qdy,col=\"red\",type=\"l\",xlab=\"Quality score\",ylab=\"Number of bases\",main=\"$ID\")
axis(side=1,at=seq(from=0,to=max(qdx),by=5))
dev.off()

RQD

## err and QM
### QM
$rs_str.=<<RQM;
qm<-read.table(\"$out.QM\")
qmx<-qm[,1]
qmy<-qm[,2]
qmz<-qm[,3]
png(\"$out.QM.png\",type=\"cairo\")
plot(qmx,qmy,xaxt=\"n\",xlim=c(0,$last_cycle[-1]),ylim=c(0,40),col=\"red\",type=\"p\",pch=\".\",cex=1.5,xlab=\"Position along reads\",ylab=\"Quality\",main=\"$ID\")
axis(side=1,at=seq(from=0,to=$last_cycle[-1],by=50))
abline(h=20,col=\"darkblue\",lty=3)
RQM
for (my $i=20;$i<$last_cycle[-1];$i+=20) {
	$rs_str.="abline(v=$i,col=\"darkblue\",lty=3)\n";
}
### err
$rs_str.=<<ERR;
png(\"$out.Error.png\",type=\"cairo\")
plot(qmx,qmz,xaxt=\"n\",xlim=c(0,$last_cycle[-1]),col=\"red\",type=\"h\",xlab=\"Position along reads\",ylab=\"\%Error-Rate\",main=\"Error rate distribution$ID_o\",lty=1,lwd=1.5)
axis(side=1,at=seq(from=0,to=$last_cycle[-1],by=50))
ERR
for (my $i=20;$i<$last_cycle[-1];$i+=20) {
	$rs_str.="abline(v=$i,col=\"darkblue\",lty=3)\n";
}
$rs_str.="dev.off()\n\n";

open RS,">","$out.R" or die $!;
print RS $rs_str;
close RS;

# run rscript
`chmod 755 $out.R && $rscript $out.R`;

exit 0;

sub find_rscript {
	my $rscript = 'System/R-2.15.3/bin/Rscript';
	$rscript = "env Rscript" unless (-e $rscript);
	return $rscript;
}

__END__
