#!/usr/bin/perl
use File::Basename;
@ARGV || die"usage: perl $0 <otu_table.p.absolute.mat> [outfile]\n";
my ($file1,$file) = @ARGV;
open IN ,$file1;
$file ||= basename $file1;
open OUT, ">$file";
my $title=<IN>;
$title =~ s/^\S+//;
$title =~ s/\s+Tax_detail$//; #for 1.07.5 
$title =~ s/\s+Taxonomy$//; #for 1.07.5 for cca for otu_table.even.txt
$title =~ s/\s+Description//;#for Meta
print OUT $title;
while(<IN>){
  chomp;
  @line=split /\t+/;
  $taxa=$line[0];
  ($taxa eq "Others") && next;
  if(exists $hash{$line[0]}){
     $line[0]="$line[0]_$hash{$taxa}";
  }
  $hash{$taxa}++; 
pop @line;
  $line=join("\t",@line);
  print OUT $line."\n";
}
close IN;
close OUT;
