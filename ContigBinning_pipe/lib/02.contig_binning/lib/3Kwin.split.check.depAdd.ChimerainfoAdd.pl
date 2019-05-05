#!usr/bin/perl
(@ARGV>=2) || die"perl $0 <chimeraSplit_check.info> <3Kwin.split.check.depAdd.info>\n";

open (F, "$ARGV[0]");
my %chimera_id;
while(<F>){
    chomp;
    my $subid = (split/\t/, $_)[0];
    $chimera_id{$subid}=1;
}
close F;

open (F, "$ARGV[1]");
my $head = <F>; $head =~ s/\n//g; print $head."\tChimera mark\n"; 
while(<F>){
    chomp;
    my $subid = (split/\t/, $_)[1];
    if(exists $chimera_id{$subid}){
        print "$_\t\*\n";
    }else{
        print "$_\t \n";
    }
}
close F;
