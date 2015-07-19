# Overview #

SPLODGE allows for systematic generation of SPARQL benchmark queries for Linked Open Data, i.e. the generated queries are ideal for benchmarking RDF federation systems.

# Howto #

The generation process consists of two steps.
  1. pre-processing and computing statistics
  1. query generation

In order to run the query generation for the BTC 2011 dataset, just download the [pre-processed data](https://github.com/goerlitz/splodge/releases/download/ISWC-2012/btc2011_pre-processed.zip) from the download section, unzip it, unzip the included context-list.gz and predicate-list.gz, and run query-gen.sh like this:

```
scripts/query_gen.sh -c context-list -p predicate-list
```

For more options of the script type -h.

Other datasets can be used as well. All necessary pre-processing steps need to be performed with a set of shell scripts. They should generally work for any gzipped N-Quad input files.

Following steps are required in the given order:

```
# download N-Quad files, e.g.
wget http://km.aifb.kit.edu/projects/btc-2012/datahub/data-1.nq.gz

# replace context with common domain
./create_context_mapping.sh *.nq.gz
rm context-statistics.txt

# sort quads and remove duplicates
./sort_quads.sh *.nq_condensed-ctx.gz
rm *.nq_condensed-ctx.gz

# create dictionary for predicates and context
./count_predicates.sh sorted_spoc.gz | cut -d" " -f2 >pdict
./count_context-raw.sh sorted_spoc.gz | cut -d" " -f2 >cdict

# create link statistics for entities
./create_entity-statistics.sh -p pdict -c cdict sorted_spoc.gz
rm *.txt

# create statistics for each predicate
./create_predicate-statistics.sh

# create statistics for predicate paths
./create_path-statistics.sh

# generate queries (type -h for help)
./query_gen.sh -c cdict -p pdict
```

# Status #

The provided implementation of the query generator does not include all features described in the ISWC paper. Due to limited resources and a lack of time, it currently only supports path queries where each triple pattern has to be matched by a different data source. This type of queries is most challenging for query processing and query generation. Hence, the query-gen script will run forever if it is not able to find any queries which satisfy the required constraints. (maximum tested join length for the BTC 2011 data was 6 triple patterns).

# Resources #

Several path queries were generated and tested to verify that the generated can actually return results. The queries can be downloaded here: http://code.google.com/p/splodge/downloads/detail?name=ISWC2012_eval_queries.zip&can=2

# Publications #

<a href='http://slideshare.net/slideshow/embed_code/15197280'>Presentation at ISWC 2012</a>
