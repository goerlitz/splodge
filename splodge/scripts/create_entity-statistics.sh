#!/bin/sh
#------------------------------------------------------------------------------
# Create entity statistics for incoming and outgoing edges (predicate counts).
# PARAMS: list of gziped input files.
# OUTPUT: statistics file for each input file (<filename>_entity-stats.txt).
###############################################################################

# usage message
usage() {
cat << EOF
usage: $0 options

OPTIONS:
   -h      Show this message
   -o      Set output file
   -p      Set predicate dictionary file
   -s      Set source dictionary file
   -t      Set temp dir (for sort)
EOF
}

export LANG=C;  # speed up sorting

STATFILE="entity-stats.gz";

# parse arguments
while getopts "ho:p:s:t:" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    o) STATFILE=$OPTARG ;;
    p) PDICT=$OPTARG ;;
    s) SDICT=$OPTARG ;;
    t) TMP=$OPTARG ;;
  esac
done
shift $(( OPTIND-1 )) # shift consumed arguments

# check dictionary settings
if [ -z "$PDICT" ]; then
  echo "WARNING: a predicate dictionary must be supplied (use -p flag, or -h for help).";
  exit 1;
fi
if [ -z "$SDICT" ]; then
  echo "WARNING: a source dictionary must be supplied (use -s flag, or -h for help).";
  exit 1;
fi
# check temp dir settings
if [ ! -z "$TMP" ]; then
  if [ -e "$TMP" ] && [ -d "$TMP" ]; then
    TMP="-T $TMP";
  else
    echo "invalid temp directory: $TMP";
    exit 1;
  fi
fi


# handle all files from argument list
echo "processing $# files..." >&2;
for i in $@; do

  outfile=${i%.*}_entity-stats.txt;
  statfiles=$statfiles" "$outfile;

  # check if stat file already exists
  if [ -e $outfile ] && [ $(stat -c%s "$outfile") -gt "0" ]; then
    echo "skipped '$i': stat file already exists.";
    continue;
  fi

  # create entity statistics for current chunk
  echo `date +%X` "$i" >&2;
  gzip -dc $i | perl -ne '
  BEGIN {
    # prepare predicate dictionary (predicate -> ID)
    open FILE, "'"$PDICT"'" or die "error loading dictionary '"$PDICT"': $!";
    while (<FILE>) { chomp; $pdict{"<$_>"} = $. }
    close FILE;
    open FILE, "'"$SDICT"'" or die "error loading dictionary '"$SDICT"': $!";
    while (<FILE>) { chomp; $sdict{"$_"} = $. }
    close FILE;
  } {
    # count predicates (ID) for incoming and outgoing edges of entities (URI/BNode)
    my ($s, $p, $o, @rest) = split; $p = $pdict{$p};
    $rest[$#rest-1] =~ m|//(.*)/|; $ctx = $sdict{$1};
    $stat->{$s}[1]->{$p}->{$ctx}++;
    $stat->{$o}[0]->{$p}->{$ctx}++ if ($#rest == 1 && $o !~ "^\"");
  } END {
    # print predicate lists (IDs) with predicate frequency for incoming and outgoing edges of each entity
    # serialization of entity->predicate->context->count
    print ((join " ", $_, map {my $pmap=$_; defined $_ ? join ",", map {my $p=$_; map {"$p:$_:$pmap->{$p}->{$_}"} keys %{$pmap->{$p}}} sort keys %$_ : ""} @{$stat->{$_}})."\n") for (keys %$stat);
  }' \
  | tr -d '<>' | sort $TMP >$outfile;  # remove URI brackets and save sorted entitity statistics
done


# aggregate statistic files and merge duplicates
echo `date +%X` "merging entity statistics" >&2;

# check if stat file already exists
if [ -e $STATFILE ] && [ $(stat -c%s "$STATFILE") -gt "0" ]; then
  echo "skipped merging: '$STATFILE' already exists.";
else
  sort -m $TMP $statfiles | perl -ne '{
    chomp; ($uri, @stat) = split /[ ]/;
    if ($last_uri ne $uri) {
      print "$last_uri @last_stat\n" if ($last_uri);
      ($last_uri, @last_stat) = ($uri, @stat);
      next;
    }
    map {map {($p, $ctx, $val) = split /:/; $data[$idx]->{$p}->{$ctx}+=$val;} split /,/; $idx = ++$idx&1; } @stat[0..1], @last_stat[0..1];
    # serialization of entity->predicate->context->count
    @last_stat = map {my $pmap=$_; defined $_ ? join ",", map {my $p=$_; map {"$p:$_:$pmap->{$p}->{$_}"} keys %{$pmap->{$p}}} sort keys %$_ : ""} @data;  # sort { $a <=> $b } is slower
    @data = ();
  } END {
    print "$last_uri @last_stat\n";
  }' | gzip >$STATFILE

  echo `date +%X` "done. entity statistics written to $STATFILE" >&2;
fi

