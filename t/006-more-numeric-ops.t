#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub test ($x) {
        my $y = ($x + $x);
        my $z = ($y - 20.3) + (12.5 - $x);
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    check_env($test->ast,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($test->ast,
        [[ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ]],
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
    );

    check_statement_types($test->ast,
        B::MOP::Type::Void->new,   # arg check
        B::MOP::Type::Scalar->new, # arg elem
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
    );

    say Dump $test->ast->to_JSON(true) if $ENV{DEBUG};
};


done_testing;
