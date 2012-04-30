#!/bin/sh
#------------------------------------------------------------------------------
# Update all context URIs of RDF quads with shortened (reduced) URIs.
#   e.g. {jane,john}.livejournal.com -> livejournal.com.
###############################################################################

echo "processing $# files..." >&2;
path=${0%/*};

for i in $@; do
  out=${i%.*}"_reduced-uris."${i##*.};
  echo "updating: $i -> $out" >&2;
  gzip -dc $i | $path/substitute-context-uri.pl $path/../btc2011-ctx-host-mappings.txt | gzip >$out;
done
