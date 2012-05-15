#!/bin/sh
#------------------------------------------------------------------------------
# Sort the RDF quads in CSPO order and remove duplicates.
# SPOC quads are reordered to CSPO, sorted, and finally changed back to SPOC.
###############################################################################

export LANG=C sort

echo "processing $# files..." >&2;
for i in $@; do
  echo ": $i" >&2;
  gzip -dc $i
done \
| awk '{tmp=$(--NF); $(NF)="."; print tmp,$_}' \
| sort -u -S 3g -T . --compress-program=gzip \
| awk '{$NF=$1; $1=""; $++NF="."; print }' | sed 's/^ //'
#| awk '{$NF=$1; $1=""; print $0,"."}' | sed 's/^ //'

#| perl -ne '{m/(.*)(<.*?> )(.*)/;print "$2$1$3\n"}'   # slower
#| perl -ane '{@ctx=splice(@F,@F-2,1); unshift(@F,@ctx[0]); print "@F\n"}'   # much slower
