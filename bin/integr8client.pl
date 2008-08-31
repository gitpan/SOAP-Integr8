#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "${Bin}/../lib";

use SOAP::Integr8;
use SOAP::Lite;

my $tilde_line = '~'x18;
my $i8_ws = SOAP::Integr8->new();

my $dispatch = {
	getorganisms => sub{
		print_organisms($i8_ws->getOrganisms());
	},
	getorganismsbyqueryterm => sub{
		print_organisms($i8_ws->getOrganismsByQueryTerm(@_));
	},
	getgeneidsbyproteomeid => sub{
		print_gene_ids($i8_ws->getGeneIdsByProteomeId(@_));
	},
	getgeneidsbygenomeac => sub{
		print_gene_ids($i8_ws->getGeneIdsByGenomeAc(@_));
	},
	getgeneidsbyqueryterm => sub{
		print_gene_ids($i8_ws->getGeneIdsByQueryTerm(@_));
	},
	getgeneidsbyproteomeidandqueryterm => sub{
		if(scalar(@_) != 2) {
			print STDERR 'Incorrect number of elements given for getGeneIdsByProteomeIdAndQueryTerm()', "\n";
			exit(2);
		}
		my ($proteome_id, $terms) = @_;
		print_gene_ids($i8_ws->getGeneIdsByProteomeIdAndQueryTerm($proteome_id, split(/,/, $terms)));
	},
	getgenebyid => sub{
		print_gene($i8_ws->getGeneById(@_));
	}
};

run();

sub run {
	print '*** Sample perl client for accessing Integr8 Web Services (SOAP::Lite version ', $SOAP::Lite::VERSION, ') ***', "\n";
	my ($cmd, @data) = @ARGV;
	
	my $search_cmd = lc($cmd);
	
	if($cmd eq '' or $search_cmd eq 'h') {
    get_help();
    exit(0);
  }

	my $code_dispatch = $dispatch->{$search_cmd};
	
	if(!defined $code_dispatch) {
		print_invalid_command();
		exit(1);
	}
	
	my $params = join(', ', @data);
	my $title = "${tilde_line} ${cmd}(${params}) ${tilde_line}";
	print "\n${title}\n";
	$code_dispatch->(@data);
	print "\n${title}", "\n"x2;
}

sub get_help
{
  print "\n";
  print '*** HELP (you have the following options) ***', "\n";

  print "\n";
  print 'getOrganisms', "\n";
  print 'Get all Organisms.', "\n";
  print 'Example: getOrganisms', "\n";

  print "\n";
  print 'getOrganismsByQueryTerm', "\n";
  print 'Get all Organisms matching the query term $1', "\n";
  print 'Example: getOrganismsByQueryTerm yeast', "\n";

  print "\n";
  print 'getGeneIdsByProteomeId', "\n";
  print 'Get all Gene IDs matching the proteome ID $1', "\n";
  print 'Example: getGeneIdsByProteomeId 17', "\n";

  print "\n";
  print 'getGeneIdsByGenomeAc', "\n";
  print 'Get all Gene IDs matching the genome AC $1', "\n";
  print 'Example: getGeneIdsByGenomeAc CP000416', "\n";

  print "\n";
  print 'getGeneIdsByQueryTerm', "\n";
  print 'Get all Gene IDs matching the query term(s) $1,$2,.,.,$n', "\n";
  print 'Example: getGeneIdsByQueryTerm ras', "\n";
  print 'Example: getGeneIdsByQueryTerm ras1,ras85d', "\n";
  print 'Example: getGeneIdsByQueryTerm GO:0007257', "\n";

  print "\n";
  print 'getGeneIdsByProteomeIdAndQueryTerm', "\n";
  print 'Get all Gene IDs matching the proteome ID $1 and query term(s) $2,.,.,$n', "\n";
  print 'Example: getGeneIdsByProteomeIdAndQueryTerm 17 ras1,ras85d', "\n";
  print 'Example: getGeneIdsByProteomeIdAndQueryTerm 18 ras1,ras85d', "\n";

  print "\n";
  print 'getGeneById', "\n";
  print 'Get the Gene which matches the ID $1', "\n";
  print 'Example: getGeneById 1', "\n";

  print "\n";
  print '*********************************************', "\n";
}

sub print_invalid_command
{
  print "\n";
  print 'Invalid command, please try again (use h for help)', "\n";
}

sub print_organisms
{
  my @organisms = @{shift @_};

  print "\n*** ORGANISMS (", scalar(@organisms), ") ***\n";
  for my $organism (@organisms)
  {
    print_organism($organism);
  }
}

sub print_organism
{
  my ($organism) = @_;

  print "\n*** ORGANISM ***\n";
  print 'Name:        ', $organism->{name} ,"\n";
  print 'Superregnum: ', $organism->{superregnum} ,"\n";
  print 'ProteomeId:  ', $organism->{proteomeId} ,"\n";
  print 'Tax ID:      ', $organism->{taxId} ,"\n";
  print 'Description: ', $organism->{description}, "\n";
}

sub print_gene_ids
{
  my @geneIds = @{decode_to_array(shift @_)};

  print "\n*** GENE IDS (", scalar(@geneIds), ") ***\n";
  for my $geneId (@geneIds)
{
    print "\n";
    print 'ID:           ', $geneId->{id}, "\n";
    print 'UniProtKb AC: ', $geneId->{uniProtKbAc} || q{}, "\n";
    print 'Name:         ', $geneId->{name}, "\n";
    print 'Protein Name: ', $geneId->{proteinName}, "\n";
    print 'Proteome ID:  ', $geneId->{proteomeId}, "\n";
  }
}

sub print_gene
{
  my ($gene) = @_;

  if (!defined $gene)
  {
    print "\nNO GENE FOUND ! ***\n";
    return;
  }

  print "\n*** GENE ***\n";
  print 'Name: ', $gene->{name}, "\n";

  print_xrefs($gene->{xrefs}, 'GENE');

  print "\n\n*** CHROMOSOME ***\n";
  my $chromosome = $gene->{chromosome};
  print 'Name:   ', $chromosome->{name}, "\n";

  print "\n*** CHROMOSOMAL LOCATION ***\n";
  my $location = $gene->{chromosomalLocation};
  print 'Start:  ', $location->{start}, "\n";
  print 'End:    ', $location->{end}, "\n";
  print 'Strand: ', $location->{strand}, "\n";

  print "\n";
  print_transcripts($gene);

  print "\n";
  print_protein_isoforms($gene);

  print "\n\n*** ORTHOLOGUES ***\n";
  print_gene_ids($gene->{orthologues});

  print "\n\n*** PARALOGUES ***\n";
  print_gene_ids($gene->{paralogues});
}

sub print_xrefs
{
  my ($xrefs_ref, $label) = @_;
	my @xrefs = @{decode_to_array($xrefs_ref)};
  print "\n*** ", $label, " XREFS (", scalar(@xrefs), ") ***\n";
  for my $xref (@xrefs)
  {
    print "\n*** XREF ***\n";
    print 'DB Name:      ', $xref->{dbName}, "\n";
    print 'Primary ID:   ', $xref->{id}, "\n";
    print 'Secondary ID: ', $xref->{secondaryId} || q{}, "\n";
    print 'Category:     ', $xref->{category}, "\n";
  }
}

sub print_transcripts
{
  my ($result) = @_;
	
  my @transcripts = @{decode_to_array($result->{transcripts})};
  print "\n*** TRANSCRIPTS (", scalar(@transcripts), ") ***\n";
  for my $transcript (@transcripts)
  {
    print "\nName: ", $transcript->{name}, "\n";
    print_xrefs($transcript->{xrefs}, 'TRANSCRIPT');
  }
}

sub print_protein_isoforms
{
  my ($gene) = @_;
  my @proteins = @{decode_to_array($gene->{proteinIsoforms})};
  print "\n*** PROTEIN ISOFORMS (", scalar(@proteins), ") ***\n";
  for my $protein (@proteins)
  {
    print "\nName: ", $protein->{name}, "\n";
    print_xrefs($protein->{xrefs}, 'PROTEIN');
  }
}

sub print_strings
{
  my @strings = @{decode_to_array(shift @_)};
  print "\n\n*** UniProtKb ACs (" , scalar(@strings), ") ***\n";
  for my $string (@strings)
  {
    print $string, "\n";
  }
}

sub decode_to_array {
	my ($val) = @_;
	return $i8_ws->wrap_array($val);$i8_ws
}
