#! /usr/bin/perl -w
use strict;
my ($outdir)=@ARGV;
my @allpdf=`ls $outdir/boxplot/figures/*.pdf`;
open OUF,">$outdir/boxplot/figures/readpdf.txt"|| die $!;
 open OUG,">$outdir/boxplot/figures/readpng.txt"|| die $!;
for (my $i = 0; $i < $#allpdf+1; $i++) {
 chomp $allpdf[$i];
 my $mingzi=$1 if($allpdf[$i]=~/.*\/(.*)\.pdf$/);
 my $namepdf="$mingzi.pdf";
 my $namepng="$mingzi.png";
 my $j=$i+1;
 my $titlepdf="$j.pdf";
my $titlepng="$j.png";
 my $cutid;
  my $lenth=length($mingzi);
     if ($lenth>60){
        $cutid=substr($mingzi,0,60). "(\.\.\.)";
     }else{$cutid=$mingzi}
 print OUF "$titlepdf\t$namepdf\t$cutid\n";
 print OUG "$titlepng\t$namepng\t$cutid\n";
 $namepdf =~ s/(&|\(|\))/\\$1/g;
 $namepng =~ s/(&|\(|\))/\\$1/g;
 `mv $outdir/boxplot/figures/$namepdf $outdir/boxplot/figures/$titlepdf`;
 `mv $outdir/boxplot/figures/$namepng $outdir/boxplot/figures/$titlepng`;
 }
 close OUF;
 close OUG;

