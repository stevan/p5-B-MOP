#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub test {
        my $x;
        my $y = ($x + $x) + 12.5;
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    say Dump $test->ast->to_JSON(true) if $ENV{DEBUG};
};


done_testing;
