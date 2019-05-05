#!/usr/bin/perl -w
use strict;
@ARGV || die"usage: perl $0 <report1_dir> <report1_dir> ... <outdir> > run_metastat.sh\n";
my $outdir = pop;
(-d $outdir) || mkdir($outdir);
for(@ARGV){
    my $dir = "$outdir/$_";
    (-d $dir) || mkdir($dir);
    system " perl /PROJ/MICRO/share/16S_pipeline/16S_pipeline_V1.08/lib/00.Commbin/metastat/Metastat.pl $_/03.Make_OTU/otu97/Evenabs $_/03.Make_OTU/group $dir\n ";
}
