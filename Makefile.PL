use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SOAP::Integr8',
    AUTHOR              => 'Andrew Yates <ayatesatebi.ac.uk>',
    VERSION_FROM        => 'lib/SOAP/Integr8.pm',
    ABSTRACT_FROM       => 'lib/SOAP/Integr8.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => undef,
				'SOAP::Lite' => undef
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SOAP-Integr8-*' },
);

print q(
******************************************************************************
** Some of the tests for this module need internet access                   **
** Also remember to set your http_proxy environment variable if you need to **
******************************************************************************
);