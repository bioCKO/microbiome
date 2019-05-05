#!/PROJ/GR/share/Software/perl/bin/perl
use strict;
use warnings;
use File::Basename;
use Encode;
my $usage=<<USAGE;
trasform tab file to .json file fir HTML report /#first line should be title#/
        
        perl $0 <input> <output>
example :
        perl $0 anno.tab output/json/anno.tab.json
USAGE
die $usage unless @ARGV == 2;
my $inf = shift;
my $outf = shift;
open OUT,">",$outf or die $!;
my $outname=basename($outf);
print OUT "{\"src/json/$outname\":[\n";
open IN,"<",$inf or die $!;
chomp(my $str = <IN>);
$str = &enc_utf8($str);
my @ids = split /\t/,$str;
my $firstline = 1;
while (<IN>) {
        chomp;
        next unless $_;
        my $line = &enc_utf8($_);
        my @arr = split /\t/,$line;
        if (!$firstline) {
                print OUT "},\n";
        } else {
                $firstline = 0;
        }
        print OUT "{";
        my $idx = 0;
        while (1) {
                my $id = $ids[$idx];
                if ($id eq 'SeqStrategy'){ # 2015-08-10, delete SeqStrategy
                    $idx++;
                    next;
                }
                $id = '' unless defined $id;
                my $data = $arr[$idx];
                $data = '' unless defined $data;
                if ($idx == $#ids) {
                        print OUT "\"$id\":\"$data\"\n";
                        last;
                }
                print OUT "\"$id\":\"$data\",\n";
                $idx++;
        }
}
print OUT "}\n]\n}\n";
close IN;
close OUT;
exit 0;

sub enc_utf8($) {
        my $str = shift;
        my $encoding = '';
        my @arr = qw(utf8 gbk gb2312 big5);
        my $utf8_str = $str;
        foreach my $enc (@arr) {
                eval {my $str2 = $str; Encode::decode("$enc", $str2, 1)};
                #print STDERR "$enc\t$@\n";
                if (!$@) {
                        $encoding = $enc;
                        last;
                }
        }
        #$encoding ||= 'utf8';
        if ($encoding ne 'utf8') {
                $utf8_str = encode_utf8(decode("$encoding",$str));
        }
        return $utf8_str;
}
__END__
