#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "${Bin}/../lib";

use SOAP::Integr8;
use Carp;

my $i8_ws = SOAP::Integr8->new();

my $gene_ids;
eval {
	$gene_ids = $i8_ws->getGeneIdsByQueryTerm('tns');
};

croak("Cannot retrive genes for tns due to error: $@") if $@;

print "\n*** Gene IDs (", scalar(@{$gene_ids}), ") ***\n";

foreach my $gene_id (@{$gene_ids}) {
	print "\n";
	print "ID: ", $gene_id->{id}, "\n";
	print "Uniprot KB AC: ", $gene_id->{uniProtKbAc} || q{-?-}, "\n";
	print "Name: ", $gene_id->{name}, "\n";
	print "Protein Name: ", $gene_id->{proteinName}, "\n";
	print "Proteome ID: ", $gene_id->{proteomeId}, "\n";
}
