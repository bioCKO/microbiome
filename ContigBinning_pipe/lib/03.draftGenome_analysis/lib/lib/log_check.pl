#!/usr/bin/perl

use strict;
use warnings;

if (@ARGV != 1) {
	warn "\tusage: perl log_check.pl <readfq log list>\n
	<readfq log list> file format: \"log file\" \"data limit(M)\"\n\n";
	exit;
}

my $infile = shift;
my $return_info;

open IN, $infile || die;
while (<IN>) {
	chomp;
	next if (/^\s*\#|^\s*$/);
	s/^\s+|\s+$//g;
	if (/^(\S+)\s+([\d\.]+)[Mm]?/) {
		my ($log, $limit) = ($1, $2);
		if (-s $log) {
			my $stat = `less $log`;
			#449028000   4989200   73643670    98730    56503080  1208160   0  (90:90)   301000140    16574220
			if ($stat =~ /\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\(\d+:\d+\)\s+(\d+)\s+\d+/) {
				my $outdata = $1;
				if (($limit > 0) && ($outdata < ($limit * 1000000))) {
					$return_info .= "error: output data size doesn't reach the limit of $log.\n";
				}
			}
			else {
				$return_info .= "error: format of $log.\n";
			}
		}
		else {
			$return_info .= "error: file isn't exist of $log.\n";
		}
	}
}
close IN;
$return_info ||= "1\n";
print $return_info;

