#!/usr/bin/env perl
#-------------------------------------------------------------------------
# Processes context URIs of RDF quads.
# Aggregates sub domains if they belong to a common parent domain,
#   e.g. {jane,john}.livejournal.com.
# Prints the frequency for all (common) host names (with sub domains).
##########################################################################

use strict;
use warnings "all";

my $tree = {};

# split URI by '.' in domain parts, build tree starting with top level domain
while(<>) {
  chomp;
  my $href=$tree;
  for (reverse split /\./) {
    $href->{$_} = {} unless exists $href->{$_};  # initialize sub-tree
    $href = $href->{$_};
  }
  $href->{""}++;
}

print_hosts(0, undef, $tree);

# print all host names with frequency count.
# traverses the tree recursively and concats domain names.
# params: level    - the current tree level
#         host     - the host name at the current level
#         hash_ref - the reference to the current tree element
sub print_hosts {
  my ($level, $host, $href) = @_;
  my @keys = sort keys %$href;
  my $size = scalar @keys; 

  # print domain if it has different sub domains (except for 'co.uk')
  if ($size > 1 && $level > 1 && ($host !~ /.uk$/ || $level > 2)) {
    my @subdomains = ();
    for (@keys) {
      if ($_ ne "") {
        get_subdomains($_, $href->{$_}, \@subdomains);
      }
    }
    print "$host ".(join ",", @subdomains)."\n";
  } else  {
    for (@keys) {
      if ($_ ne "") {
        # add sub domains recursively (concat domain names)
        print_hosts($level+1, defined $host ? "$_.$host" : $_, $href->{$_});
      }
    }
  }
}

sub get_subdomains {
  my ($name, $href, $arrref) = @_;

  for (sort keys %$href) {
    if ($_ eq "") {
      push @$arrref, $name;
    } else {
      get_subdomains("$_.$name", $href->{$_}, $arrref);
    }
  }
}

# compute sum of sub domain frequencies
# params: hash_ref - the reference to the current tree element
# return: sum - the sum of frequencies
sub sum_freq {
  my ($href) = @_;
  my $sum = 0;
  $sum += $_ eq "" ? $href->{$_} : sum_freq($href->{$_}) for keys %$href;
  return $sum;
}
