#!/bin/sh
#------------------------------------------------------------------------------
# Aggregate domains with multiple subdomains, e.g. {bob,jane}.livejournal.com.
# 1. step: collect statistics: frequency, domain name, and list of subdomains.
# 2. step: condense quad context to common domain names.
###############################################################################

# set default statistic file
STATFILE="context-stats.txt";

# handle all files from argument list
echo "processing $# files..." >&2;

# check if output statistic file already exists
if [ -e $STATFILE ] && [ $(stat -c%s "$STATFILE") -gt "0" ]; then
  echo "skipped analysis: '$STATFILE' already exists.";
else
  for i in $@; do
    echo `date +%X` "$i" >&2;
    gzip -dc $i
  done \
  | awk '{print $(NF-1)}' | awk -F "/" '{print $3}' | perl -lne '
BEGIN {
  $tree = {};
  sub sum { my $ref = shift; my $sum = 0; $sum += ($_ ? &sum($ref->{$_}) : $ref->{$_}) for (keys %$ref); return $sum };
  sub dom { my $ref = shift; return map { my $name = $_; map { $_ ? "$_.$name" : $name } dom($ref->{$_}) if $_ } keys %$ref };
  sub aggregate {
    my ($ref, @names) = @_; 
    my @keys = keys %$ref;

    if (@keys > 1 && @names > 1 && (@names > 2 || $names[0] !~ /^(au|uk|jp)$/)) {
      # aggregate domains which have multiple subdomains
      print sum($ref)," ",(join ".", reverse @names)," ",join ",", dom($ref);
    } else {
      # process all subdomains recursively or print details of fully traversed domain name
      for (@keys) { $_ ? aggregate($ref->{$_}, @names, $_) : print sum($ref)," ",join ".", reverse @names }
    }
  }
} {
  # add host parts to domain name tree
  my $ref = $tree; 
  map {$ref->{$_} = {} unless $ref->{$_}; $ref = $ref->{$_}} reverse split /\./; 
  $ref->{""}++;
} END {
  aggregate($tree);
}' \
  | sort -nr >$STATFILE
  echo `date +%X` "done. context statistics written to $STATFILE" >&2;
fi

# replace quad context with condensed context
# handle all files from argument list
for i in $@; do
  out=${i%.*}"_condensed-uris."${i##*.};
  echo `date +%X` "updating: $i -> $out" >&2;
  gzip -dc $i | perl -lne '
  BEGIN {
    # prepare predicate dictionary (predicate -> ID)
    open FILE, "'"$STATFILE"'" or die "error loading dictionary '"$STATFILE"': $!";
    while (<FILE>) {
      chomp;
      my ($count, $host, $subdomains) = split;
      if ($subdomains) {$dict{"$_.$host"} = $host for (split /,/, $subdomains)};
    }
    close FILE;
  } {
    my ($first, $host) = m!(.*<.*?//)(.*?)/!;
    print "$first".(exists($dict{$host}) ? $dict{$host} : $host)."/> .";
  }' | gzip >$out;
done
echo `date +%X` "done. all contexts updated." >&2;
