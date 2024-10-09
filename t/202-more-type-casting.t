#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;
use B::MOP::Type;

my $scalar  = B::MOP::Type::Scalar->new;
my $bool    = B::MOP::Type::Bool->new;
my $string  = B::MOP::Type::String->new;
my $numeric = B::MOP::Type::Numeric->new;
my $int     = B::MOP::Type::Int->new;
my $float   = B::MOP::Type::Float->new;

subtest '... testing casting' => sub {
    my $new_int = $numeric->cast( $int );
    isa_ok($new_int, 'B::MOP::Type::Int');
    isa_ok($new_int->get_prev, 'B::MOP::Type::Numeric');

    my $new_scalar = $new_int->cast( $scalar );
    isa_ok($new_scalar, 'B::MOP::Type::Scalar');
    isa_ok($new_scalar->get_prev, 'B::MOP::Type::Int');
    isa_ok($new_scalar->get_prev->get_prev, 'B::MOP::Type::Numeric');
};

done_testing;
