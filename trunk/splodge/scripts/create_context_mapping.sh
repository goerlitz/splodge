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
  sub sum { my $ref = shift; my $sum = 0; $sum += ($_ ? &sum($ref->{$_}) : $ref->{$_}) for (keys %$ref); return $sum };
  sub dom { my $ref = shift; return map { my $name = $_; map { $_ ? "$_.$name" : $name } dom($ref->{$_}) if $_ } keys %$ref };
  sub aggr {
    my ($ref, @names) = @_; 
    my @keys = keys %$ref;

#    if (@keys > 1 && @names > 1 && (@names > 2 || $names[0] ne "au" && $names[0] ne "uk" && $names[0] ne "jp")) {
    if (@keys > 1 && @names > 1 && (@names > 2 || $names[0] !~ /^(au|uk|jp)$/)) {
      print sum($ref)," ",(join ".", reverse @names)," ",join ",", dom($ref);
    } else {
      for (@keys) {
        if ($_) {
          aggr($ref->{$_}, @names, $_);
        } else {
          print sum($ref)," ",join ".", reverse @names;
        }
      }
    }
  }
} {
  # add host parts to domain name tree
  my $ref = $tree; 
  map {$ref->{$_} = {} unless $ref->{$_}; $ref = $ref->{$_}} reverse split /\./; 
  $ref->{""}++;
} END {
  aggr($tree);
}' \
| sort -nr >context-stats.txt

