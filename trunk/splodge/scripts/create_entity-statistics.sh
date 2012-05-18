#!/bin/sh
#------------------------------------------------------------------------------
# Create entity statistics for incoming and outgoing edges (predicate count).
# PARAMS: list of gziped input files.
# RESULT: statistics file for each input file (<filename>_entity-stats.txt).
###############################################################################

export LANG=C;  # speed up sorting

# usage message
usage() {
cat << EOF
usage: $0 options

OPTIONS:
   -h      Show this message
   -d      Set predicate dictionary file
EOF
}

# parse arguments
while getopts "hd:" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    d) DICT=$OPTARG ;;
  esac
done

# shift arguments by number of consumed options
shift $(( OPTIND-1 ))

# check settings
if [ -z "$DICT" ]; then
  echo "WARNING: a predicate dictionary must be supplied (-d flag).";
  exit 1;
fi

# handle all files from argument list
echo "processing $# files..." >&2;
for i in $@; do

  outfile=${i%.*}_entity-stats.txt;
  statfiles=$statfiles" "$outfile;

  # check if stat file already exists
  if [ -e $outfile ]; then
    echo "skip: '$i' has already been processed.";
    continue;
  fi

  # create entity statistics for current chunk
  echo `date +%X` "$i" >&2;
  gzip -dc $i | perl -ne '
  BEGIN {
    # prepare predicate dictionary (predicate -> ID)
    open FILE, "'"$DICT"'" or die "error loading dictionary: $!";
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
  | tr -d '<>' | sort >$outfile;  # remove URI brackets and save sorted entitity statistics
done

# merge generated statistic files
#echo "files: '$statfiles'";
sort -m $statfiles | gzip >entity-stats.gz
