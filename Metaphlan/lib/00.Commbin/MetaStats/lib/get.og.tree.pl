#! /usr/bin/perl

use warnings;
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);

@ARGV == 2 || die "usage: perl $0 <input list> <output dir>\n";
my($input,$outdir)=@ARGV;
#get software pathway
use lib "$Bin/../../";
my $lib = "$Bin/../../../";
use PATHWAY;
(-s "$Bin/../../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../../bin, $!\n";
my ($tree_dir,$nog_anno,$css,$logo) = get_pathway("$Bin/../../../../bin/Pathway_cfg.txt",[qw(NOG_TREE NOG_ANNO2 KEGG_CSS KEGG_LOGO)],$Bin,$lib);

open(OR,"$nog_anno");
my %ogid2anno;
while (<OR>) {
	chomp;
	my @or=split/\t/;
	$ogid2anno{$or[1]}{proteins}=$or[2];
	$ogid2anno{$or[1]}{species}=$or[3];
	$ogid2anno{$or[1]}{catagory}=$or[4];
	$ogid2anno{$or[1]}{description}=$or[5];
}
close OR;

(-s "$outdir/src") || `mkdir -p $outdir/src`;
`cp -f $css $outdir/src/ `;
`cp -f $logo $outdir/src/ `;
open(OR,"$input");
<OR>;
open(OUT,">$outdir/og.trees.locate.html");
open(OUT2,">$outdir/og.trees.html");
print OUT '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />
<meta NAME="Author" CONTENT="guoyang@novogene.cn" /> 
<meta NAME="Version" CONTENT="20121102v1.0" /> 
<title>eggNOG Ortholog Annotation</title>
<link href="./src/base.css" type="text/css" rel="stylesheet">
</head>
<body>
<div>
<p><a name="home"><img class="normal" src="./src/logo.png" /></a></p>
</div><br />
<h1>The annotated Ortholog Groups</h1>
<table class="gy">
<tr>
	<th>Catagory</th>
	<th>Catagory Description</th>
	<th>Catagory</th>
	<th>Catagory Description</th>
	</tr>
';
print OUT2 '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />
<meta NAME="Author" CONTENT="guoyang@novogene.cn" /> 
<meta NAME="Version" CONTENT="20121102v1.0" /> 
<title>eggNOG Ortholog Annotation</title>
<link href="./src/base.css" type="text/css" rel="stylesheet">
</head>
<body>
<div>
<p><a name="home"><img class="normal" src="./src/logo.png" /></a></p>
</div><br />
<h1>The annotated Ortholog Groups</h1>
<table class="gy">
<tr>
	<th>Catagory</th>
	<th>Catagory Description</th>
	<th>Catagory</th>
	<th>Catagory Description</th>
	</tr>
';
my $catagory=&get_catelogy;
print OUT "$catagory";
print OUT2 "$catagory";
print OUT '
</table>
<p></p>
</br>
</br>
</br>
<table class="gy">
	<tr>
	<th>Ortholog Group ID</th>
	<th>Proteins</th>
	<th>Species</th>
	<th>Catagory</th>
	<th>Description</th>
	<th>Phylogenetic Tree</th>
	</tr>';
print OUT2 '
</table>
<p></p>
</br>
</br>
</br>
<table class="gy">
	<tr>
	<th>Ortholog Group ID</th>
	<th>Proteins</th>
	<th>Species</th>
	<th>Catagory</th>
	<th>Description</th>
	<th>Phylogenetic Tree</th>
	</tr>';
while (<OR>) {
	chomp;
	my $og=(split/\t/)[0];
	`ln -fs $tree_dir/$og.html $outdir/src/`;
	print OUT "
			<tr>
			<td>$og</td><td>$ogid2anno{$og}{proteins}</td><td>$ogid2anno{$og}{species}</td><td>$ogid2anno{$og}{catagory}</td><td>$ogid2anno{$og}{description}</td><td><a href=./src/$og.html target=_blank>>please click</a></td>
			</tr>
		";
	print OUT2 "
			<tr>
			<td>$og</td><td>$ogid2anno{$og}{proteins}</td><td>$ogid2anno{$og}{species}</td><td>$ogid2anno{$og}{catagory}</td><td>$ogid2anno{$og}{description}</td><td><a href=http://eggnogapi.embl.de/nog_data/html/tree/$og target=_blank>>please click</a></td>
			</tr>
		";
}
close OR;
print OUT '
</table>
</body>
</html>';
print OUT2 '
</table>
</body>
</html>';
close OUT;
close OUT2;




sub get_catelogy{
	my %modules_des=(
#INFORMATION STORAGE AND PROCESSING
	'J','Translation, ribosomal structure and biogenesis',
	'A','RNA processing and modification',
	'K','Transcription',
	'L','Replication, recombination and repair',
	'B','Chromatin structure and dynamics',
#CELLULAR PROCESSES AND SIGNALING
	'D','Cell cycle control, cell division, chromosome partitioning',
	'Y','Nuclear structure',
	'V','Defense mechanisms',
	'T','Signal transduction mechanisms',
	'M','Cell wall/membrane/envelope biogenesis',
	'N','Cell motility',
	'Z','Cytoskeleton',
	'W','Extracellular structures',
	'U','Intracellular trafficking, secretion, and vesicular transport',
	'O','Posttranslational modification, protein turnover, chaperones',
#METABOLISM
	'C','Energy production and conversion',
	'G','Carbohydrate transport and metabolism',
	'E','Amino acid transport and metabolism',
	'F','Nucleotide transport and metabolism',
	'H','Coenzyme transport and metabolism',
	'I','Lipid transport and metabolism',
	'P','Inorganic ion transport and metabolism',
	'Q','Secondary metabolites biosynthesis, transport and catabolism',
#POORLY CHARACTERIZED
	'R','General function prediction only',
	'S','Function unknown',
	);
	my @key=sort keys %modules_des;
	my $return;
	for (my $i = 0; $i < $#key; $i+=2) {
		$return .= "<tr>
		<td>$key[$i]</td><td>$modules_des{$key[$i]}</td><td>$key[$i+1]</td><td>$modules_des{$key[$i+1]}</td>
		</tr>";
	}
	$return .= "<tr>
		<td>$key[$#key]</td><td>$modules_des{$key[$#key]}</td><td></td><td></td>
		</tr>";
	return$return;
}