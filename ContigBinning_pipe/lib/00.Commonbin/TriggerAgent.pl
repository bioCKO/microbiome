#!/usr/bin/perl 

use strict; 
use Digest::SHA;
use strict;
use FindBin qw($Bin);
use FindBin qw($Bin);
BEGIN {
	my $mail_lib = "$Bin/Mail/";
        unshift @INC, $mail_lib
};
use Mail::Sender;
use Cwd qw(abs_path);
use Getopt::Long;

#set default 
my $default_to=`whoami`.'@novogene.com';
$default_to=~s/\s+//g;
my %opt = (status=>'create',from=>'novometa@163.com',to=>$default_to,passwd=>'novogene2014',sleept=>'5'); 

#get options from screen
GetOptions(
    \%opt,"status:s","from:s","to:s","passwd:s","title:s","message:s","sleept:s","attach:s","notsend","all",
);

#===========================================================================================================================================
($opt{status}=~/^(delete|modify|create)$/ && @ARGV  && &checkEmail_Format($opt{from}) && &checkEmail_Format($opt{to})) || 
die "Name: $0
Description: script to Monitor the status of the file and Send email by novometa@163.com
Version: 1.0 Date: 2014-08-14
Connector: chenjunru[AT]novogene.cn
Usage1: perl TriggerAgent.pl \@ARGV [-options]
    <files>              input files for trigger agent
    --status             supported create|delete|modify, default is created
    --sleept             the sleep time for script,default is 5s
    --from               default is novometa\@163.com, you must enter a email address
    --to                 default is username\@novogene.cn, you must enter a email address
    --passwd             default is novometa\@163.com's password
    --title              set title for email, default according to status
    --message            set message for email, default according to status
    --attach             set attachment, when you have multipe attachments, you can split by ',',like --attach 'filea,fileb'
    --notsend            not send email,just check status for @ARGV
    --all                set this option for checking status for all files in @ARGV\n\n";
#===========================================================================================================================================

##main script
my @files=@ARGV; 
my $file_num=$#files +1 ;
if($opt{attach}) { (-s $opt{attach}) || die "file $opt{attach} is not exists\n";}
# -s for --status delete modify
if($opt{status} eq 'create'){ 
     my $flag;
     while(1) { 
          sleep $opt{sleept}; 
          foreach my $file (@files) { 
               if (-s $file) { 
                    my $title=$opt{title}?$opt{title}:"$file is created\n";
                    my $message=$opt{message}?$opt{message}:"your file $file has been created\n\n";
                    $opt{notsend} || &Send_email($title,$message);
                    $opt{all} || exit;
                    $flag++;
                    @files = grep (!/^$file$/,@files);
               }
          }
          $opt{all} && ($flag == $file_num) && exit;
     }
}

if($opt{status} eq 'delete'){ 
    my $flag;
     while(1) { 
          sleep $opt{sleept}; 
          foreach my $file (@files) { 
               if (! -s $file) { 
                    my $title=$opt{title}?$opt{title}:"$file is deleted\n";
                    my $message=$opt{message}?$opt{message}:"your file $file has been deleted\n\nthe last logging information is:\n".`last -2`;
                    $opt{notsend} || &Send_email($title,$message);
                    $opt{all} || exit;
                    $flag++;
                    @files = grep (!/^$file$/,@files);
               }
          }
          $opt{all} && ($flag == $file_num) && exit;
     }
}

    
if($opt{status} eq 'modify'){ 
    my %md5_res; 
    foreach my $file (@files) { 
        $md5_res{$file}=MD5_digest($file); 
     }
     my $flag;
     while(1) { 
          sleep $opt{sleept}; 
          foreach my $file (@files) { 
               if ($md5_res{$file} ne MD5_digest($file)) { 
                    my $title=$opt{title}?$opt{title}:"$file is changed";
                    my $message=$opt{message}?$opt{message}:"your file $file has been changed\n\nthe last logging information is:\n".`last -2`."\nthe changed information is:\n".`stat $file`;
                    $opt{notsend} || &Send_email($title,$message);
                    $opt{all} || exit;
                    $flag++;
                    @files = grep (!/^$file$/,@files);
               }
          }
          $opt{all} && ($flag == $file_num) && exit;
     }
}


# sub script
sub MD5_digest { 
     my $file=shift; 
     my $sha=Digest::SHA->new('256'); 
     $sha->addfile($file); 
     my $digest=$sha->hexdigest; 
     return "$digest"; 
}    
     
sub Send_email { 
     my($subject,$msg)=@_;
     my $user=$1 if($opt{from}=~/(.*)\@.*/); 
     if($opt{attach}){
     my $sender=new Mail::Sender->MailFile({ 
          smtp => 'smtp.163.com', 
          from => $opt{from}, 
          to => $opt{to}, 
          subject => $subject, 
          msg => $msg, 
          auth => 'LOGIN', 
          authid => $user, 
          authpwd => $opt{passwd},
          file => $opt{attach},
     }) or die "$Mail::Sender::Error\n";}
     else{
     my $sender=new Mail::Sender->MailMsg({
        smtp => 'smtp.163.com',
        from => $opt{from},
        to => $opt{to},
        subject => $subject,
        msg => $msg,
        auth => 'LOGIN',
        authid => $user,
        authpwd => $opt{passwd},
     }) or die "$Mail::Sender::Error\n";}
     print "Mail sent ok\n"; 
} 

sub checkEmail_Format{
     my $email=shift;
     $email=~/[a-zA-Z]\w+\.?\w+\@\w+\.\w+(\.\w+)?/ ? return(1):return(0);
}  
