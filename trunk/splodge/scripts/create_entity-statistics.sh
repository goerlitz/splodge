#!/bin/sh
#------------------------------------------------------------------------------
# Create predicate statistics for incoming and outgoing edges of entitities.
###############################################################################

export LANG=C;

echo "processing $# files..." >&2;
for i in $@; do
  echo `date +%X` ": $i" >&2;
  gzip -dc $i | perl -ne '
  BEGIN {
    # prepare predicate dictionary (predicate -> ID)
    open FILE, "btc2011/btc2011-predicate-dictionary.txt" or die $!;
    while (<FILE>) { chomp; $dict{"<$_>"} = $. }
    close FILE;
  } {
    # count predicates (ID) for incoming and outgoing edges of entities (URI/BNode)
    my ($s, $p, $o, @rest) = split; $p = $dict{$p};
    $edge->{$s}[1]->{$p}++;
    $edge->{$o}[0]->{$p}++ if ($#rest == 1 && $o !~ "^\"");
  } END {
    # print predicate lists (IDs) with predicate frequency for incoming and outgoing edges of each entity
    print ((join " ", $_, map {my $plist=$_; defined $_ ? join ",", map {"$_:$plist->{$_}"} keys %$_ : ""} @{$edge->{$_}})."\n") for (keys %$edge);
  }' \
  | tr -d '<>' | sort >${i%.*}_entity-stats.txt;  # remove URI brackets and save sorted entitity statistics
done
