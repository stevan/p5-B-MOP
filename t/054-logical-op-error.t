
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- is kinda broken
- the idea is that both sides of the logical op should be the same type
    - but the type inferrence system just downcaststs to Scalar
        - not sure if this is okay
        - maybe it just needs a Type warning?

=cut

package Foo {
    sub test {
        my $x = 100;
        my $y = "test";
        my $z;
        $z = $x && $y;
        $z = $x || $y;
        $z = $x // $y;
        $z = ($x // 5) && ($y || 16);
    }
}

# FIXME:
# currently this does not Type error, but should it?
#   - and if so, how?

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
        [ '$z', B::MOP::Type::Scalar->new ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new,
    );

    # TODO:
    # - test the sub-expressions in the last statement

    say node_to_json($test) if $ENV{DEBUG};

    use Test::Differences;
    use B::MOP::Tools::AST::Dumper::JSON;
    eq_or_diff(
        B::MOP::Tools::AST::Dumper::JSON->new( subroutine => $test )->dump,
        $test->to_JSON,
        '... how did we do?'
    );
};


done_testing;
