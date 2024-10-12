#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        $x = "ten";
        $x = 100;
        $x = 12.5;
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
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
    );

    check_signature($test->ast, [],
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
    );

    check_statement_types($test->ast,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
    );

    check_type_error(
        $test->ast->tree->block->statements->[1]->expression,
        B::MOP::Type::Relation->new(
            lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
            rhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        )
    );

    check_type_error(
        $test->ast->tree->block->statements->[3]->expression,
        B::MOP::Type::Relation->new(
            lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
            rhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        )
    );

    say Dump $test->ast->to_JSON(true) if $ENV{DEBUG};
};


done_testing;
