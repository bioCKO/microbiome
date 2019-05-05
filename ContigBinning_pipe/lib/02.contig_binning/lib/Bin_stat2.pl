use Cwd qw(abs_path);
use FindBin qw($Bin);

my $indir = shift;
$indir = abs_path($indir); 
my $len = shift;
$len ||= "500"; 

## get software's path
use lib "$Bin/../../00.Commbin/";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($ss_o, $get_len_fa, $line_diagram, $svg2xxx) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(SS GET_FA_LEN LINE_DIAGRAM SVG2XXX)], $Bin, $lib); 

my @bins = glob"$indir/*/*fa";
open O, ">$indir/bins_stat2.sh";
foreach(@bins){
    my $bin = $_;
    my ($index,$bin_name) = (split/\//,$bin)[-2..-1];
    $bin_name =~ s/\.fa//g;
    print O "cd $indir/$index
    $ss_o $bin $len >$bin_name.scaftigs.$len.ss.txt\n".
    "$get_len_fa $bin_name.fa >$bin_name.scaftigs.len\n".
    "$line_diagram -fredb2 -fredb -numberc -vice -ranky2 \"0:2\" -samex -bar -frame  -y_title  \"Frequence(#)\" -y_title2 \"Percentage(%)\" -barstroke black -barstroke2 black -symbol -signs \"Frequence(#),Percentage(%)\" -color \"cornflowerblue,gold\" -linesw 2 -opacity 80 -opacity2 40  -sym_xy p0.6,p0.98  --sym_frame  -x_mun 0,500,6  -x_title \"Scaftig Length(bp)\"   --h_title \'$bin_name Length Distribution\' $bin_name.scaftigs.len > $bin_name.len.svg\n".
   "$svg2xxx -t png $bin_name.len.svg\n\n";
}

print O "ls $indir/*/*.scaftigs.$len.ss.txt > $indir/total.scaftigs.ss.list\n".
"perl $Bin/get_table_scaf.pl --data_list $indir/total.scaftigs.ss.list --outdir $indir --outfile total.scaftigs.stat.info.xls\n";
close O;
system("sh $indir/bins_stat2.sh");
