#!/bin/bash

cd ~/x/rss

test $2 == 'web' && {
	export FETCH_FROM_WEB=1
} || {
	cat > html/${1}.html
}

SCRAP_TARGET=$1 jupyter nbconvert --to notebook --execute scrap-blogs.ipynb

cat feeds/${1}.xml