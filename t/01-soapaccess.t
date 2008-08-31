use strict;
use warnings;

use Test::More tests => 6;

use SOAP::Integr8;

my $i8_ws = SOAP::Integr8->new();

organisms();
genome_ac();
proteome_id();
gene();

sub organisms {
	my $orgs = $i8_ws->getOrganismsByQueryTerm('sapiens');
	is(size($orgs), 1, 
		'Searching for Homo Sapiens using "sapiens"; expect one result');
	is($orgs->[0]->{taxId}, 9606, 'Human tax id (9606) as expected');
	is($orgs->[0]->{name}, 'Homo sapiens', 'Human scientific name as expected');
}

sub genome_ac {
	my $ac = 'U00096';
	my $gene_ids = $i8_ws->getGeneIdsByGenomeAc($ac);
	ok(size($gene_ids) > 0, "Expecting Genes for ${ac}");
}

sub proteome_id {
	my $gene_ids = $i8_ws->getGeneIdsByProteomeIdAndQueryTerm(18, 'valyl');
	ok(size($gene_ids) > 0, 'Expect some gene id results for Proteome ID 18 and valyl');
}

sub gene {
	my $gene = $i8_ws->getGeneById(1);
	ok(defined $gene, 'Expect a result for Gene ID 1');
}

sub size {
	my ($aref) = @_;
	return scalar(@{$aref});
}