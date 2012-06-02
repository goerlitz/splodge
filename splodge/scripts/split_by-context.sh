#!/bin/sh
#-------------------------------------------------------------------------
# Splitting quads by context and writing spo triples.
# Input must be sorted by context - will not be checked.
##########################################################################


# handle all files from argument list
echo "processing $# files..." >&2;
for i in $@; do

  echo `date +%X` "$i" >&2;
  gzip -dc $i | perl -lne '
  BEGIN {
    $dir = "btc-split";
  } {
    my ($dot, $ctx, @ops) = reverse split;
    my $host = (split /\//, $ctx)[2];
    if ($ctx ne "$last_ctx") {
      close FILE if ($last_ctx);
      open FILE, "| gzip >>$dir/$host.nt.gz" or die "ERROR: cannot save file $dir/$host.nt: $!";
      $last_ctx = $ctx;
      print STDERR "next context: $ctx $.";
    }
    print FILE join " ", reverse $dot, @ops;
  } END {
    close FILE;
  }'
done
