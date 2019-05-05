#!/usr/bin/perl -w
use File::Basename;
use Getopt::Long;
use strict;
use FindBin qw($Bin);
use lib "$Bin/../../../00.Commbin";
use PATHWAY;
my $lib = "$Bin/../../../../lib";
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin/, $!\n";
my ($samtools) = get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(SAM)],$Bin,$lib);

my ( $len_file, $soaplist, $out_file, $help,$pe_file,$se_file,$sam_file );
GetOptions(
	"h!"     => \$help,
	"len=s"  => \$len_file,
	"soap=s" => \$soaplist,
	"out=s"  => \$out_file,
	"pe=s"   => \$pe_file,
	"se=s"   => \$se_file,
    "sam=s"  => \$sam_file, 
);

if ( !($len_file && ($soaplist || $pe_file || $se_file || $sam_file)) ) {
	&usage();
}

my %gene_len;
my %gene;
if ( -s $len_file ) {
	&readlen( $len_file, \%gene_len, \%gene );
}
else {
	print "eeee...Can not use files $len_file, Please check again!";
	exit;
}

if ( $soaplist && -s $soaplist ) {
	&readsoap( $soaplist, \%gene );
}elsif($pe_file && -s $pe_file && $se_file && -s $se_file){
	&readsoap_pe_se($pe_file,$se_file,\%gene);
}elsif($pe_file && -s $pe_file){
	&readsoap_pe_se($pe_file,'',\%gene);
}elsif($se_file && -s $se_file){
	&readsoap_pe_se('',$se_file,\%gene);
}elsif($sam_file && -s $sam_file){
    &readsam($sam_file,\%gene,$samtools);
}else {
	print "eeee...Can not use files soaplist or pe & se or sam, Please check again!";
	exit;
}


my %tempcount;
my $tempsum=0;
my %RA;
foreach my $key ( keys %gene_len ) {
	if ( exists $gene{$key} ) {
		$tempcount{$key} = $gene{$key} / $gene_len{$key};
		$tempsum = $tempsum+$tempcount{$key};
	}
}
open OUT, ">" . $out_file or die "can not open $out_file $!\n.";
print OUT "Gene_ID\tGene_Reads\n";
#print OUT "Gene_ID\tGene_Reads\tRelative_Abundance\n";
foreach my $key (sort {$gene{$b} <=> $gene{$a}} keys %gene ) {
	print OUT $key . "\t"
	  . $gene{$key} . "\n";
	 # . $tempcount{$key} / $tempsum . "\n";
}
close OUT;

sub usage() {
	print "Usage1:perl $0 -len <len.info> -soap <soap.lst> -out <out_file>
	Usage2:perl $0 -len <len.info> -pe <soap.PE> -se <soap.SE> -out <out_file>
	-len	[str] Gene lenth info file
	-soap	[str] Soap result list file 
	--pe    [str] Soap result file PE
	--se    [str] Soap result file SE
	-out	[str] Output file
    --sam   [str] bowtie result file 
	-h	print help info.
	Contacter: wangxiaohong\@novogene.cn
	Discription: This script is used to caculate the relative abundance for Metagenomics gene.
	Version: 0.1	Date:2014-1-16
	Version: 0.11	Date:2014-5-24
	Version: 0.2    Date:2015-04-20, update --pe --se
    Version: 0.3    Date:2017-09-28, update --sam\n";
	exit;
}

sub readlen() {
	my ( $len_file, $gene_len, $gene ) = @_;
	open IN, $len_file or die "Can not open $len_file $!\n.";
	while (<IN>) {
		chomp;
		my @temp = split;
		$gene_len->{ $temp[0] } = $temp[1];
		$gene->{ $temp[0] }     = 0;
	}
	close IN;
}

sub readsoap() {
	my ( $soaplist, $gene ) = @_;
	if ( -s $soaplist ) {
		open SL, $soaplist or die "Can not open $soaplist $!\n.";
		while (<SL>) {
			chomp;
			my @temp       = split(/\s/);
			my $insertsize = $temp[0];
			my $sf         = pop @temp;
			if ( $sf =~ /PE/g ) {
				print $sf."\n";
				if ( $sf =~ /.gz$/ ) {
					open PE, "gzip -dc $sf |"
					  or die "Can not open $sf $!\n.";
				}
				else {
					open PE, $sf or die "Can not open $sf $!\n.";
				}
				while (<PE>) {
					chomp;
					my @tmp = split();
					if ( $tmp[3] == 1 ) {
						$gene->{ $tmp[7] } += 0.5 if exists $gene->{ $tmp[7] };
					}
				}
				close PE;
			}
			else {
				print $sf."\n";
				if ( $sf =~ /.gz$/ ) {
					open SE, "gzip -dc $sf |"
					  or die "Can not open $sf $!\n.";
				}
				else {
					open SE, $sf or die "Can not open $sf $!\n.";
				}
				my ( $prid, $pgid );
				while (<SE>) {
					chomp;
					my ( $rid, $gid ) = (split)[ 0, 7 ];
					if ( $prid && $pgid ) {
						if ( $prid eq $rid && $pgid eq $gid ) {
							$gene->{$gid}++;
							( $prid, $pgid ) = ();
						}
						else {
							$gene->{$pgid}++;
							( $prid, $pgid ) = ( $rid, $gid );
						}
					}
					else {
						( $prid, $pgid ) = ( $rid, $gid );
					}

		  #$pgid && ( $gene->{$pgid}++ );
		  #( $prid, $pgid ) = ( $prid && $prid eq $rid ) ? () : ( $rid, $pgid );

				}
				close SE;
			}
		}
	}
}

sub readsoap_pe_se() {
	my ( $pe_file_a, $se_file_a, $gene ) = @_;

			if ( $pe_file_a && $pe_file_a =~ /PE/g ) {
				if ( $pe_file_a =~ /.gz$/ ) {
					open PE, "gzip -dc $pe_file_a |"
					  or die "Can not open $pe_file_a $!\n.";
				}
				else {
					open PE, $pe_file_a or die "Can not open $pe_file_a $!\n.";
				}
				while (<PE>) {
					chomp;
					my @tmp = split();
					if ( $tmp[3] == 1 ) {
						$gene->{ $tmp[7] } += 0.5 if exists $gene->{ $tmp[7] };
					}
				}
				close PE;
			}
			if($se_file_a && $se_file_a =~ /SE/g) {
				if ( $se_file_a =~ /.gz$/ ) {
					open SE, "gzip -dc $se_file_a |"
					  or die "Can not open $se_file_a $!\n.";
				}
				else {
					open SE, $se_file_a or die "Can not open $se_file_a $!\n.";
				}
				my ( $prid, $pgid );
				while (<SE>) {
					chomp;
					my ( $rid, $gid ) = (split)[ 0, 7 ];
					if ( $prid && $pgid ) {
						if ( $prid eq $rid && $pgid eq $gid ) {
							$gene->{$gid}++;
							( $prid, $pgid ) = ();
						}
						else {
							$gene->{$pgid}++;
							( $prid, $pgid ) = ( $rid, $gid );
						}
					}
					else {
						( $prid, $pgid ) = ( $rid, $gid );
					}

		  #$pgid && ( $gene->{$pgid}++ );
		  #( $prid, $pgid ) = ( $prid && $prid eq $rid ) ? () : ( $rid, $pgid );

				}
				close SE;
			}		
}

sub readsam(){
    my ( $sam_file, $gene , $samtools) = @_;
    if ( -s $sam_file ) {
	my ($oo,$ot,$to,$tt);
	if (-B "$sam_file") {
	    $oo = `$samtools view $sam_file | tail -2 | awk 'NR==1{print \$1}'`;
	    $ot = `$samtools view $sam_file | tail -2 | awk 'NR==1{print \$3}'`;
	    $to = `$samtools view $sam_file | tail -2 | awk 'NR==2{print \$1}'`;
	    $tt = `$samtools view $sam_file | tail -2 | awk 'NR==2{print \$3}'`;
	} else {
	    $oo = `tail -2 $sam_file\|awk 'NR==1{print \$1}'`;
	    $ot = `tail -2 $sam_file\|awk 'NR==1{print \$3}'`;
	    $to = `tail -2 $sam_file\|awk 'NR==2{print \$1}'`;
	    $tt = `tail -2 $sam_file\|awk 'NR==2{print \$3}'`;
	}
        chomp $oo;
        chomp $ot;
        chomp $to;
        chomp $tt;
        if ( $oo ne $to || $ot ne $tt ) {
            $gene->{$tt}++;
        }
        (-B "$sam_file") ? open SA, "$samtools view $sam_file | " || die $! :
	open SA, $sam_file or die "Can not open $sam_file $!\n.";
        my ( $prid, $pgid );
        while (<SA>) {
            chomp;
            next if /^\@/;
            my @temp  =  /\t/ ? split(/\t+/) : split(/\s+/);
            my ( $rid, $gid ) = ($temp[0],$temp[2]);
            if ( $prid && $pgid ) {
                if ( $prid eq $rid && $pgid eq $gid ) {
                    $gene->{$gid}++;
                    ( $prid, $pgid ) = ();
                } else {
                    $gene->{$pgid}++;
                    ( $prid, $pgid ) = ( $rid, $gid );
		}
	    } else {
		( $prid, $pgid ) = ( $rid, $gid );
	    }
	}
        close SA;
    }
}
