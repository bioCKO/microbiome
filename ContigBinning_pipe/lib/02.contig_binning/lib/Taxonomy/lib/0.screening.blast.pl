#! /usr/bin/perl
#
@ARGV >= 3 || die"usage:perl $0 <input:blast out list> <iput:query len> <output> [input:identity,default=95] [input:coverage,default=0.9]\n";
my($input,$len,$output)=@ARGV;
$ARGV[3] ||= 95;
$ARGV[4] ||= 0.9;

my%id2len;
open(OR,$len);
while(<OR>){
    chomp;
    my@or=split/\s+/;
    $id2len{$or[0]}=$or[1];
}
close OR;

open LIST,"$input";
open(OUT,">$output");
while (my$blastfile=<LIST>) {
	chomp$blastfile;
	open(OR,"$blastfile");
	my %info;
	while (my $or=<OR>) {
		chomp$or;
        next if $or=~/^Gene_id\t/;
		my @or=split/\t/,$or;
        my $identity=$or[2];
        my $coverage=$or[3]/$id2len{$or[0]};
        next if !($identity >= $ARGV[3] && $coverage >= $ARGV[4]);
		my $evalue=$or[10];
		my $query=$or[0];
		push @{$info{$query}{$evalue}},$or;
	}
	close OR;
	LABEL:foreach my $query (keys %info){
		my @evalue=sort {$a <=> $b} keys %{$info{$query}};
		my $min_evalue=$evalue[0]*10;
		foreach my $evalue(@evalue){
			next LABEL if ($evalue > $min_evalue);
			my @lines=@{$info{$query}{$evalue}};
			print OUT join("\n",@lines)."\n";
		}
	}
}
close OUT;
