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

subtest '... testing scalar' => sub {

    my $x = $numeric->cast( $int );
    my $y = $x->cast( $scalar );
    pass "... numeric        : $numeric";
    pass "... int            : $int";
    pass "... numeric to int : $x";
    pass "... int to scalar  : $y";
};




done_testing;
