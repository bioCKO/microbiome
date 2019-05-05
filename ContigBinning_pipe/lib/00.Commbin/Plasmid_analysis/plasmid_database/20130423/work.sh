#-- download database from ftp
tar xzvf  plasmids.all.fna.tar.gz
cat am/ftp-genomes/Plasmids/fna/*.fna > plasmid20130423.fa
formatdb -i plasmid20130423.fa  -p F
gzip plasmid20130423.fa
rm -r am/ plasmids.all.fna.tar.gz
