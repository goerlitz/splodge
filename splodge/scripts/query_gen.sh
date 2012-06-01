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
   -p      Set predicate dictionary file (one predicate URI per line)
   -s      Set predicate statistics file (one predicate stat per line)
EOF
}


# set default output files
PATHFILE="path-stats.gz";
PREDFILE="predicate-stats.gz";
COUNT=10;

# parse arguments
while getopts "hn:i:p:s:" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    i) PATHFILE=$OPTARG ;;
    p) PDICT=$OPTARG ;;
    s) PSTAT=$OPTARG ;;
    n) COUNT=$OPTARG ;;
  esac
done
shift $(( OPTIND-1 )) # shift consumed arguments

# check dictionary settings
if [ -z "$PDICT" ]; then
  echo "WARNING: a predicate dictionary must be supplied (use -p flag, or -h for help).";
  exit 1;
fi
if [ -z "$PSTAT" ]; then
  echo "WARNING: apredicate statistics must be supplied (use -s flag, or -h for help).";
  exit 1;
fi

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
  # choose p1, c1, p2, c2 randomly (recursive traversal of hash)
  sub choose { my $ref=@_[0]; return (@_ && ref($ref) eq "HASH") ? map {$_, &choose($ref->{$_})} (keys %$ref)[int(rand(keys %$ref))] : () }

  # prepare predicate dictionary (ID -> predicate)
  open FILE, "'"$PDICT"'" or die "ERROR: cannot load dictionary '"$PDICT"': $!";
  while (<FILE>) { chomp; $pindex{"$."} = "<$_>"}
  close FILE;
  # prepare predicate statistics (predicate -> ID, stats)
  open FILE, "'"$PSTAT"'" or die "ERROR: cannot load statistics '"$PSTAT"': $!";
  while (<FILE>) { chomp; ($p, $c, $s, $stats) = split; for (split /,/, $stats) { my ($ctx, $n) = split /:/; $pstats->{$p}->{$ctx}=$n }}
  close FILE;

  $time = `date +%X`; chomp($time); print STDERR "$time loading path statistics";
} { # load only path statistics of predicates which span sources
  ($p1, $p2, $c1, $c2, @counts) = split;
  @{$stat->{$p1}->{$c1}->{$p2}->{$c2}} = @counts if ($c1 != $c2);
} END {
  $time = `date +%X`; chomp($time); print STDERR "$time generating queries";
  srand(42);  # fixed seed for rand()

  while ($runs--) {
    my ($p1, $c1, $p2, $c2) = &choose($stat);
    my $ref = $stat->{$p1}->{$c1}->{$p2}->{$c2};

    if ($stat->{$p2} && $stat->{$p2}->{$c2}) {
      my ($p3, $c3) = &choose($stat->{$p2}->{$c2});
      redo if ($c1 == $c3);
      # are there different sources to reach p3@c3 from p1@c1 via p2?

      printf("%5d<%3d> - %5d<%3d> - %5d<%3d> : %d / %d / %d\n", $p1, $c1, $p2, $c2, $p3, $c3, $pstats->{$p2}->{$c2}, $ref->[2], $stat->{$p2}->{$c2}->{$p3}->{$c3}[1]);
      printf("SELECT * WHERE {\n  ?var1 %s ?var2 .\n  ?var2 %s ?var3 .\n  ?var3 %s ?var4 .\n}\n", map {$pindex{$_}} $p1, $p2, $p3);
    } else {
      redo;
    }
  }
}' -- -runs=$COUNT 

echo `date +%X` "done." >&2;
