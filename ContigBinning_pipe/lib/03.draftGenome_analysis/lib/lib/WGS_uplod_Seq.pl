#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use PerlIO::gzip;
my ($Ngapl,$contl,$scafl,$linel,$random,$scaftig) = (10, 200, 200, 60);
my ($organism, $tax_id, $assembly_name, $id_prefix);
GetOptions(
        "Ngapl:i"=>\$Ngapl,
        "scafl:i"=>\$scafl,
        "contl:i"=>\$contl,
        "linel:i"=>\$linel,
        "random"=>\$random,
        "scaftig:s"=>\$scaftig,
        "id_prefix:s"=>\$id_prefix,
        "organism:s"=>\$organism,
        "tax_id:i"=>\$tax_id,
        "assembly_name:s"=>\$assembly_name
);
@ARGV || die"Name: WGS_uplod_Seq.pl
Version: 1.0	date: 2011-7-7
Description: script to deal the barbarism assemble fasta to fit NCBI criterion
Author:
  Wenbin Liu, liuwenbin\@genomics.org.cn
Version: 1.1
Last modify: 2012-04-12 (to fit agp-version 2.0)
Version: 1.2
Last modify: 2013-03-20 (del some bug)
Usage: perl WGS_uplod_Seq.pl <in.fa> [-options] >out.NCBI.fa 2> out.agp
  in.fa <file>       input assembly fasta file, .gz form is allowed
  -Ngapl <num>       Ngap length cutoff, default=10
  -contl <num>       contig within scaffold leng cutoff, default=200
  -scafl <num>       alone contig or scaffold leng cutoff, default=200
  -linel <num>       sequence leng per line, default=60
  -scaftig <file>    outfile scaftig, default not out
  -random            output sequenc in random turn, default natural ordering
  -id_prefix <str>   set new scaffold id prefix and rename scaffold name, default not set
  About AGP head info:
  -organism <str>       species name, default=' '
  -tax_id <num>         TAX_ID, default=' '
  -assembly_name <str>  ASSEMBLY NAME, default=' '
  \n";
#  -contl <num>       contig within scaffold leng cutoff, default=50  ## NOTE!!
my @out;
my $i = 0;
my $nfill = 'N' x $Ngapl;
my %turn;
my $infa = shift;
(-s $infa) || die"error: can't find file $infa, $!";
$scaftig && (open TIG,">$scaftig" || die$!);
($infa=~/\.gz$/) ? (open(IN,"<:gzip",$infa) || die$!) : (open(IN,$infa) || die$!);
my $date = join("-",(split/\s+/,`date`)[2,1,-1]);
$organism ||= " ";
$tax_id ||= " ";
$assembly_name ||= " ";
print STDERR "##agp-version 2.0
# ORGANISM: $organism
# TAX_ID: $tax_id
# ASSEMBLY NAME:  $assembly_name
# ASSEMBLY DATE: $date
# GENOME CENTER: Novogene
# DESCRIPTION: Example AGP specifying the assembly of scaffolds from WGS contigs\n";
$/=">";<IN>;$/="\n";
my $p = 0;
while(<IN>){
	/^(\S+)/ || next;
	my $id = $1;
	$/=">";chomp(my $seq = <IN>);$/="\n";
	$seq =~ s/\s+//g;
	my $len = length($seq);
	($len < $scafl) && next;
	my ($begap,$fgap) = (0, 0);
    my @ATCGN;
    $seq =~ s/^N+//i;
    $seq =~ s/N+$//i;
    if($seq =~ /N/){
        push @ATCGN,($seq=~/([^N]+)(N+)/ig);
        push @ATCGN,($seq=~/N([^N]+)$/i);
    }else{
        push @ATCGN,$seq;
    }
    while(@ATCGN && length($ATCGN[0])<$contl){splice(@ATCGN,0,2);}
    while(@ATCGN && length($ATCGN[-1])<$contl){splice(@ATCGN,-2,2);}
    @ATCGN || next;
    if($id_prefix){
        $p++;
        $id = $id_prefix . $p;
    }
    my ($contig_fa,$agp);
    $seq = "";
    $len = Array_change(\@ATCGN,$contl,$Ngapl,$linel,$scaftig,\$agp,\$contig_fa,\$seq,$id);
	if ($len < $scafl) {
		$p --;
		next;
	}
    if($scaftig && $contig_fa){
        print TIG $contig_fa;
        $contig_fa = "";
    }
    print STDERR $agp;
	$seq =~ s/(.{1,$linel})/$1\n/g;
	push @out,">$id\n$seq";
	$turn{$i}=1;
	$i++;
}
close IN;
$scaftig && close(TIG);
foreach( $random ? (keys %turn) : (0 .. $i-1) ){
	print $out[$_];
	$out[$_]="";
}
sub Array_change{
    my ($atcgn,$contl,$Nlen,$linel,$scaftig,$agp,$contig_fa,$seq,$id) = @_;
    my @old_len;
    my ($n,$j,$not_gap) = ($#$atcgn,0,1);
    foreach (0..$n){
        ($j > $n) && last;
        my $len = length $atcgn->[$j];
        if($not_gap && $len < $contl){
            $atcgn->[$j-1] .= ("N" x $len) . $atcgn->[$j+1];
            splice(@$atcgn,$j,2);
            $len = length $atcgn->[$j-1];
            $old_len[-1] = $len;
            $n -= 2;
            $not_gap = 0;
        }else{
            push @old_len,$len;
            $j++;
        }
        $not_gap = 1 - $not_gap;
    }
    my $is_gap = 0;
    my $scaf_len = 0;
    my ($star,$end,$comp_num,$id_num) = (1,0,1,1);
    foreach my $j(0..$n){
        if($is_gap && $old_len[$j] < $Nlen){
            $old_len[$j] = $Nlen;
            $atcgn->[$j] = "N" x $Nlen;
        }
        $$seq .= $atcgn->[$j];
        $end = $star + $old_len[$j] - 1;
        if($is_gap){
            $$agp .= join("\t",$id,$star,$end,$comp_num,'N',$old_len[$j],"scaffold\tyes\tpaired-ends\n");
        }elsif($old_len[$j] >= $contl){
            $$agp .= join("\t",$id,$star,$end,$comp_num,'W',"$id\_$id_num",1,$old_len[$j],"+\n");
            if($scaftig){
                $atcgn->[$j] =~ s/(.{1,$linel})/$1\n/g;
                $$contig_fa .= ">$id\_$id_num\n".$atcgn->[$j];
            }
            $id_num++;
        }else{
            die"error at: contig len $old_len[$j] < $contl\n$atcgn->[$j]\n";
        }
        $comp_num++;
        $star = $end + 1;
        $scaf_len += $old_len[$j];
        $is_gap = 1 - $is_gap;
        $atcgn->[$j] = "";
    }
    $scaf_len;
}



    

