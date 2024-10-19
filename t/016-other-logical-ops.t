
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- the and/or varient of logical operatons
    - more control-flow tests here

=cut

package Foo {
    sub test {
        my $x = 100;
        my $y = 30;
        my $z;
        $x and $z = 200;
        $y or  $z = 5000;
        $z = ($x and 5) or ($y and 16);
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
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
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
