
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        my $y = "ten";
        my $z = ($x + $y);
        my $p = ($x + $z) * $y;
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    check_env($test,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$p', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
    );

    check_signature($test, [],
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
    );

    check_type_error(
        $test->ast->tree->block->statements->[2]->expression->rhs,
        B::MOP::Type::Relation->new(
            lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
            rhs => B::MOP::Type::Numeric->new,
        )
    );

    check_type_error(
        $test->ast->tree->block->statements->[3]->expression->rhs,
        B::MOP::Type::Relation->new(
            lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
            rhs => B::MOP::Type::Numeric->new,
        )
    );

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
