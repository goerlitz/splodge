#!/usr/bin/env perl
#-------------------------------------------------------------------------
# Processes context URIs of RDF quads.
# Aggregates sub domains if they belong to a common parent domain,
#   e.g. {jane,john}.livejournal.com.
# Prints the frequency for all (common) host names (with sub domains).
##########################################################################

use strict;
use warnings "all";

my %dict = ();

die "missing list of context URI to replace!\n" if (@ARGV == 0);

open FILE, $ARGV[0] or die $!;
while (<FILE>) { 
  chomp;
  my ($new_uri, $subdomains) = split / /, $_;
  my @domains = split /,/, $subdomains;
  for my $domain (split /,/, $subdomains) {
#    print "$domain.$new_uri -> $new_uri\n";
    $dict{"$domain.$new_uri"} = $new_uri; 
  }
}
close FILE;

#exit;

#print "loaded " . scalar (keys %dict) . " uris.\n";

while (<STDIN>) {
  my ($first, $host) = m!(.*//)(.*?)/!;
#  for (keys %dict) {
    $host = $dict{$host} if exists($dict{$host});
#    if ($host =~ m/$_/) {
#      print "match\n";
#    }
#  }
  print "$first$host/> .\n";
}
