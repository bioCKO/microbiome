#!usr/bin/perl -w
use strict;

my ($depth,$len,$covdep,$deptab,$plot)=@ARGV;
my $zeronum;
my %hash;
my %cover;
my %gene_len;
my %single;
if (-s $covdep||$deptab||$plot){
    `rm -rf $covdep $deptab $plot`;
}
open IN,$depth;
while (<IN>){
    chomp;
    my @or=split;
    #push @id, $or[0] if ! $hash{$or[0]};
    $hash{$or[0]}+=$or[2];
    $cover{$or[0]}++ if $or[2] != 0 ;#zhongjian weizhi you 0 shi hou,ji suan coverage jian diao
    $single{$or[2]}++ if $or[2] != 0; #bu tongji zhong jian de  0
}
close IN;
open(LEN,"$len")or die "Can not open $len $!\n.";
while (<LEN>) {
    chomp;
    my @temp = split;
    $gene_len{ $temp[0] } = $temp[1];
}
close LEN;
open DEPTH,">$deptab";
open OUT1,">$covdep";
print DEPTH "Reference_ID\tReference_size(bp)\tCovered_length(bp)\tCoverage(%)\tDepth\tDepth_single\n";
foreach (keys %gene_len){
    if (exists $hash{$_}){
    print DEPTH $_,"\t";
    print DEPTH  $gene_len{$_},"\t";
    print DEPTH $cover{$_},"\t";
    my $percent = sprintf ("%.2f",100*$cover{$_}/$gene_len{$_});
    my $depth=sprintf ("%.1f",$hash{$_}/$cover{$_});
    my $cha=$gene_len{$_}-$cover{$_};
    $zeronum+=$cha;
    print DEPTH "$percent\t$depth\t$hash{$_}\n";
    print OUT1 "$_\:\t$cover{$_}\/$gene_len{$_}\tPercentage\:$percent\tDepth\:$depth\n";
}else{
    print OUT1 "$_\:\t0\/$gene_len{$_}\tPercentage\:0\tDepth\:nan\n";
    print DEPTH "$_\t$gene_len{$_}\t0\t0\t0\t0\n";
    my $cha=$gene_len{$_};
    $zeronum+=$cha;
}
}
close DEPTH;
close OUT1;
 open SI,">$plot";
 print SI 0,"\t",$zeronum,"\n";
 for my $i(1..400){
    if (exists $single{$i}){
        print SI $i,"\t",$single{$i},"\n" ;
     }else{
         print SI $i,"\t",0,"\n";}
 }
 close SI;
