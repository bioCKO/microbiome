#! /usr/bin/perl -w
use strict;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use Getopt::Long;
#get software & scripts' pathway
use lib "$Bin/..";
my $lib = "$Bin/../..";
use PATHWAY;
(-s "$Bin/../../../bin/Pathway_cfg.txt") || die"error: can't find config at $Bin/../../../bin/, $!\n";
my ($Rscript,$R,$convert) = get_pathway("$Bin/../../../bin/Pathway_cfg.txt",[qw(Rscript R CONVERT)],$Bin,$lib);

@ARGV == 4 || @ARGV == 5 || die"usage:perl $0 <com> <tax> <prefix> <outdir> [<top>]\n";
my($matrix1,$matrix2,$prefix,$outputdir,$top_num)=@ARGV;
&spearman($matrix1,$matrix2,$prefix,$outputdir,$top_num);

#====================================================================================================================
#sub routines
sub spearman{
    my ($tax_matrix, $com_matrix, $corrlation_prefix,$outdir,$top) = @_;
    (-s $outdir)|| `mkdir -p $outdir`;
    (-s $tax_matrix && -s $com_matrix) || die $!;
    open TAX, $tax_matrix || die $!;
    <TAX>;
    my (%tax_hash, %com_hash);
    my $i=0;
    while(<TAX>){
        chomp;
        my @fields = (/\t/? split/\t/ : split/\s+/);
        push @{$tax_hash{$fields[0]}}, @fields[1..$#fields];
        last if($top && $i >= $top);
        $i++;
    }
    close TAX;
    open COM, $com_matrix || die $!;
    <COM>;
    $i=0;
    while(<COM>){
        chomp;
        my @fields = (/\t/? split/\t/ : split/\s+/);
        push @{$com_hash{$fields[0]}}, @fields[1..$#fields];
        last if($top && $i >= $top);
        $i++;
    }
    close COM;

    open OUT,">$outdir/$corrlation_prefix.xls" || die $!;
    open XING,">$outdir/$corrlation_prefix.sig" || die $!;
    my @tax_head = sort{$a cmp $b}keys %tax_hash;
    print OUT "\t",join("\t",@tax_head),"\n";
    print XING "tax/com\t",join("\t",@tax_head),"\n";

    foreach my $comp(sort keys %com_hash){
        print OUT "$comp";
        print XING "$comp";
        foreach my $tax(@tax_head){
            my $pvalue = &Spearman_Test_pvalue($Rscript, $tax_hash{$tax}, $com_hash{$comp});
            print OUT "\t$pvalue";
            ($pvalue>0.5||$pvalue<-0.5) ? print XING "\t*": print XING "\t ";
        }
        print OUT "\n";
        print XING "\n";
    }
    close OUT;
    close XING;  
    &r_heatmap("$outdir/$corrlation_prefix.xls","$outdir/$corrlation_prefix.sig",$corrlation_prefix,$outdir);
}


sub Spearman_Test_pvalue{
    my ($Rscript,$arr1,$arr2) = @_;
    my $c1 = join(",",@$arr1);
    my $c2 = join(",",@$arr2);
    #print "$c1\t$c2\n";
    my $Rtest = `$Rscript -e 'x<-c($c1);y<-c($c2); cor.test(x,y,method="spearman",conf.level=0.95)' 2>/dev/null`; #var.equal=TRUE
    #print "$Rtest";
    #my $pvalue = ($Rtest =~ /p-value\s*=\s*(\S+)/) ? $1 : 'NA';
    my $cor_value = ($Rtest =~ /^\s*(-?0?\.?\d+)\s*$/m) ? $1 : 'NA';
    $cor_value;
}

sub r_heatmap{
    my($corrlation_file,$corrlation_file_sig,$correlation_prefix,$outdir)=@_;
    my $R_heatmap = "t<-as.matrix(read.table(\"$corrlation_file\", head =T,sep=\"\t\",row.names=1));\n";
    $R_heatmap .= '
    unByteCode <- function(fun)
        {
            FUN <- eval(parse(text=deparse(fun)))
            environment(FUN) <- environment(fun)
            FUN
        }

    ## Replace function definition inside of a locked environment **HACK**
    assignEdgewise <- function(name, env, value)
        {
            unlockBinding(name, env=env)
            assign( name, envir=env, value=value)
            lockBinding(name, env=env)
            invisible(value)
        }

    ## Replace byte-compiled function in a locked environment with an interpreted-code
    ## function
    unByteCodeAssign <- function(fun)
        {
            name <- gsub(\'^.*::+\',\'\', deparse(substitute(fun)))
            FUN <- unByteCode(fun)
            retval <- assignEdgewise(name=name,
                                     env=environment(FUN),
                                     value=FUN
                                     )
            invisible(retval)
        }

    ## Use the above functions to convert stats:::plotNode to interpreted-code:
    unByteCodeAssign(stats:::plotNode)

    ## Now raise the interpreted code recursion limit (you may need to adjust this,
    ##  decreasing if it uses to much memory, increasing if you get a recursion depth error ).
    options(expressions=5e4)
    ';

    $R_heatmap .="
    library(gplots);
    library(RColorBrewer)
    lmat = rbind(c(0,3),c(2,1),c(0,4))
    pdf('$outdir/$correlation_prefix.heatmap.pdf');
    lmat = rbind(c(0,3),c(2,1),c(0,4))
    lable = read.table(\"$corrlation_file_sig\", header=T, row.names=1, sep = \"\\t\")
    lable = as.matrix(lable)
#heatmap.2(t,col=colorRampPalette(c(\"#53ddf7\",\"white\",\"#f76d53\")), keysize=5, trace='none',cexCol=1,scale='none',density.info='none',lmat=rbind( c(4,3,0),c(2,1,0),c(0,0,0) ), lwid=c(1.3,4.4,1.3), lhei=c(1,4.5,0.5), cellnote=lable, notecex = 1.5, notecol = \"white\")
heatmap.2(t,col=colorRampPalette(c(\"#53ddf7\",\"white\",\"#f76d53\")), trace='none',scale='none',density.info='none',cellnote=lable, notecol = \"white\",lmat = rbind(c(0,3,4),c(2,1,0)),lwid = c(1,4.5,3),lhei = c(1,5),margins=c(13,0),cexRow=0.7,cexCol=0.5)
    dev.off()";

    open OUT, ">$outdir/heatmap.R" || die $!;
    print OUT "$R_heatmap\n";
    close OUT;
    `$R -f $outdir/heatmap.R`;
    `$convert -density 150 $outdir/$correlation_prefix.heatmap.pdf $outdir/$correlation_prefix.heatmap.png`;
}
