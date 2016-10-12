numLines=$1
wordsPerLine=$2
fileName=$3
ruby -e "a=STDIN.readlines;$numLines.times do;b=[];$wordsPerLine.times do; b << a[rand(a.size)].chomp end; puts b.join(' '); end" < /usr/share/dict/words > $fileName
