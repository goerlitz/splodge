#!/bin/sh
#------------------------------------------------------------------------------
# Create a mapping to normalize full context URIs to a short data source URI.
###############################################################################

# handle all files from argument list
echo "processing $# files..." >&2;
for i in $@; do
  echo `date +%X` "$i" >&2;

  gzip -dc $i
done \
| awk '{print $(NF-1)}' | awk -F "/" '{print $3}' | perl -lne '
BEGIN {
  $tree = {};
  sub sum { my $ref = shift; my $sum = 0; map {$sum += ($_ ? &sum($ref->{$_}) : $ref->{$_});} keys %$ref; return $sum; };
  sub dom { my $ref = shift; map { my $name = $_; map {$_ ? "$name.$_" : "$name ".sum($ref) } dom($ref->{$_}) if $_; } keys %$ref; };
} {
  # add host parts to domain tree
  my $ref = $tree; 
  map {$ref->{$_} = {} unless $ref->{$_}; $ref = $ref->{$_}} reverse split /\./; 
  $ref->{""}++;
} END {
  print join "\n", "domains:", &dom($tree);
  print "sum: ".&sum($tree);
}'
