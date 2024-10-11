#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub adder ($x, $y) {
        $x + $y;
    }

    sub test {
        my $z = adder(10, "ten");
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::adder' => sub {
    my $adder = $Foo->get_subroutine('adder');
    isa_ok($adder, 'B::MOP::Subroutine');

    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    #say Dump $adder->ast->to_JSON(true) if $ENV{DEBUG};
    say Dump $test->ast->to_JSON(true)  if $ENV{DEBUG};
};


done_testing;
