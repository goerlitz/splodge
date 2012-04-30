#!/bin/sh
#------------------------------------------------------------------------------
# Count the number of occurences of predicates in RDF triples/quads.
###############################################################################

echo "processing $# files..." >&2;
path=${0%/*};

for i in $@; do
  gzip -dc $i;
done \
| awk '{print $(NF-1)}' | awk -F "/" '{print $3}' \
| $path/compute_reduced-host-mapping.pl | sort -rn
