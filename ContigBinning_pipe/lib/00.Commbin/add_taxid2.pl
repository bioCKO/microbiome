#!/usr/bin/perl -w 
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use PerlIO::gzip;
# Author; unkmow form MG, Modify by liuwenbin, 2011-12-27
my $usage =<<USAGE;
perl $0 [-options] <file.blast.m8>
    -stdin          use STDIN at infile file.blast.m8
    -gidTaxid <file>set the gi_taxid_nucl.dmp file path, gzip file formate is supported.
                    [<program path>/database/gi_taxid_nucl.dmp{|.gz}].
    --name <file>   names.dmp.short from NCBI taxonomy, default 20141020 version
    --node <file>   nodes.dmp.short from NCBI taxonomy, default 20141020 version
    -len <int> set the value for filte short match length[200].
    -out <str> set the ouput file, default STDOUT.
    -top <num> output the specified number of besthit for eatch scaffold, default=10
    -help      show this help information.
Reference: http://bergelson.uchicago.edu/Members/mhorton/taxonomydb.build
USAGE

my %opts = (top=>10);
GetOptions(\%opts,"tax:s", "len:i", "out:s", "help","stdin","top:i","name:s","node");
#$tax ||= "$Bin/database/20101123/gi_taxid_nucl.dmp.gz";
my $tax = $opts{gidTaxid} || (-e "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp.gz") ? "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp.gz" : "$Bin/database/taxonomy_taxid_20141020/gi_taxid_nucl.dmp";
my $name = $opts{name} || "$Bin/database/taxonomy_taxid_20141020/names.dmp.short";
my $node = $opts{node} || "$Bin/database/taxonomy_taxid_20141020/nodes.dmp.short";
my $len = $opts{len} || 200;

((!$opts{stdin} && @ARGV < 1) || $opts{help}) && ((print $usage),exit(1));

if(@ARGV==1 && -d $ARGV[0]){
    chomp(@ARGV = `ls $ARGV/*blast.m8`);
}
my (%gi,%uniq,%tax_name,%node);
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
get_hash(\%tax_name,$name);
get_hash(\%node,$node);

($tax =~ /\.gz$/) ? (open IN2,"<:gzip","$tax" or die $!) : (open IN2,"<$tax" or die $!);
if($opts{out}){
    open OUT,">$opts{out}" or die $!;
    select OUT;
}
my ($outn,$outl) = (0);
while(<IN2>){
    chomp;
	my @items = split /\t/;
    $gi{$items[0]} || next;
    my $species = get_species(\%tax_name,\%node,$items[1]);
    foreach(@{$gi{$items[0]}}){
	    $outl .= $_ . "\t" .$items[1] . "\t$species\n";
        $outn++;
    }
    delete $gi{$items[0]};
    %gi || last;
    if($outn>=30){
        print $outl;
        $outl = "";
        $outn = 0;
    }
}
close IN2;
foreach my $v(values %gi){
    foreach(@{$v}){
        $outl .= $_ . "\t" . "unknow\tunknow\n";
        $outn++;
    }
}
$outn && (print $outl);
$opts{out} && close(OUT);
#===============================================
sub get_hash{
    my ($hash,$file) = @_;
    open IN,$file || die$!;
    while(<IN>){
        chomp;
        my @l = split/\t/;
        $hash->{$l[0]} = $l[1];
    }
    close IN;
}
sub get_species{
    my ($tax_name,$node,$tax_id) = @_;
    $tax_name->{$tax_id} && return($tax_name->{$tax_id});
    my @get;
    if($node->{$tax_id}){
        foreach(split/\s+/,$node->{$tax_id}){
            $tax_name->{$_} && (push @get,$tax_name->{$_});
        }
    }
    @get ? join("|",@get) : "unknow genus";
}

