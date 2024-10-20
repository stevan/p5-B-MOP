
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- that an error is flagged when comparing Strings with Numeric boolean ops
- NOTE:
    - there is a commented out test to check the last expression
        - which compares Int to Float with a Numeric Boolean op
        - this works because they are downgraded to Numeric
            - but this is never visible because the op returnes a Bool
        - perhaps this should be a Type Warning?

=cut

package Foo {
    sub test {
        my $x = 10;
        my $y = "ten";
        my $z = $x == $y;
        my $p = $x != 10.5;
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
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
        [ '$p', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
    );

   check_type_error(
       $test->ast->tree->block->statements->[2]->expression->rhs,
       B::MOP::Type::Relation->new(
           lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
           rhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
       )
   );

    # TODO: add TypeWarning
    # check_type_error(
    #     $test->ast->tree->block->statements->[3]->expression->rhs,
    #     B::MOP::Type::Relation->new(
    #         lhs => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
    #         rhs => B::MOP::Type::Float->new,
    #     )
    # );

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
