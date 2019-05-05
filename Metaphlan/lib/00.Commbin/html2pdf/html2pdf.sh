#!/bin/bash

# description: convert html to pdf
# author: Zhang Fangxian, zhangfx@genomics.cn
# created date: 20100504
# modified date: 20100510, 20100507

if [ $# -ne 2 ]; then
	echo "usage: $0 html pdf" >&2
	exit 1
fi

path=`dirname $0`

# install font
if [ ! -f ~/.fonts/wqy-microhei.ttc ]; then
	wqy=$path/`ls -1 $path | grep wqy-microhei | tail -n 1`

	echo installing wqy font...
	if [ ! -d ~/.fonts ]; then
		mkdir ~/.fonts
	fi
	tar zxf $wqy
	cp wqy-microhei/*.ttc  ~/.fonts
	rm -rf wqy-microhei
fi

# convert html to pdf
$path/wkhtmltopdf-amd64 --quiet --disable-internal-links --disable-external-links --print-media-type -O Landscape --footer-center '[page]/[toPage]' -T 5mm -R 5mm -B 5mm -L 5mm $1 $2

exit 0
