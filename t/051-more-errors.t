#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        my $y = "ten";
        my $z = ($x + $y);
        my $p = ($x + $z) * $y;
    }
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    say Dump $test->ast->to_JSON(true) if $ENV{DEBUG};
};


done_testing;
