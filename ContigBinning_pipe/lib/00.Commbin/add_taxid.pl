#!/usr/bin/perl -w 
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use PerlIO::gzip;
# Author; unkmow form MG, Modify by liuwenbin, 2011-12-27
my $usage =<<USAGE;
perl $0 [-options] <file.blast.m8>
    -stdin     use STDIN at infile file.blast.m8
    -tax <str> set the gi_taxid_nucl.dmp file path, gzip file formate is supported.
               [<program path>/database/gi_taxid_nucl.dmp{|.gz}].
    -len <int> set the value for filte short match length[200].
    -out <str> set the ouput file[filtered_add.blast].
    -top <num> output the specified number of besthit for eatch scaffold, default=5
    -help      show this help information.
USAGE

my %opts = (top=>5);
GetOptions(\%opts,"tax:s", "len:i", "output:s", "help","stdin","top:i");
my ($tax, $len, $out, $help) = ($opts{tax}, $opts{len}, $opts{output}, $opts{help});
#$tax ||= "$Bin/database/20101123/gi_taxid_nucl.dmp.gz";
$tax ||= (-e "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp.gz") ? "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp.gz" : "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp";
$len ||= 200;
$out ||= "filtered_add.blast";

((!$opts{stdin} && @ARGV < 1) || $help) && ((print $usage),exit(1));

if(@ARGV==1 && -d $ARGV[0]){
    chomp(@ARGV = `ls $ARGV/*blast.m8`);
}
my (%gi,%uniq);
while(<>){
    chomp;
    my @items = split /\s+/;
    $uniq{$items[0]} && ($uniq{$items[0]} == $opts{top}) && next;
    ($items[1] =~ /gi\|(\d+)\|/) || ((warn "input file format error!\n"),next);
    ($items[3] < $len) && next;
    $uniq{$items[0]}++;
    push @{$gi{$1}},$_;
}
if(!%gi){
    print "Note: can't find able blast m8 alignment, $!\n";
    exit(1);
}

($tax =~ /\.gz$/) ? (open IN2,"<:gzip","$tax" or die $!) : (open IN2,"<$tax" or die $!);
open OUT,">$out" or die $!;
my ($outn,$outl) = (0);
while(<IN2>){
	my @items = split /\t/;
    $gi{$items[0]} || next;
    foreach(@{$gi{$items[0]}}){
	    $outl .= $_ . "\t" .$items[1];
        $outn++;
    }
    delete $gi{$items[0]};
    %gi || last;
    if($outn>=30){
        print OUT $outl;
        $outl = "";
        $outn = 0;
    }
}
close IN2;
foreach my $v(values %gi){
    foreach(@{$v}){
        $outl .= $_ . "\t" . "unknow\n";
        $outn++;
    }
}
$outn && (print OUT $outl);
close OUT;

