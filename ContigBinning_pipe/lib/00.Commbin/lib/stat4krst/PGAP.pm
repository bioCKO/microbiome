package PGAP;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(parse_config comma_add rainbow_color);
use Data::Dumper;

#my @list=("blast", "qsub_sge");
#my ($blast, $qsub_sge) = parse_config("config.txt",$Bin, @list);

sub rainbow_color { #input: how many color do you want.
	my $number = $_[0];
	my @color_list;
	push (@color_list,
		"#CCCCCC", "#FFCCCC", "#FF9999", "#FF6666", "#FF3333", "#FF0000", "#FF6699", "#FF0066",
		"#FFFFFF", "#FFCCFF", "#FF99FF", "#FF66FF", "#FF33FF", "#FF00FF", "#CC66FF", "#9900FF",
		"#000000", "#CCCCFF", "#9999FF", "#6666FF", "#3333FF", "#0000FF", "#6699FF", "#0066FF",
		"#333333", "#CCFFFF", "#99FFFF", "#66FFFF", "#33FFFF", "#00FFFF", "#66FFCC", "#00FF99",
		"#666666", "#CCFFCC", "#99FF99", "#66FF66", "#33FF33", "#00FF00", "#99FF66", "#66FF00",
		"#999999", "#FFFFCC", "#FFFF99", "#FFFF66", "#FFFF33", "#FFFF00", "#FFCC66", "#FF9900");
	my $color_num = $#color_list + 1;
	my $step = int ($color_num / $number);
	print "$color_num / $number $step\n";
	my $return_str = "";
	if ($step > 1) {
		foreach (1..$number) {$return_str .= " " . $color_list[($_-1)*$step];}
	}
	elsif ($step == 1 || $number <= $color_num) {
		$return_str = join (" ", @color_list[0..$number-1]);
	}
	else { #$number > $color_num
		foreach (1..$number) {
			$return_str .= " " . $color_list[($_ - 1) % $color_num];
		}
	}
	$return_str =~ s/^\s+//;
	return $return_str;
}

sub parse_config{
	my $conifg_file = shift;
	my $bin = shift;
	my @array = @_;
	my %config_p;
	my %prepare_bin;
	my $error_status = 0;
	my @out_array;
	open IN, $conifg_file || die "open error: $conifg_file\n";
	while (<IN>) {
		chomp;
		next if (/^#/ || /^\s*$/);
		last if (/^__END__/);
		if (/(\S+)\s*:\s*"(\S+)"/) { 
			$prepare_bin{$1} = $2; 
			$prepare_bin{$1} =~ s/DIR_Bin/$bin/;
		   	next; 
		}

		if (/(\S+)\s*=\s*<\s*(.*)\s*>/) {
			my ($name, $path) = ($1, $2);
			$path =~ tr/"/\"/;
			$path =~ tr/$/\$/;
			while ($path =~ /(DIR_\w+)\//) {
				my $dir = $prepare_bin{$1};
				$path =~ s/$1/$dir/g;
			}
			$config_p{$name} = $path;
#tRNAscan = <export PERLLIB="$PERLLIB:DIR_Blc/tRNAscan-SE-1.3.1/bin"; DIR_Blc/tRNAscan-SE-1.23/bin/tRNAscan-SE>
		}
		elsif (/(\S+)\s*=\s*([^\/\s]+)(\/\S+)/) { $config_p{$1} = $prepare_bin{$2} . $3; }
		elsif (/(\S+)\s*=\s*(\/\S+)/) { $config_p{$1} = $2; }
	}
	close IN;
#	print Dumper \%config_p;

	foreach (@array) {
		while ($config_p{$_} =~ /([^\/]+\/\.\.\/)/) {
		    $config_p{$_} =~ s/$1//g;
		}
		$config_p{$_} =~ s/\/\//\//g;
		if ($config_p{$_} =~ /\*$/) {
			$config_p{$_} =~ s/\*$//;
			push (@out_array, $config_p{$_});
		}
		else{
			my $path = (split (/\s+/, $config_p{$_}))[-1];
			if (! -e $path) {
				warn "Non-exist: $_ \"$path\"\n";
				$error_status = 1;
				push (@out_array, "");
			}
			else {
				push (@out_array, $config_p{$_});
			}
		}
	}
	die "\nExit due to error of software configuration\n" if($error_status);
	return @out_array;
}


sub comma_add {
	my $nu = shift;
	my $arg = "%.${nu}f";
	foreach (@_) {
		$_ = sprintf($arg,$_);
		$_ = /(\d+)\.(\d+)/ ? comma($1) . '.' . $2 : comma($_);
		$_ = "0" if ($_ =~ /^[0\.]+$/);
	}
}
sub comma{
	my ($c,$rev) = @_;
	(length($c) > 3) || return($c);
	$rev || ($c = reverse $c);
	$c =~ s/(...)/$1,/g;
	$rev || ($c = reverse $c);
	$rev ? ($c =~ s/,$//) : ($c =~ s/^,//);
	$c;
}

1;

