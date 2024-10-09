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
    ok(!$scalar->can_upcast_to($scalar),   '... scalar  can upcast from scalar');
    ok(!$scalar->can_upcast_to($bool),     '... bool    can upcast from scalar');
    ok(!$scalar->can_upcast_to($string),   '... string  can upcast from scalar');
    ok(!$scalar->can_upcast_to($numeric),  '... numeric can upcast from scalar');
    ok(!$scalar->can_upcast_to($int),      '... int     can upcast from scalar');
    ok(!$scalar->can_upcast_to($float),    '... float   can upcast from scalar');

    ok(!$scalar->can_downcast_to($scalar),   '... scalar  can downcast from scalar');
    ok( $scalar->can_downcast_to($bool),     '... bool    not downcast from scalar');
    ok( $scalar->can_downcast_to($string),   '... string  not downcast from scalar');
    ok( $scalar->can_downcast_to($numeric),  '... numeric not downcast from scalar');
    ok( $scalar->can_downcast_to($int),      '... int     not downcast from scalar');
    ok( $scalar->can_downcast_to($float),    '... float   not downcast from scalar');
};

subtest '... testing bool' => sub {
    ok( $bool->can_upcast_to($scalar),   '... scalar  not upcast from bool');
    ok(!$bool->can_upcast_to($bool),     '... bool    can upcast from bool');
    ok(!$bool->can_upcast_to($string),   '... string  not upcast from bool');
    ok(!$bool->can_upcast_to($numeric),  '... numeric not upcast from bool');
    ok(!$bool->can_upcast_to($int),      '... int     not upcast from bool');
    ok(!$bool->can_upcast_to($float),    '... float   not upcast from bool');

    ok(!$bool->can_downcast_to($scalar),   '... scalar  can downcast from bool');
    ok(!$bool->can_downcast_to($bool),     '... bool    can downcast from bool');
    ok(!$bool->can_downcast_to($string),   '... string  not downcast from bool');
    ok(!$bool->can_downcast_to($numeric),  '... numeric not downcast from bool');
    ok(!$bool->can_downcast_to($int),      '... int     not downcast from bool');
    ok(!$bool->can_downcast_to($float),    '... float   not downcast from bool');
};

subtest '... testing string' => sub {
    ok( $string->can_upcast_to($scalar),   '... scalar  not upcast from string');
    ok(!$string->can_upcast_to($bool),     '... bool    not upcast from string');
    ok(!$string->can_upcast_to($string),   '... string  can upcast from string');
    ok(!$string->can_upcast_to($numeric),  '... numeric not upcast from string');
    ok(!$string->can_upcast_to($int),      '... int     not upcast from string');
    ok(!$string->can_upcast_to($float),    '... float   not upcast from string');

    ok(!$string->can_downcast_to($scalar),   '... scalar  can downcast from string');
    ok(!$string->can_downcast_to($bool),     '... bool    not downcast from string');
    ok(!$string->can_downcast_to($string),   '... string  can downcast from string');
    ok(!$string->can_downcast_to($numeric),  '... numeric not downcast from string');
    ok(!$string->can_downcast_to($int),      '... int     not downcast from string');
    ok(!$string->can_downcast_to($float),    '... float   not downcast from string');
};

subtest '... testing numeric' => sub {
    ok( $numeric->can_upcast_to($scalar),   '... scalar  not upcast from numeric');
    ok(!$numeric->can_upcast_to($bool),     '... bool    not upcast from numeric');
    ok(!$numeric->can_upcast_to($string),   '... string  not upcast from numeric');
    ok(!$numeric->can_upcast_to($numeric),  '... numeric can upcast from numeric');
    ok(!$numeric->can_upcast_to($int),      '... int     can upcast from numeric');
    ok(!$numeric->can_upcast_to($float),    '... float   can upcast from numeric');

    ok(!$numeric->can_downcast_to($scalar),   '... scalar  can downcast from numeric');
    ok(!$numeric->can_downcast_to($bool),     '... bool    not downcast from numeric');
    ok(!$numeric->can_downcast_to($string),   '... string  not downcast from numeric');
    ok(!$numeric->can_downcast_to($numeric),  '... numeric can downcast from numeric');
    ok( $numeric->can_downcast_to($int),      '... int     not downcast from numeric');
    ok( $numeric->can_downcast_to($float),    '... float   not downcast from numeric');
};

subtest '... testing int' => sub {
    ok( $int->can_upcast_to($scalar),   '... scalar  not upcast from int');
    ok(!$int->can_upcast_to($bool),     '... bool    not upcast from int');
    ok(!$int->can_upcast_to($string),   '... string  not upcast from int');
    ok( $int->can_upcast_to($numeric),  '... numeric not upcast from int');
    ok(!$int->can_upcast_to($int),      '... int     can upcast from int');
    ok(!$int->can_upcast_to($float),    '... float   not upcast from int');

    ok(!$int->can_downcast_to($scalar),   '... scalar  can downcast from int');
    ok(!$int->can_downcast_to($bool),     '... bool    not downcast from int');
    ok(!$int->can_downcast_to($string),   '... string  not downcast from int');
    ok(!$int->can_downcast_to($numeric),  '... numeric can downcast from int');
    ok(!$int->can_downcast_to($int),      '... int     can downcast from int');
    ok(!$int->can_downcast_to($float),    '... float   not downcast from int');
};

subtest '... testing float' => sub {
    ok( $float->can_upcast_to($scalar),   '... scalar  not upcast from float');
    ok(!$float->can_upcast_to($bool),     '... bool    not upcast from float');
    ok(!$float->can_upcast_to($string),   '... string  not upcast from float');
    ok( $float->can_upcast_to($numeric),  '... numeric not upcast from float');
    ok(!$float->can_upcast_to($int),      '... int     not upcast from float');
    ok(!$float->can_upcast_to($float),    '... float   can upcast from float');

    ok(!$float->can_downcast_to($scalar),   '... scalar  can downcast from float');
    ok(!$float->can_downcast_to($bool),     '... bool    not downcast from float');
    ok(!$float->can_downcast_to($string),   '... string  not downcast from float');
    ok(!$float->can_downcast_to($numeric),  '... numeric can downcast from float');
    ok(!$float->can_downcast_to($int),      '... int     not downcast from float');
    ok(!$float->can_downcast_to($float),    '... float   can downcast from float');
};


done_testing;
