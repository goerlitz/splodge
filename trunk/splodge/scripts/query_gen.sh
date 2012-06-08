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
while getopts "hn:i:c:p:s:" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    i) PATHFILE=$OPTARG ;;
    c) CDICT=$OPTARG ;;
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
  sub print_path_as_id_list { print join " -> ", map {join ":", @$_} @_ }
  sub print_path_as_sparql { $v=1; printf "SELECT * WHERE { %s }\n", join " . ", map {"?var$v ".$pindex{@$_[0]}." ?var".++$v} @_ }
  sub print_path_for_mysql { $v=1; print join ";;", map {"?var$v\$\$".$pindex{@$_[0]}."\$\$?var".++$v."§§".$cindex{@$_[1]}} @_ }

  sub create_path_join {
    my ($num_pattern, $num_sources) = @_;
    my @path = ();

    die "path-join must have at least two patterns" if $num_pattern < 2;
    die "path-join must have at least two sources" if $num_sources < 2;
    die "path-join cannot have more sources than patterns" if $num_sources > $num_pattern;
    
    while (@path < $num_pattern) {
      if (@path == 0) {
        my ($p1, $c1, $p2, $c2) = &choose($stat);
        @path = ([$p1, $c1], [$p2, $c2]);
        next;
      }

      my ($p, $c) = @{$path[-1]};
      if ($stat->{$p} && $stat->{$p}->{$c}) {
        push @path, [&choose($stat->{$p}->{$c})];
      } else {
        @path = (); # no combination available, retry
      }

      # check number of sources
      # ToDo: prevent endless loops for impossible query parameters
      %sources = map { (@$_[1], 1) } @path;
      @path = () if (keys %sources < @path); # not enough sources included, retry
    }

    # ToCheck: are there different possible intermediate sources to connect p1@c1 with p3@c3 via p2?
    return @path;
  }

  # INITIALIZE STATISTICS
  $time = `date +%X`; chomp($time); print STDERR "$time loading predicate and path statistics";

  # prepare predicate dictionary (ID -> predicate)
  open FILE, "'"$CDICT"'" or die "ERROR: cannot load context list '"$CDICT"': $!";
  while (<FILE>) { chomp; $cindex{"$."} = "<$_>" }
  close FILE;
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
#    &print_path_as_id_list(&create_path_join(4,2));
    &print_path_as_sparql(&create_path_join(4,2));
#    &print_path_for_mysql(&create_path_join(4,2));
  }

#      my ($p1c1size, $p2c2size, $p3c3size) = ($pstats->{$p1}->{$c1}, $pstats->{$p2}->{$c2}, $pstats->{$p3}->{$c3});  # number all triples for predicate in context
#      my ($p1c1path, $p2c2path1, $p2c2path2, $p3c3path) = (@$ref[1..2], @{$stat->{$p2}->{$c2}->{$p3}->{$c3}}[1..2]); # number path triples for predicate in context

#      # print SPARQL query
#      $triples=$p2c2path1*$p2c2path2/$p2c2size;
#      printf("# join size: %d [of %d] * %d|%d [of %d] * %d [of %d] triples\n", $p1c1path, $p1c1size, $p2c2path1, $p2c2path2, $p2c2size, $p3c3path, $p3c3size);
#      printf("%f (%d/%d * %d/%d) %f %s -> %s -> %s\n", ($triples/$p2c2size), $p2c2path1, $p2c2size, $p2c2path2, $p2c2size, $triples, map {$pindex{$_}} $p1, $p2, $p3);
' -- -runs=$COUNT 

echo `date +%X` "done." >&2;
