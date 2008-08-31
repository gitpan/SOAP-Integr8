use strict;
use warnings;

use Test::More tests => 3;

use SOAP::Integr8;

my $i8_ws = SOAP::Integr8->new();

is_deeply($i8_ws->wrap_array(), [], 'Empty arg should return an empty []');
is_deeply($i8_ws->wrap_array(1), [1], 'Scalar arg returned as [1]');
my $src_array = [0,9];
ok($i8_ws->wrap_array($src_array) eq $src_array, 'Array ref arg returned intact');
