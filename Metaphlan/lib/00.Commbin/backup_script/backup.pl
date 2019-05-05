#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(abs_path);

## Get option
my %opt=(run=>'N');
GetOptions(\%opt,"key_level:s","indir:s","stage:s","tar:s","mv:s","run");
$opt{key_level} ||="$Bin/meta_key.level";
($opt{key_level} && -s $opt{key_level}) && $opt{indir} && $opt{stage} || die"
Usage: perl $0 --indir indir --stage 1 [--option]
Note1:  Do not use this script in the directory that you want to mv or tar !!!
Note2:  If tar or mv file to /RRM/MICRO/,do not qsub !!!

       *--key_level [file]  input key level file,default=\$Bin/meta_key.level
       *--indir     [str]   set input directory,multiple directory shuld separate by comma
       *--stage     [str]   set backup stage,the number of 1,2,3...
                                1 -- delete the file at stage 1
                                2 -- delete the file at stage 2
                                3 -- delete the file at stage 3
                                Note:the stage correspond to key level file
       --mv         [dir]   to move file to a directory,such as /RRM/MICRO/user
       --tar        [dir]   tar and gzip file to a directory,such as /RRM/MICRO/user
       --run        [str]   set whether to run backup,default='N' \n"; 

$opt{mv} = abs_path($opt{mv}) if($opt{mv});
my $level = abs_path($opt{key_level}) if($opt{key_level});

## Main
open IN,"<$level" || die"The key level file does not exist\n";
my %stage_dir;
while(<IN>){
    my @line=split /\s+/;
    push @{$stage_dir{$line[1]}},$line[0];
}
if($opt{stage} =~/0/){
    die "The stage can not be 0 !!!\n";
}
my @stage=split /,/,$opt{stage};
my @indir=split /,/,$opt{indir};
my @shdir;
for my $indir(@indir){
    $indir=abs_path($indir);
    my $name=(split /\//,$indir)[-1];
    (-d "$name\_backup_shell") || `mkdir $name\_backup_shell`;
    open OUT,">$name\_backup_shell/backup.sh";
    for my $stage(@stage){
        for my $file(@{$stage_dir{$stage}}){
            print OUT "rm -rf $indir/$file\n";
        }
    }
    if($opt{tar} && -s $opt{tar}){
        open RM,">$name\_backup_shell/$name\_rm.sh";
        $opt{tar}=abs_path($opt{tar});
        print OUT "tar -zcf $opt{tar}/$name\.tar.gz $indir\n";
        print RM "rm -r $indir\n";
        close RM;
    }
    if($opt{mv} && -d $opt{mv}){
        print OUT "mv $indir $opt{mv}\n";
    }
    close OUT;
    my $pwd=`pwd`;
    push @shdir,"$pwd/$name\_backup_shell";
}

if($opt{run} eq 'Y'){
    for my $shdir(@shdir){
        system "cd $shdir;nohup sh backup.sh & ;";
    }
}
