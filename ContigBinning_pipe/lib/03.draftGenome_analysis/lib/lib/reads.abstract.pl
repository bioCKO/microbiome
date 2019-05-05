#!/usr/bin/perl
use PerlIO::gzip;

@ARGV >=5 || die"<bin_file_list> <soap1> <soap2> <combine_fq1> <combine_fq2>  must be input! [intersize] is optional(default:350).
Usage:
    <bin file list>  a file of two columns, with formats:
                     sample1   path of sample1 contig file
                     sample2   path of sample2 contig file
                     ...
    <soap1>          soap file(PE or SE)
    <soap2>          soap file(PE or SE)
    <combine_fq1>    soap align result of fq1
    <combine_fq2>    soap align result of fq2
    <inersize>       intersize of PE reads.
\n";

my $bin_file_list = shift;
my @soap_files = (shift,shift);
my $in1 = shift;
my $in2 = shift;
my $insertsize ||= "350";


#if($in1 =~ /gz/){
#  $out1 = (split/gz/,$in1)[0];$out2 = (split/gz/,$in2)[0];
#   $out1 .= "$prefix.gz";$out2 .= "$prefix.gz";
#}else{
#   $out1 = "$in1.$prefix.gz";
#   $out2 = "$in2.$prefix.gz";
#}
#my $outdir = $ARGV[4]||".";


my %ids; 
open IDS, $bin_file_list;
while(<IDS>){
    chomp;
    my ($sampleID,$fa) = split/\s+/,$_;
    for(`less $fa`){
        chomp;
        if($_ =~ />/){my $id = $_; $id =~ s/>//g; $ids{$id} = $sampleID;}
    }
}
close IDS;

#my @contigs = keys %ids;
#foreach(@contigs){
#    print $_."\t".$ids{$_}."\n";
#}

my %filter_id;
foreach(@soap_files){
    get_soap(\%filter_id,$_);
}

open IN1, "<:gzip", $in1 || die $!;
open IN2, "<:gzip", $in2 || die $!;
#open OUT1, ">:gzip", $out1 || die $!;
#open OUT2, ">:gzip", $out2 || die $!;
my (%out1,%out2);
while(my $info1 = <IN1>,my $info2 = <IN2>){
    my $index_r1 = (split /\s+/,$info1)[0];
    $index_r1 =~ s/\/\d$//g; $index_r1 =~ s/^\@//;
    $info1 .= <IN1> . <IN1> . <IN1>;
    $info2 .= <IN2> . <IN2> . <IN2>;
    if(exists $filter_id{$index_r1}){
        my $sampleID =  $filter_id{$index_r1};
        $out1{$sampleID} .= $info1;
        $out2{$sampleID} .= $info2;
        #print OUT1 $info1;
        #print OUT2 $info2;
    }
}close IN1;close IN2;close OUT1;close OUT2;

my @out1_sampleIDs = keys %out1;
foreach(@out1_sampleIDs){
    open O, ">:gzip","$_.L$insertsize\_libname_1.fq.clean.gz"||die $!;
    print O $out1{$_};
    close O;
}
my @out2_sampleIDs = keys %out2;
foreach(@out2_sampleIDs){
    open O, ">:gzip", "$_.L$insertsize\_libname_2.fq.clean.gz"||die $!;
    print O $out2{$_};
    close O;
}

sub get_soap{
    my ($id_h,$soap) = @_;
    ($soap && -s $soap) || return(0);
    ($soap =~ /\.gz$/) ? (open IN,"<:gzip",$soap || die$!) : (open IN,$soap || die $!);
    while (<IN>){
        chomp;
        my ($read_id, $contig_id) = (split/\s+/,$_)[0,7];
        if(exists $ids{$contig_id}){
            $read_id =~ s/\/\d$//g; $read_id =~ s/^\@//;
            $id_h->{$read_id} = $ids{$contig_id};}
    }
    close IN;
}
