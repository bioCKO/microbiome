@ARGV == 2 || die"perl $0 <seq> <abu_table>\n";
my $seq_file = $ARGV[0];
my $abu_table = $ARGV[1];
my %BinContigs;
open F, $seq_file;
while(<F>){
    chomp;
    if(/>/){
        $id = $_;
        $id =~ s/>//g;
        $BinContigs{$id} = 1;
    }
}close F;

open F, $abu_table;
my $head = <F>;
print $head;
while(<F>){
    chomp;
    my $id = (split/\t/,$_)[0];
    if($BinContigs{$id}){
        print $_."\n";
    }
}close F;
