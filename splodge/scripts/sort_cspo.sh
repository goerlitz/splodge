#!/bin/sh
#------------------------------------------------------------------------------
# Sorts the RDF quads in CSPO order and removes duplicates.
# SPOC quads are transformed to CSPO order, sorted, and changed back to SPOC.
###############################################################################

# usage message
usage() {
cat << EOF
usage: $0 options [quad_file.gz [...]]

OPTIONS:
   -h      Show this message
   -o      Set output file (gzipped)
   -s      Set max memory size for sorting
   -t      Set temp dir for sorting
   -z      Enable gzip compression for temp files
EOF
}

export LANG=C;  # speed up sorting

OUTFILE="cspo_sorted.gz";

# parse arguments
while getopts "ho:s:t:z" OPTION; do
  case $OPTION in
    h) usage; exit 1 ;;
    o) OUTFILE=$OPTARG ;;
    s) MEMSIZE="-S $OPTARG" ;;
    t) TEMPDIR=$OPTARG ;;
    z) COMPRESS="--compress-program=gzip" ;;
  esac
done
shift $(( OPTIND-1 )) # shift consumed arguments

# check temp dir settings
if [ ! -z "$TEMPDIR" ]; then
  if [ -e "$TEMPDIR" ] && [ -d "$TEMPDIR" ]; then
    TEMPDIR="-T $TEMPDIR";
  else
    echo "invalid temp directory: $TEMPDIR";
    exit 1;
  fi
fi

# do the sorting
echo "processing $# files..." >&2;
for i in $@; do
  echo `date +%X` "$i" >&2;
  gzip -dc $i
done \
| awk '{tmp=$(--NF); $(NF)="."; print tmp,$_}' \
| sort -u $MEMSIZE $TEMPDIR $COMPRESS \
| awk '{$NF=$1; $1=""; $++NF="."; print }' | sed 's/^ //' \
| gzip >$OUTFILE

#| perl -ne '{m/(.*)(<.*?> )(.*)/;print "$2$1$3\n"}'   # slower
#| perl -ane '{@ctx=splice(@F,@F-2,1); unshift(@F,@ctx[0]); print "@F\n"}'   # much slower
