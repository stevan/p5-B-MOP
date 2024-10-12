#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub adder ($x, $y) {
        $x + $y;
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::adder' => sub {
    my $adder = $Foo->get_subroutine('adder');
    isa_ok($adder, 'B::MOP::Subroutine');

    check_env($adder->ast,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($adder->ast, [
            [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
            [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        ],
        B::MOP::Type::Numeric->new
    );

    check_statement_types($adder->ast,
        B::MOP::Type::Void->new,   # arg check
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Numeric->new,
    );

    say Dump $adder->ast->to_JSON(true) if $ENV{DEBUG};
};


done_testing;
