#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        my $y = 20;
        my $z;
        $z = $x == $y;
        $z = $x != $y;
        $z = $x <  $y;
        $z = $x <= $y;
        $z = $x >  $y;
        $z = $x >= $y;
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
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
    );

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
