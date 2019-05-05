#!/usr/bin/perl
(@ARGV>=3) || die"perl $0 <depth.list> <ori.fna> <split.fa> [split.info] [split.subid.record]>chimeraSplit_check.info\n";
#[split.info]: ori id and chimera subid.
#[split.subid.record]: split behind these ori subids.
#chimeraSplit_check.info: split related ori subids.
my (%hash, %hash2);
open (IN, "$ARGV[0]");
<IN>;
while(<IN>){
    chomp;
    my ($id, $len, $dep1, $dep2) = (split/\s+/, $_)[1,3,-2,-1];
    if($id =~ /(.*)\_\_([0-9]+)$/){
        my $ori_id = $1;
        my $rank = $2;  #get subid;
        push @{$hash{$ori_id}{$rank}}, ($dep1, $len);  #save dep and len of every subid;
        push @{$hash2{$ori_id}{$rank}}, ($dep2, $len);
    }
}
close IN;

my %cut_point;
foreach my $id(keys %hash){ #iterate every id
    my @ranks = keys %{$hash{$id}};
    @ranks = sort { $a <=> $b } @ranks;
    if($#ranks>0){
        foreach my $r (0..$#ranks-1){  # iterate every subid and compare its dep difference with its next subid.
            my $abs = abs(${$hash{$id}{$ranks[$r]}}[0]-${$hash{$id}{$ranks[$r+1]}}[0]);
            my $min = &min(${$hash{$id}{$ranks[$r]}}[0], ${$hash{$id}{$ranks[$r+1]}}[0]);
            if($min == 0){ $min += 0.0001;}
            if($abs/$min>=0.75){
                push @{$cut_point{$id}}, [$ranks[$r], ${$hash{$id}{$ranks[$r]}}[1]]; #if the dep diffrence is significant, save the index and length of the former subid. 
            }
         }    
    }  
}
foreach my $id(keys %hash2){ #iterate every id
    my @ranks = keys %{$hash2{$id}};
    @ranks = sort { $a <=> $b } @ranks;
    if($#ranks>0){
        foreach my $r (0..$#ranks-1){  # iterate every subid and compare its dep difference with its next subid.
            my $abs = abs(${$hash2{$id}{$ranks[$r]}}[0]-${$hash2{$id}{$ranks[$r+1]}}[0]);
            my $min = &min(${$hash2{$id}{$ranks[$r]}}[0], ${$hash2{$id}{$ranks[$r+1]}}[0]);
            if($min == 0){ $min += 0.0001;}
            if($abs/$min>=0.75){
                push @{$cut_point{$id}}, [$ranks[$r], ${$hash2{$id}{$ranks[$r]}}[1]]; #if the dep diffrence is significant, save the index and length of the former subid. 
            }
         }    
    }  
}

foreach my $id(keys %cut_point){
    my @ranks = @{$cut_point{$id}};
    my (%h_subid,@new_ranks);
    foreach my $i(0..$#ranks){
        if(not exists $h_subid{${$ranks[$i]}[0]}){
            $h_subid{${$ranks[$i]}[0]} = 1; 
            push @new_ranks, [${$ranks[$i]}[0], ${$ranks[$i]}[1]];
        }
        else{
            next;
        }
    }
    @new_ranks = sort {$a->[0] <=> $b->[0]} @new_ranks;
    @{$cut_point{$id}} = @new_ranks;
#if($#ranks ne $#new_ranks){print $id."\t".$#ranks."\t"."$#new_ranks"."\t".${$new_ranks[0]}[0]."\t".${$new_ranks[0]}[1]."\t".${$new_ranks[1]}[0]."\t".${$new_ranks[1]}[1]."\n";exit;}
}

open (IN, "$ARGV[1]");
$/ = ">";<IN>;$/="\n";
open O, ">$ARGV[2]";
open O2, ">$ARGV[3]";
open O3, ">$ARGV[4]";
print O2 "ORI_ID\tSplit_ID\tLength_ori\tLength_split\tStart\tEnd\n";
while(<IN>){
    /(^(\S+))/ || next;
    my $id = $1;
    $/=">"; chomp(my $seq = <IN>); $/="\n";
    $seq =~ s/\s+//g;
    my $len = length($seq);
    if(not exists $cut_point{$id}){
        print O ">$id\n$seq\n";
        my $len = length $seq;
        my $end = $len-1; 
        print O2 "$id\t$id\t$len\t$len\t1\t$len\n";
    }else{
        my $len = length $seq;
        my @cutid_info = @{$cut_point{$id}};#get the index and length info of the subid from which the contig shoubld be split.
        my $suffix = 0;
        foreach my $n (0..$#cutid_info){
                if($n != 0){
                    $suffix++;
                    my $sub_id = $id."__".$suffix;
                    my $sub_id_index = ${$cutid_info[$n]}[0];
                    my $sub_id_previous_index = ${$cutid_info[$n-1]}[0];
                    my $cut_len;
                    foreach($sub_id_previous_index..$sub_id_index-1){
                        my $r = $_+1;
                        if(exists $hash{$id}{$r}){
                            $cut_len += ${$hash{$id}{$r}}[1];
                        }elsif(exists $hash2{$id}{$r}){
                            $cut_len += ${$hash2{$id}{$r}}[1];
                        }
                    }
#my $cut_len = ${$cutid_info[$n]}[1]*($sub_id_index-$sub_id_previous_index);
                    my $cut_pos;
                    foreach(1..$sub_id_previous_index){
                        my $r = $_;
                        if(exists $hash{$id}{$r}){
                            $cut_pos += ${$hash{$id}{$r}}[1];
                        }elsif(exists $hash2{$id}{$r}){
                            $cut_pos += ${$hash2{$id}{$r}}[1];
                        }
                    }
                    my $start_pos = $cut_pos+1;
#my $cut_pos = $sub_id_previous_index*${$cutid_info[$n-1]}[1]; my $start_pos = $cut_pos+1; #the start split position
                    my $end = $cut_pos+$cut_len-1; my $end_pos = $end+1;
                    my $sub_seq = substr($seq,$cut_pos,$cut_len); #  ${$cutid_info[$n]}[1] refer to length of the subid.
                    my $sub_len = length $sub_seq;
                    print O ">$sub_id\n$sub_seq\n";
                    print O2 "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                    print O3 "$id\_\_$sub_id_index\n";
                    print "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                }elsif($n == 0){
                    $suffix++;
                    my $sub_id = $id."__".$suffix;
                    my $sub_id_index = ${$cutid_info[$n]}[0];
                    my $cut_len;
                    foreach(1..$sub_id_index){
                        my $r = $_;
                        if(exists $hash{$id}{$r}){
                            $cut_len += ${$hash{$id}{$r}}[1];
                        }elsif(exists $hash2{$id}{$r}){
                            $cut_len += ${$hash2{$id}{$r}}[1];
                        }
                    }
                    my $cut_pos = 0; my $start_pos = $cut_pos+1; #the start split position
                    my $end = $cut_pos+$cut_len-1; my $end_pos = $end+1;
                    my $sub_seq = substr($seq,$cut_pos,$cut_len); #  ${$cutid_info[$n]}[1] refer to length of the subid.
                    my $sub_len = length $sub_seq;
                    print O ">$sub_id\n$sub_seq\n";
                    print O2 "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                    print O3 "$id\_\_$sub_id_index\n";
                    print "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                }
                if($n == $#cutid_info){
                    $suffix++;
                    my $sub_id = $id."__".$suffix; 
#my $cut_pos  = ${$cutid_info[$#cutid_info]}[0]*${$cutid_info[$cutid_info]}[1];
                    my $sub_id_index = ${$cutid_info[$n]}[0];
                    my $cut_pos;
                    foreach(1..$sub_id_index){
                        my $r = $_;
                        if(exists $hash{$id}{$r}){
                            $cut_pos += ${$hash{$id}{$r}}[1];
                        }elsif(exists $hash2{$id}{$r}){
                            $cut_pos += ${$hash2{$id}{$r}}[1];
                        }
                    }
                    my $start_pos = $cut_pos+1;
                    my $sub_seq = substr($seq, $cut_pos, $len-$cut_pos+1);
                    my $end = $len-1; my $end_pos = $end+1;
                    my $sub_len = length $sub_seq; 
                    print O ">$sub_id\n$sub_seq\n";
                    print O2 "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                    print "$id\t$sub_id\t$len\t$sub_len\t$start_pos\t$end_pos\n";
                }
        }
    }
}
close IN;

sub min(){
    my $n1 = shift;
    my $n2 = shift;
    my $n = ($n1<=$n2)?$n1:$n2;
}
