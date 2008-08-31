#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "${Bin}/../lib";

use Getopt::Long;
use SOAP::Integr8;

my $opts = {};
GetOptions($opts, qw(organism=s gene=s));

my $i8_ws = SOAP::Integr8->new();

my $organisms = get_organisms();

print 'Found ', scalar(@{$organisms}), ' organism(s)', "\n"x2;

foreach my $organism (@{$organisms}) {
	print 'Organism: ', $organism->{name}, "\n";
	my $genes = get_genes($organism);
	print 'Found ', scalar(@{$genes}), ' gene(s)', "\n"x2;
	foreach my $gene (@{$genes}) {
		print_orthologues($gene);
	}
}

sub get_organisms {
	return $i8_ws->getOrganismsByQueryTerm($opts->{organism});
}

sub get_genes {
	my ($organism) = @_;
	my $gene_ids = $i8_ws->getGeneIdsByProteomeIdAndQueryTerm($organism->{proteomeId}, $opts->{gene});
	my @results;
	foreach my $gene_id (@{$gene_ids}) {
		my $gene = $i8_ws->getGeneById($gene_id->{id});
		$gene->{description} = $gene_id->{proteinName};
		push(@results, $gene);
	}
	return \@results;
}

sub print_orthologues {
	my ($gene) = @_;
	
	my $orth_p = sprintf('%s (%s) orthologue(s)', $gene->{name}, $gene->{description});
	print $orth_p, "\n";
	print '~' x length($orth_p), "\n";
	
	foreach my $orthologue (@{$i8_ws->wrap_array($gene->{orthologues})}) {
		print "\t", $orthologue->{uniProtKbAc} || q{?}, "\n";
	}
	print "\n";
}