
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- creating a scalar ref
    - capturing the type inside the Ref type
- dereferencing the scalar
    - using postfix and prefix
    - on both lhs and rhs of the assign operator
        - and even in an expression
    - and returning the inner type of the Ref where relevant
    - the last one even has a type error in the assign node
        - and things get downgraded to scalar

=cut

package Foo {
    sub test {
        my $x = 100;
        my $y = \$x;
        my $z = $y->$*;
        my $p = $$y;
        $y->$* = 200;
        my $q = $y->$* + $$y;
        $$y = "foo";
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
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Ref->new(
                        inner_type => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new))) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$p', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$q', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Ref->new(
                        inner_type => B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new))),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new,
    );

    # TODO: test the error

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
