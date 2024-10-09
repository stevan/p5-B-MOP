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
    is($scalar->compare($scalar),    0, '... scalar   == scalar');
    is($scalar->compare($bool),     -1, '... bool    isa scalar');
    is($scalar->compare($string),   -1, '... string  isa scalar');
    is($scalar->compare($numeric),  -1, '... numeric isa scalar');
    is($scalar->compare($int),      -1, '... int     isa scalar');
    is($scalar->compare($float),    -1, '... float   isa scalar');
};

subtest '... testing bool' => sub {
    is($bool->compare($scalar),     1, '... scalar !isa bool');
    is($bool->compare($bool),       0, '... bool     == bool');
    is($bool->compare($string),  undef, '... string  != bool');
    is($bool->compare($numeric), undef, '... numeric != bool');
    is($bool->compare($int),     undef, '... int     != bool');
    is($bool->compare($float),   undef, '... float   != bool');
};

subtest '... testing string' => sub {
    is($string->compare($scalar),     1, '... scalar !isa string');
    is($string->compare($bool),    undef, '... bool    != string');
    is($string->compare($string),     0,  '... string  == string');
    is($string->compare($numeric), undef, '... numeric != string');
    is($string->compare($int),     undef, '... int     != string');
    is($string->compare($float),   undef, '... float   != string');
};

subtest '... testing numeric' => sub {
    is($numeric->compare($scalar),     1, '... scalar !isa numeric');
    is($numeric->compare($bool),    undef, '... bool    != numeric');
    is($numeric->compare($string),  undef, '... string  != numeric');
    is($numeric->compare($numeric),    0,  '... numeric == numeric');
    is($numeric->compare($int),       -1,  '... int    isa numeric');
    is($numeric->compare($float),     -1,  '... float  isa numeric');
};

subtest '... testing int' => sub {
    is($int->compare($scalar),     1, '... scalar   !isa int');
    is($int->compare($bool),    undef, '... bool      != int');
    is($int->compare($string),  undef, '... string    != int');
    is($int->compare($numeric),    1,  '... numeric !isa int');
    is($int->compare($int),        0,  '... int      == int');
    is($int->compare($float),  undef,  '... float     != int');
};

subtest '... testing float' => sub {
    is($float->compare($scalar),     1, '... scalar   !isa float');
    is($float->compare($bool),    undef, '... bool      != float');
    is($float->compare($string),  undef, '... string    != float');
    is($float->compare($numeric),    1,  '... numeric !isa float');
    is($float->compare($int),    undef,  '... int       != float');
    is($float->compare($float),      0,  '... float     == float');
};

done_testing;
