#!/bin/sh
#------------------------------------------------------------------------------
# Generate SPARQL queries using the collected data statistics.
###############################################################################

# usage message
usage() {
cat << EOF
usage: $0 options

OPTIONS:
   -h      Show this message
   -i      Set input file (gzipped path statistics)
   -n      Number of generated queries
EOF
}


# set default output files
PATHFILE="path-stats.gz";
PREDFILE="predicate-stats.gz";
COUNT=10;

# parse arguments
while getopts "hn:i:" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    i) PATHFILE=$OPTARG ;;
    o) PREDFILE=$OPTARG ;;
    n) COUNT=$OPTARG ;;
  esac
done
shift $(( OPTIND-1 )) # shift consumed arguments

# analyse path stats
# * how many different p1, p2 overall
# * how many different p2 for p1: min/max/mean (and vice versa?)
# * how often occurs p2 in any p1 (distribution)
# * how many different c1, c2 overall
# * how many different c2 for p1: min/max/mean

#gzip -dc btc2011/btc2011-path-statistics.gz | awk '{if ($3 != $4) print $1}' | uniq | wc -l  # fastest
#gzip -dc btc2011/btc2011-path-statistics.gz | perl -lane '{print $F[0] if ($F[2] != $F[3])}' | uniq | wc -l

# create predicate paths
gzip -dc $PATHFILE | perl -slne '
BEGIN {
  # select random p1, c1, p2, c2
  sub select { $ref=@_[0]; return (@_ && ref($ref) eq "HASH") ? map {$_, &select($ref->{$_})} (keys %$ref)[int(rand(keys %$ref))] : () };

#  print STDERR ((join ":", reverse ((localtime(time))[0..2])), " loading path statistics");
  $time = `date +%X`; chomp($time); print STDERR "$time loading path statistics";
} { # load only path statistics of predicates which span sources
  ($p1, $p2, $c1, $c2, @counts) = split;
  @{$stat->{$p1}->{$c1}->{$p2}->{$c2}} = @counts if ($c1 != $c2);
} END {
  $time = `date +%X`; chomp($time); print STDERR "$time generating queries";
  srand(42);  # fixed seed for rand()

  while ($runs--) {
    ($p1, $c1, $p2, $c2) = &select($stat);
    $entities = @{$stat->{$p1}->{$c1}->{$p2}->{$c2}}[0];
    $count2   = @{$stat->{$p1}->{$c1}->{$p2}->{$c2}}[2];

    printf("%5d[%d] - %5d[%2d] : %3d[%2d] - %3d[%d] : %d / %d\n", $p1, scalar @p1_keys, $p2, scalar @p2_keys, $c1, scalar @c1_keys, $c2, scalar @c2_keys, $entities, $count2);
#    print "$p1\[".@p1_keys."] - $p2\[".@p2_keys."]";
  }
}' -- -runs=$COUNT 

echo `date +%X` "done." >&2;
