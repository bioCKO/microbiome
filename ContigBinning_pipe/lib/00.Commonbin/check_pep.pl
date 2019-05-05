#!/usr/bin/perl -w
=head1 
Usage
    perl  check_pep.pl  --outdir  Absolute_path/03.Genome_Component/  --ass_list  Absolute_path/02.Assembly/02.stat/reach_stand.list

     --outdir*              */output/03.Genome_Component/
     --ass_list*            sample1  /TJPROJ1/MICRO/lihongyue/Project/sample1.seq

=cut

use strict;
use Getopt::Long;
my ($Outdir, $ass_list);
GetOptions("outdir:s"=>\$Outdir,"ass_list:s"=>\$ass_list);
($Outdir  &&  $ass_list) || (warn "--outdir --ass_list must be set\n\n" && die `pod2text $0`);
my %hash;
%hash=split /\s+/,(`less  $ass_list`);
my @samples= keys %hash;
my $num_sample=@samples;
while(1){
    my $i=0;
    sleep (300);
    foreach my $sample (keys %hash){
          (-s "$Outdir/01.run_component/$sample/01.Gene_Prediction/$sample.gmhmmp.pep" || -s "$Outdir/01.run_component/$sample/01.Gene_Prediction/$sample.pep") &&  $i++;
    }
    $i==$num_sample &&  exit;
}

