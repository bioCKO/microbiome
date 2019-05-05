#-- download database from ftp
wget ftp://ftp.ncbi.nih.gov/genomes/Plasmids/plasmids.all.fna.tar.gz

tar xzvf  plasmids.all.fna.tar.gz
cat am/ftp-genomes/Plasmids/fna/*.fna > plasmid20131219.fa
formatdb -i plasmid20131219.fa  -p F
gzip plasmid20131219.fa
rm -r am/ plasmids.all.fna.tar.gz
