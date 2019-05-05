#!usr/bin/perl -w
use strict;
use File::Basename;


(@ARGV==2)||die "Usage:perl $0 <dir> <outfile>\n";

my ($dir,$outfile)=@ARGV;
my %tax2psig;
my %tax;
my @psig=`ls $dir/*.qsig.xls`;

foreach my $file (@psig){
    open IN,$file||die$!;
    my $filename=basename($file);
    my $vsname=$1 if ($filename=~/(.*)\.qsig\.xls/);
    <IN>;
    my $flag=0;
    while(<IN>){
      chomp;
      my @tmp=split /\t/;
      $tax{$tmp[0]}=1; 
      if ( 0.01< $tmp[-1] ){
        $tax2psig{$vsname}{$tmp[0]} = "\*";
        $flag=1;
      }else{
        $tax2psig{$vsname}{$tmp[0]} = "\*\*";
        $flag=1;
        }
     }
     $tax2psig{$vsname}{1}=1 if($flag==0);
  }
  close IN;

open OUT,">$outfile";
print OUT "Name\t";
print OUT join ("\t",(keys %tax2psig)),"\n";
foreach my $tax (keys %tax){
    print OUT "$tax\t";
    foreach my $vs (keys %tax2psig){
    if (exists $tax2psig{$vs}{$tax}){
    print OUT "$tax2psig{$vs}{$tax}\t";
     }else{
     print OUT "\-\t";
    }
  }
  print OUT "\n";
}
close OUT;


