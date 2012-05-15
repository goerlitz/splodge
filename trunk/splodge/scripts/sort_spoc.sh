#!/bin/sh
#------------------------------------------------------------------------------
# Sort the RDF quads in SPOC order and remove duplicates.
###############################################################################

export LANG=C sort

echo "processing $# files..." >&2;
for i in $@; do
  echo ": $i" >&2;
  gzip -dc $i
done \
| sort -u -S 3g -T . --compress-program=gzip

