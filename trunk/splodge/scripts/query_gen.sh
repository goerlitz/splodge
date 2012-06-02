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
   -n      Number of queries to generate
   -p      Set predicate dictionary file (one predicate URI per line)
   -s      Set predicate statistics file (one predicate stat per line)
EOF
}


# set default output files
PATHFILE="path-stats.gz";
PSTAT="predicate-stats.gz";
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
  echo "WARNING: a predicate list must be supplied (use -p flag, or -h for help).";
  exit 1;
fi
if [ -z "$PSTAT" ]; then
  echo "WARNING: predicate statistics must be supplied (use -s flag, or -h for help).";
  exit 1;
fi


# query generation.
perl -sle '
  # DEFINE FUNCTIONS

  # choose p1, c1, p2, c2 randomly (recursive traversal of stats in hash tree)
  sub choose { my $ref=@_[0]; return (@_ && ref($ref) eq "HASH") ? map {$_, &choose($ref->{$_})} (keys %$ref)[int(rand(keys %$ref))] : () }

  # INITIALIZE STATISTICS
  $time = `date +%X`; chomp($time); print STDERR "$time loading predicate and path statistics";

  # prepare predicate dictionary (ID -> predicate)
  open FILE, "'"$PDICT"'" or die "ERROR: cannot load predicate list '"$PDICT"': $!";
  while (<FILE>) { chomp; $pindex{"$."} = "<$_>" }
  close FILE;
  # prepare predicate statistics (predicate -> ID, stats)
  open FILE, "gzip -dc '"$PSTAT"'|" or die "ERROR: cannot load predicate statistics '"$PSTAT"': $!";
  while (<FILE>) { chomp; ($p, $c, $s, $stats) = split; for (split /,/, $stats) { my ($ctx, $n) = split /:/; $pstats->{$p}->{$ctx}=$n } }
  close FILE;
  # prepare predicate statistics (predicate -> ID, stats)
  open FILE, "gzip -dc '"$PATHFILE"'|" or die "ERROR: cannot load path statistics '"$PATHFILE"': $!";
  while (<FILE>) { chomp; ($p1, $p2, $c1, $c2, @counts) = split; @{$stat->{$p1}->{$c1}->{$p2}->{$c2}} = @counts if ($c1 != $c2); }
  close FILE;

  # GENERATE QUERIES

  $time = `date +%X`; chomp($time); print STDERR "$time generating queries";
  srand(42);  # fixed seed for rand()

  while ($runs--) {
    my ($p1, $c1, $p2, $c2) = &choose($stat);
    my $ref = $stat->{$p1}->{$c1}->{$p2}->{$c2};

    # check if current path pattern connected with another pattern spans three sources, otherwise retry
    # ToDo: prevent endless loop if not possible
    # ToCheck: are there different possible intermediate sources to connect p1@c1 with p3@c3 via p2?
    if ($stat->{$p2} && $stat->{$p2}->{$c2}) {
      my ($p3, $c3) = &choose($stat->{$p2}->{$c2});
      redo if ($c1 == $c3);

      # print SPARQL query
      printf("SELECT * WHERE {\n  ?var1 %s ?var2 .\n  ?var2 %s ?var3 .\n  ?var3 %s ?var4 .\n}\n", map {$pindex{$_}} $p1, $p2, $p3);

      # print path with pattern counts
#      printf("%5d<%3d> - %5d<%3d> - %5d<%3d> : %d / %d / %d\n", $p1, $c1, $p2, $c2, $p3, $c3, $pstats->{$p2}->{$c2}, $ref->[2], $stat->{$p2}->{$c2}->{$p3}->{$c3}[1]);
    } else {
      redo;
    }
  }
' -- -runs=$COUNT 

echo `date +%X` "done." >&2;
