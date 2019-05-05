#!/usr/bin/perl -w

=head1 Usage

	perl contig_gap_info.pl [option] <fasta list file>
		<fasta list file>  format: id  sequence_path
=head1 Exmple

	perl contig_gap_info.pl  **ncbifa.lst
=cut

use strict;

die (`pod2text $0`) if (@ARGV <= 0);

my $scaffold_list = $ARGV[0];

open LIST, "$scaffold_list" or die "Open error for $scaffold_list\n";
while (<LIST>) {
	chomp;
	next if (/^\s*#|^\s*$/);
	s/\s+$//g;
	my $scaffold = (split (/\s+/))[-1];
	print "$scaffold\t";
	my ($temp_seq, $temp_len);
	my $out_info = "$scaffold.stat.xls";
	print "$out_info\n";
	open INFO, ">$out_info" or die "can not create file: $out_info\n" if ($out_info);
	open IN, "<$scaffold" or die "Open error for $scaffold : $!\n"; 
	$/ = "\>";
	<IN>;
	while (<IN>)
	{	
		chomp;

		my ($scaf_id, $scaf_seq) = split (/\n/, $_, 2);
		$scaf_seq =~ s/[^atgcnATGCN]//g;
		$scaf_seq =~ s/^N+//g; $scaf_seq =~ s/N+$//g;
		$scaf_seq = uc ($scaf_seq);

		if ($out_info)
		{
			my ($scaf_len, $scaf_GC);
			$scaf_len = length ($scaf_seq);
			$temp_seq = $scaf_seq; 
			$temp_seq =~ s/[^ATGC]//g; $temp_len = length ($temp_seq);
			$temp_seq =~ s/[^GC]//g;
			($temp_len == 0) ? ($scaf_GC = 0) : ($scaf_GC = length ($temp_seq) / $temp_len * 100);

			printf INFO (">%s\t%d\t%5.2f%s\n", $scaf_id, $scaf_len, $scaf_GC, "%") if ($out_info);

			my @contig = split (/N+/, $scaf_seq);
			my @gap = split (/[ATGC]+/, $scaf_seq); shift @gap;
			for (my $i=0; $i<@contig; $i++) {
				my ($ctg_id, $ctg_len, $ctg_GC, $ctg_start, $ctg_end);
				$ctg_id = "$scaf_id:$scaf_len--ctg" . ($i+1);
				$ctg_len = length ($contig[$i]);
				$temp_seq = $contig[$i];
				$temp_seq =~ s/[^GC]//g;
				($ctg_len == 0) ? ($ctg_GC = 0) : ($ctg_GC = length ($temp_seq) / $ctg_len * 100);
				for (my $j=0; $j<$i; $j++) {
					$ctg_start += length ($contig[$j]) + length ($gap[$j]);
				}
				$ctg_start += 1;
				$ctg_end = $ctg_start + $ctg_len - 1;

				printf INFO ("\t%s\t%d\t%d\t%d\t%5.2f%s\t\t", $ctg_id, $ctg_len, $ctg_start, $ctg_end, $ctg_GC, "%") if ($out_info);

				if ($i < @contig-1)
				{
					my ($gap_id, $gap_len, $gap_start, $gap_end);
					$gap_id = "$scaf_id--gap" . ($i+1);
					$gap_len = length ($gap[$i]);
					$gap_start = $ctg_end + 1;
					$gap_end = $gap_start + $gap_len - 1;
					print INFO "$gap_id\t$gap_len\t$gap_start\t$gap_end\n" if ($out_info);
				}
				else {
					print INFO "\n" if ($out_info);
				}
			}
		}
	}
	$/ = "\n";
	close IN;
	close INFO if ($out_info);
}
close LIST;

__END__
