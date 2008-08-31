package SOAP::Integr8::ParamFactory;

use strict;
use warnings;
use SOAP::Lite;

sub new {
	my ($class) = @_;
	$class = ref($class) || $class;
	return bless({}, $class);
}

sub term {
	my ($self, $term) = @_;
	return $self->_single_string('term', $term);
}

sub terms {
	my ($self, @terms) = @_;
	return $self->_array_string('terms', @terms);
}

sub proteome_id {
	my ($self, $data) = @_;
	return $self->_single_int('proteomeId', $data);
}

sub genome_ac {
	my ($self, $data) = @_;
	return $self->_single_string('genomeAc', $data);
}

sub gene_id {
	my ($self, $data) = @_;
	return $self->_single_int('geneId', $data);
}

sub _single_string {
	my ($self, $name, $data) = @_;
	return SOAP::Data->name($name => $data)->type('string');
}

sub _single_int {
	my ($self, $name, $data) = @_;
	return SOAP::Data->name($name => $data)->type('int');
}

sub _array_string  {
	my ($self, $name, @data) = @_;
	my $soap_data = SOAP::Data->value(SOAP::Data->name("strings" => @data)->type("string"));
	$soap_data->type('ArrayOfString');
	return SOAP::Data->name($name, \$soap_data);
}

1;
__END__
=pod

=head1 NAME

SOAP::Integr8::ParamFactory

=head1 SYNOPSIS

	my $pf = SOAP::Integr8::ParamFactory;
	my $wrapped = $pf->gene_id(1);

=head1 DESCRIPTION

Calls to the WSDL based SOAP service requires the client code to wrap params
in an appropriate data structure. This module has methods for returning 
the correct parameter structure for each method SOAP::Integr8 has to offer.

As a user you should not have to use this class directly since SOAP::Integr8
will do all the work for you.

=head1 SUBROUTINES

=head2 new

Creates a new instance of this class. Whilst this could be a functional module
it keeps it in the spirit of the SOAP::Integr8 package to have it as a 
object.

=head2 term

Returns a string SOAP::Data type keyed by term

=head2 terms

Returns an array of Strings of SOAP::Data keyed by terms

=head2 proteome_id

Returns an int of SOAP::Data

=head2 genome_ac

Returns a String

=head2 gene_id

Returns a string

=head1 AUTHOR

Andrew Yates

=cut