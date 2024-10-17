
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- shows creating a new scope
    - capturing all the statement inside it
- shows shadowing of lexical vars ($x)
    - created with a differnt type
- and then usage of the original $x
    - after the scope exits

- as with blocks
    - the type of the last expression is the type of the loop

=cut

package Foo {
    sub test {
        my $x = 10;
        {
            my $x = 100.5 + $x;
            my $y = 1000;
            $x += $y;
        }
        $x + 5;
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
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ], # shadowed
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Numeric->new,
        B::MOP::Type::Numeric->new->cast(B::MOP::Type::Int->new),
    );

    say node_to_json($test) if $ENV{DEBUG};

};


done_testing;
