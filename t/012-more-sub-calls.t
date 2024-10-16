#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub add_10 ($x) { 10 + $x }

    sub adder ($x, $y) {
        $x + $y;
    }

    sub test {
        my $z = adder(10, add_10(20));
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::add_10' => sub {
    my $add_10 = $Foo->get_subroutine('add_10');
    isa_ok($add_10, 'B::MOP::Subroutine');

    check_env($add_10,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($add_10, [
            [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        ],
        B::MOP::Type::Numeric->new
    );

    check_statement_types($add_10,
        B::MOP::Type::Void->new,   # arg check
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Numeric->new,
    );

    say node_to_json($add_10) if $ENV{DEBUG};
};

subtest '... Foo::adder' => sub {
    my $adder = $Foo->get_subroutine('adder');
    isa_ok($adder, 'B::MOP::Subroutine');

    check_env($adder,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($adder, [
            [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
            [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        ],
        B::MOP::Type::Numeric->new
    );

    check_statement_types($adder,
        B::MOP::Type::Void->new,   # arg check
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Numeric->new,
    );

    say node_to_json($adder) if $ENV{DEBUG};
};

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    check_env($test,
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($test, [],
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new)
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
    );

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
