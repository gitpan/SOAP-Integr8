package SOAP::Integr8;

use warnings;
use strict;

use Carp;
use SOAP::Lite; # +trace => 'debug';
use SOAP::Integr8::ParamFactory;

our $VERSION = '1.0';

my $DEFAULT_WSDL = 'http://www.ebi.ac.uk:80/webservices/wsintegr8/integr8?wsdl';

# =========================== ACCESSORS

sub new {
	my ($class, %params) = @_;
	$class = ref($class) || $class;
	my $self = bless({}, $class);
	$self->wsdl($params{wsdl} || $DEFAULT_WSDL);
	$self->service($params{service}) if exists $params{service};
	$self->die_on_error($params{die_on_error}) if exists $params{die_on_error};
	return $self;
}

sub wsdl {
	my ($self, $wsdl) = @_;
	if(defined $wsdl){
		$self->{wsdl} = $wsdl;
		$self->{service} = undef;
	}
	return $self->{wsdl};
}

sub service {
	my ($self, $service) = @_;
	$self->{service} = $service if defined $service;
	if(!defined $self->{service}) {
		$self->{service} = $self->_create_service_from_wsdl();
	}
	return $self->{service};
}

sub die_on_error {
	my ($self, $die_on_error) = @_;
	$self->{die_on_error} = $die_on_error if defined $die_on_error;
	#Bit of defaulting code here
	return $self->{die_on_error} if(defined $self->{die_on_error});
	return 1;
}

sub param_factory {
	my ($self) = @_;
	$self->{param_factory} = SOAP::Integr8::ParamFactory->new() 
		unless exists $self->{param_factory};
	return $self->{param_factory};
}

# ===================== FACTORIES

sub _create_service_from_wsdl {
	my ($self) = @_;
	my $service = SOAP::Lite->service($self->wsdl);
	$service->on_fault(sub{
		my ($soap, $res) = @_;
		my $error;
		if(ref($res)) {
			$error = sprintf('SOAP FAULT(%s): %s', $res->faultcode, $res->faultstring);
			$self->{_error_detail} = $res->faultdetail;
		}
		else {
			$error = sprintf('TRANSPORT ERROR: %s', $soap->transport->status);
		}
		$self->{_error} = $error;
		return SOAP::SOM->new();
	});
	return $service;
}

# ==================== ERROR HANDLING

sub error {
	return shift(@_)->{_error};
}

sub error_detail {
	return shift(@_)->{_error_detail};
}

sub _error_handling {
	my ($self) = @_;
	if($self->die_on_error() && $self->error()) {
		confess($self->error);
	}
}


sub _reset {
	my ($self) = @_;
	$self->{_error} = undef;
	$self->{_error_detail} = undef;
}

# =================== WS METHODS

sub getOrganisms {
	my $self = shift @_;
	return $self->_run_ws('organisms', 0, sub {
		my ($self) = @_;
		return $self->service->getOrganisms();
	}, @_);
}

sub getOrganismsByQueryTerm {
	my $self = shift @_;
	return $self->_run_ws('organisms', 1, sub {
		my ($self, $term) = @_;
		my $w_t = $self->param_factory->term($term);
		return $self->service->getOrganismsByQueryTerm($w_t);
	}, @_);
}

sub getGeneIdsByProteomeId {
	my $self = shift @_;
	return $self->_run_ws('geneIds', 1, sub {
		my ($self, $proteome_id) = @_;
		my $w_p_id = $self->param_factory->proteome_id($proteome_id);
		return $self->service->getGeneIdsByProteomeId($w_p_id);
	}, @_);
}

sub getGeneIdsByGenomeAc {
	my $self = shift @_;
	return $self->_run_ws('geneIds', 1, sub {
		my ($self, $genome_ac) = @_;
		my $w_g_ac = $self->param_factory->genome_ac($genome_ac);
		return $self->service->getGeneIdsByGenomeAc($w_g_ac);
	}, @_);
}

sub getGeneIdsByQueryTerm {
	my $self = shift @_;
	return $self->_run_ws('geneIds', 1, sub {
		my ($self, @terms) = @_;
		my $w_t = $self->param_factory->terms(@terms);
		return $self->service->getGeneIdsByQueryTerm($w_t);
	}, @_);
}

sub getGeneIdsByProteomeIdAndQueryTerm {
	my $self = shift @_;
	return $self->_run_ws('geneIds', 1, sub {
		my ($self, $proteome_id, @terms) = @_;
		my $w_p_id = $self->param_factory->proteome_id($proteome_id);
		my $w_t = $self->param_factory->terms(@terms);
		$self->service->getGeneIdsByProteomeIdAndQueryTerm($w_p_id, $w_t);
	}, @_);
}

sub getGeneById {
	my $self = shift @_;
	my $result = $self->_run_ws(undef, 0, sub {
		my ($self, $id) = @_;
		return $self->service->getGeneById($self->param_factory->gene_id($id));
	}, @_);
	return $result;
}

sub _run_ws {
	my ($self, $key, $requires_array, $code, @params) = @_;
	$self->_reset;
	my $result = $code->($self, @params);
	$self->_error_handling;
	my $unwrapped = (defined $key)	? $self->_unwrap_from_hash($key, $result) 
																	: $result;
	if(defined $unwrapped) {
		if($requires_array) {
			return $self->wrap_array($unwrapped);
		}
		return $unwrapped;
	}
	return;
}

sub _unwrap_from_hash {
	my ($self, $key, $result) = @_;
	#Still have to check as user may not want a Carp earlier
	if(!$self->error()) {
		if(defined $result && ref($result) eq 'HASH') {
			return (defined $key && exists $result->{$key}) ? $result->{$key} : $result;
		}
	}
	return;
}

sub wrap_array {
	my ($self, $val) = @_;
	return [] unless defined $val;
	if(defined $val && ref($val) ne 'ARRAY') {
		return [$val];
	}
	return $val;
}


1;
__END__
=head1 NAME

SOAP::Integr8 - L<SOAP::Lite> helper class for Integr8 Web Services @ EBI

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

  use SOAP::Integr8;

  my $i8_ws = SOAP::Integr8->new();
  my $organism_name = 'Escherichia coli K12';
  my $organisms = $i8_ws->getOrganismsByQueryTerm($organism_name);

  foreach my $organism (@{$organisms}) {
    print STDOUT $organism->{superregnum}, "\n";
  }

=head1 DESCRIPTION

A wrapper for SOAP::Lite to provide easier access to the resources held
on the Integr8 resource located at the European Bioinformatics Institute (EMBL). 

=head1 FUNCTIONS

=head2 new()

Creates a new instance of this object. You can provide the following during
construction:

=over 4

=item * wsdl

=item * service

=item * die_on_error

=back

=head2 wsdl()

The WSDL to use for the integr8 service. Will default to the currently known
WSDL location but here to allow for this to change & allow clients to migrate
if this ever occurs.

=head2 service()

Allows you to give this object a L<SOAP::Lite> proxy object. Also for accessing
the one automatically created (if you prefer to customize this one further).

=head2 die_on_error()

If an error occurs the module will C<confess> the string found in C<error>. Can
be used to switch the function off (defaults to on if nothing is given)

=head2 param_factory()

An instance of L<SOAP::Integr8::ParamFactory> an internal dependency but here
if you require inspection of the parameter creation.

=head2 error()

The error found on the last run. Can be used as a boolean to check the existence
of an error. Normally used if you've opted to turn of the C<die_on_error>
functionality.

=head2 error_detail()

Will sometimes get populated in the event of an error. Depends on C<SOAP::Lite>
and its error reporting system

=head2 wrap_array()

	my $res = get_from_somewhere_might_be_an_array();
	my $this_is_an_array = $integr8->wrap_array($res);
	
This method is used to avoid ambiguity caused by the transport mechanism. 
Any element which could contain multiple elements (such as a gene's xrefs) will
be returned as an array if there is more than one. Therefore you can pass a 
potentially ambigous result to this method & this code will wrap it in an
array if the reference is not already an array. i.e.

	$i8_ws->wrap_array({}); #Returns [{}] since input is not an array
	$i8_ws->wrap_array([]); #Returns the SAME instance of the array back
	$i8_ws->wrap_array(undef); #Returns a new []

This method is a solution to a problem which would be better if it did not
exist & could be solved by this module but it is important to realise what
the underlying data is like when working with the client.

=head2 get*()

If you wish to use the C<*ByQueryTerm> methods then to get a preview of your
results please use the quick search box on the Integr8 home page.

B<N.B.> Whenever the code refers to a Gene ID this does not refer to the public
stable IGI values provided by Integr8. This is the identifier retrieved from the
getGeneIds* methods and is an internal identifier. We provide no guarentee that
this ID is stable between distant Web Service sessions but will remain constant
for basic WS work.

All methods which can return multiple elements will ALWAYS return an array. You
do not need to call C<wrap_array> for these results.

=head3 getOrganisms()

Returns an array ref of all known organisms.

=head3 getOrganismsByQueryTerm()

	$i8_ws->getOrganismsByQueryTerm('ras1');

Returns all organisms found by the given terms. Provides equivalent to the
search function found at the Integr8 website

=head3 getGeneIdsByProteomeId()

	my $gene_ids = $i8_ws->getGeneIdsByProteomeId(18); #EColi K12

Returns all known Gene IDs from a Proteome ID (which is specified in an 
Organism by proteomeId).

=head3 getGeneIdsByGenomeAc()

	my $gene_ids = $i8_ws->getGeneIdsByGenomeAc('U00096');

Returns all known Gene IDs from a Genome Ac (normally an EMBL accession such as
U00096 for E.Coli K12)

=head3 getGeneIdsByQueryTerm()

	my $gene_ids = $i8_ws->getGeneIdsByQueryTerm('valyl');

Returns all gene ids found by a query term.

=head3 getGeneIdsByProteomeIdAndQueryTerm()

	my $gene_ids = $i8_ws->getGeneIdsByProteomeIdAndQueryTerm(18, 'valyl');

Allows you to restrict the search of gene ids to a given proteome and a term
allowing for more complex queries such as E.Coli Valyl tRNA Synthetase

=head3 getGeneById()

	my $gene = $i8_ws->getGeneById(1);

Returns all the information concerning a gene that Integr8 is able to report.

=head1 AUTHOR

Andrew Yates, C<< <ayatesatebi.ac.uk> >>

=head1 BUGS

Report directly to EBI using the help interface L<http://www.ebi.ac.uk/support>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SOAP::Integr8

You can also look for information at:

=over 4

=item * Integr8

L<http://www.ebi.ac.uk/integr8/>

=item * Integr8 WS Help

L<http://www.ebi.ac.uk/integr8/HelpAction.do?action=searchById&refId=59>

=back

=head1 ACKNOWLEDGEMENTS

The hard work of Alan Horne & the SOAP::Lite module team.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 European Bioinformatics Institute.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut