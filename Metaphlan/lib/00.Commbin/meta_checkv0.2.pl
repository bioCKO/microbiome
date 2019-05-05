#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use Getopt::Long;
use File::Basename; 
@ARGV || die "Usage:perl $0 <workdir>
Name:      $0
Function:  To check the working|result|Shell directory of meta project.
Version:   0.2  Date: 2015-3-16 
Version:   0.1  Date: 2015-1-30 
Author(s): Jinhui Yu ,Junru Chen;
Contact:   yujinhui[AT]novogene.cn 
Example:
    perl $0 /TJPROJ1/MICRO/yujinhui/meta/test/MetaV2.2_Test/Syst/

";
##===Main===
my %opt=(s2=>'',help=>'');
GetOptions (\%opt,"s2","help"); 
my ($indir)=@ARGV;
$indir=abs_path($indir);
(-s "$indir")||die "The indir doesn't exist\!";
my $result="$indir"."/result/" if (-s "$indir/result");
$result=abs_path($result);
my $shdir=$indir."/Shell";
(-s "$shdir")||warn "The Shell derectory doesn't exist\!";

########################################################################
##                         process directory                          ##
########################################################################
my @prodir =qw(01.DataClean 02.Assembly 03.NR_Scaftigs 04.ReadsMapping 05.TaxAnnotation 06.GenePredict 07.FunctionAnnotation 08.Statistical);
for (@prodir){
    $_ = "$indir/$_";
}

########################################################################
##                         result directory                           ##
########################################################################

my @dir = qw(01.CleanData 02.Assembly 03.ReadsMapping 04.TaxAnnotation 05.GeneComponet 06.FunctionAnnotation);
for (@dir){
    $_ = "$result/$_";
}

###get sample name list 
my (@name,$name,%fq);
(-s "$result/../01.DataClean/Dataclean.total.list") || die "Please check the Dataclean.total.list!";
   for(`less $result/../01.DataClean/Dataclean.total.list`){
      my @l=split;
	  $name=$l[0];
	  $fq{$name}=$l[-1];#name=>name.fq1.gz,name.fq2.gz;
      push @name,$name;	  
      } 
(-s "Check.log" ) && `rm "Check.log" `;
`rm result.tree` if (-s "result.tree");
open LOG,">Check.log"; 
my $date= ` date +\"%D %T\" `;
print LOG "$date\n";
my $or;
#============================================================================================================
####step1：Checking the processing derectory
print LOG "1.The processing derectory:\n";
my %process_dir;
my ($yes,$no)=qw(YES NO);#lable yes or no 
##01.CleanData
print "\n==== Start checking the '01.DataClean' directory ====\n";
my %name_insize;
my $host=0;
my $num=0;
##item1:01.DataClean/sample/sample_insize.out.err
print LOG "01.DataClean\n#item1:";
#print "#01.DataClean/sample/sample_insize.out.err...\n";
if(-s "$indir/01.DataClean/Dataclean.total.list"){
	for(@name){
       my @fq=split/\,/,$fq{$_};#name.fq1.gz,name.fq2.gz;
	   $fq[0]=~/\/($_\_\d+)/;
	   $name_insize{$_}=$1;  
	   if($fq[0]=~/nohost/){ #exist hosts
	      $host=1;
          if (-z "$indir/01.DataClean/SystemClean/$_/$name_insize{$_}\.out.err"){ next; }	#the size of *out.err is 0k 
		  else {
		     $num++;
	         print LOG "$indir/01.DataClean/SystemClean/$_/$name_insize{$_}\.out.err\t$no\n";
			 print "$indir/01.DataClean/SystemClean/$_/$name_insize{$_}\.out.err\t$no\n";		 			 
               }
        }
       else {    #no hosts
          if ( ! -s "$indir/01.DataClean/$_/$name_insize{$_}\.out.err"){next ;}	#the size of *out.err is 0k 		 
		  else {
		     $num++;
	         print LOG "$indir/01.DataClean/SystemClean/$_/$name_insize{$_}\.out.err\t$no\n";
			 print "$indir/01.DataClean/SystemClean/$_/$name_insize{$_}\.out.err\t$no\n";
               }	      	     
	   }
	}#for(@name)	
	if($num==0){
	    print "01.DataClean/sample/sample_insize.out.err\t$yes!\n";
		print LOG "01.DataClean/sample/sample_insize.out.err\t$yes\n" ;
	}#all out.err is ok 
	print "\n(Please press Enter to go on)\n";
	<STDIN>;
##item2:01.DataClean/total.QCstat.info.xls
    print "Please check the total.QCstat.info.xls:(print 'q' to exit ) \n\n";
#    print "#01.DataClean/total.QCstat.info.xls...\n";	
	system "less -SN  \"$indir/01.DataClean/total.QCstat.info.xls\"\n" if (-s "$indir/01.DataClean/total.QCstat.info.xls");
	print "\nIs 01.DataClean ok?\n(press 'y' or 'n')\n";
##Enter	
	
INPUT:{
	$or=<STDIN>;
	($or=~/^[y|\n]/i)?($or=$yes):
	($or=~/^n/i)?($or=$no):(redo INPUT);
}	
	print LOG "#item2:01.DataClean/total.QCstat.info.xls\t$or\n\n";

}#if -s 

##02.Assembly
print "\n==== Start checking the '02.Assembly' directory ====\n ";
##item3:02.Assembly/sample/sample.soapdenovo.cfg
print LOG "02.Assembly\n";
print "Please check the 02.Assembly/sample/sample.soapdenovo.cfg \n\n";
if(-s "$indir/02.Assembly/total.scaftigs.ss.list"){
my $sample_num=$#name+1;
my $all_round=int(($sample_num+4)/5);
my ($num2,$show_round)=(0,1);
SOAP:for(@name){
        $num2++;
		my $remain=$num2%5;
        (-s "$indir/02.Assembly/$_/$_.soapdenovo.cfg") || print "The $indir/02.Assembly/$_/$_.soapdenovo.cfg does not exist!" && print LOG "The $indir/$_/$_.soapdenovo.cfg does not exist!\n";
        system "cat \"$indir/02.Assembly/$_/$_.soapdenovo.cfg\"";
		print "\n";
	    if ($remain){next;} 
		else {
		    print "\nPlease press Enter to go on or 'q' to exit this step($show_round\/$all_round)\n";#check 5 samples every time 
			$show_round++;
			}
		$or=<STDIN>;
		next if($or=~/^\n/); ##Wait and press Enter to go on 
		last SOAP if ($or=~/^q/i); ##get rid of this step
		}	
	print "\nIs 02.Assembly/sample/sample.soapdenovo.cfg ok?\n(press 'y' or 'n')\n";
##Enter	
INPUT:{
	$or=<STDIN>;
	($or=~/^[y|\n]/i)?($or=$yes):
	($or=~/^n/i)?($or=$no):(redo INPUT);
}
	print LOG "#item3:02.Assembly/sample/sample.soapdenovo.cfg\t$or\n";	
	
##item4: 02.Assembly/sample/sample.scaftigs.ss.list
	print "\nPlease check '02.Assembly/sample/sample.scaftigs.ss.list' following:\n";
	my $ss="$indir/02.Assembly/total.scafSeq.ss.list" if (-s "$indir/02.Assembly/total.scafSeq.ss.list");
	system "cat -s \"$ss\" \n\n";
	system "wc -l \"$ss\" \n\n";	
	print "Is 02.Assembly/sample/sample.scaftigs.ss.list ok?\n(press 'y' or 'n')\n";
##Enter	
INPUT:{
	$or=<STDIN>;
	($or=~/^[y|\n]/i)?($or=$yes):
	($or=~/^n/i)?($or=$no):(redo INPUT);
}
	print LOG "#item4:02.Assembly/sample/sample.scaftigs.ss(.list)\t$or\n";
	
##item5:02.Assembly/total.scaftigs.stat.info.xls
	print "\nPlease check 'total.scaftigs.stat.info.xls' following:\n";
	system "cat \"$indir/02.Assembly/total.scaftigs.stat.info.xls\"\n\n";
	system "wc -l \"$indir/02.Assembly/total.scaftigs.stat.info.xls\"\n\n";	
	print "\nIs 02.Assembly/total.scaftigs.stat.info.xls ok?\n(press 'y' or 'n')\n";
##Enter	
INPUT:{
	$or=<STDIN>;
	($or=~/^[y|\n]/i)?($or=$yes):
	($or=~/^n/i)?($or=$no):(redo INPUT);
}
	print LOG "#item5:02.Assembly/total.scaftigs.stat.info.xls\t$or\n\n";	
	
}#for if -s

##item6:04.ReadsMapping/Total/
##04.ReadsMapping
my $num4=0;
   print "\n==== Start checking the '04.ReadsMapping' directory ====\n";
   for ( qw(total.coverage total.coverage.single total.cover.depth total.cover.length total.scaf.screening.fa total.cover.depth.relative total.cover.depth.relative.tree) ){	
     if(-s "$indir/04.ReadsMapping/Total/$_" || -s "$indir/04.ReadsMapping/Total/$_.xls"){
	    next;
	 }
	 else {
	    $num4++;
	    print "$indir/04.ReadsMapping/Total/$_ :does NOT exist!\n";
		print LOG "The $indir/04.ReadsMapping/Total/$_ : does NOT exist!\n";
		}
}
	(! $num4)?($or=$yes):($or=$no);
	print LOG "04.ReadsMapping\n","#item6:04.ReadsMapping/Total/\t$or\n\n";	
    print "04.ReadsMapping/Total/\t$or\n";
	
##06.GenePredict	
print "\n==== Start checking the '06.GenePredict' directory ====\n";#}
#item7:06.GenePredict
print LOG "06.GenePredict\n";
if(-s "$indir/06.GenePredict/Gene_Table" ){
    my $num7=0;
    for (qw(Uniq.Genes.single.xls Uniq.Genes.table.relative.tree Uniq.Genes.table.relative.xls Uniq.Genes.table.xls) ){
    (-s "$indir/06.GenePredict/Gene_Table/$_") ? next : (print "$_ does NOT exist!\n" && print LOG "The $indir/06.GenePredict/Gene_Table/$_ does NOT exist!\n");
	$num7++;
       }
	(! $num7)?($or=$yes):($or=$no);
	print LOG "#item7:06.GenePredict/\t$or\n\n";	
    print "06.GenePredict/\t$or\n";	
}  


#============================================================================================================
####step2：Checking the Shell derectory
print LOG "\n2.The Shell derectory:\n";
#item8:Shell/*.log
print "\n==== Start checking the 'Shell' directory ====\n";
print LOG "Shell/\n";
#print "Shell/\n";
my $num8=0;
for (`ls $shdir/step*.log`){
    chomp;
    if(-z "$_" ){next;}
    else {
		print "\n$_:\n";	    
#	    system "cat \"$_\" \n";
	    system "head -10 \"$_\" \n";
		print LOG "\n$_:\n";
		system "head -10 \"$_\" >> Check.log ";
    $num8++; 
    }
} 
	(! $num8)?($or=$yes):($or=$no);
	print LOG "#item8:Shell/*.log\t$or\n";
	print "Shell/*.log\t$or\n";

#item9:Shell/detail/0*/*qsub/*.e*
my $num9=0;
for (` ls $shdir/detail/0*/*qsub/*.e* `){
    chomp;
	if(-s "$_"==114 || `grep Selenocysteine $_` ){next;} 
#	elsif (-s "$_"!=114 && $=~/Ass_stat/ig){
#		print "\n[Warning]$_:\n$top10";	    
#	} 
    else{
		my $top10= `head -10 $_`;
		print "\n[Warning]$_:\n$top10";
	    print LOG "\n[Warning]$_:\n$top10";
	    $num9++;	
	}
}
    (! $num9)?($or=$yes):($or=$no);
    if ($or){  
	    print LOG "#item9:Shell/detail/0*/*qsub/*.e*\t$or\n\n";
	    print "Shell/detail/0*/*qsub/*.e*\t$or\n\n";
    }
   	
	
#item10:result.tree
`tree "$indir/result" > result.tree`;
print "\n\nPress Enter to check the result.tree:(press 'q' to exit)\n\n";
<STDIN>;
system "less -SN \"result.tree\" "|| die $!;
print "Is result.tree ok ?(press 'y' or 'n')\n";
##Enter	
INPUT:{
	$or=<STDIN>;
	($or=~/^[y|\n]/i)?($or=$yes):
	($or=~/^n/i)?($or=$no):(redo INPUT);
}	
	print LOG "#item10:result.tree\t$or\n\n";	

#checking done
print "\n\n==== All checking done! ====\n\n";
print LOG "All checking done!\n\n";
print "(Press Enter to skip the Check.log)\n";
<STDIN>;
print "The checking result:\n\n";
system "more \"Check.log\" \n";
#==================================================================================================================
close LOG;

#===subroutine==#

