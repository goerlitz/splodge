#!/bin/sh
#------------------------------------------------------------------------------
# Count the number of occurences of raw contexts in RDF quads.
###############################################################################

echo "processing $# files..." >&2;

for i in $@; do
  echo ": $i" >&2;
  gzip -dc $i;
done \
| awk '{print $(NF-1)}' | awk -F "/" '{c[$3]++} END {for(i in c) print c[i],i}' | sort -rn
#| awk '{print $(NF-1)}' | awk -F "/" '{print $3}' | perl -ne '{$c{$_}++} END {print "$c[$_] $_" for keys %c}' | sort -rn
#| awk '{print $(NF-1)}' | perl -ne '{$c{(split /\//)[2]}++} END {print "$c[$_] $_\n" for keys %c}' | sort -rn
#| awk '{split($(NF-1),a,"/"); c[a[3]]++} END {for(i in c) print c[i],i}' | sort -rn   # 4 times slower
