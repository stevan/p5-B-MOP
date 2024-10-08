#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use B::MOP;

package Foo {
    our @X;
    sub add ($x, $y) { $x + $y }

    sub main () {
        push @X => 10;
        return add( 10, 20 );
    }
}

subtest '... simple package test' => sub {
    my $Foo = B::MOP->new->load_package('Foo');
    isa_ok($Foo, 'B::MOP::Package');

    is($Foo->name, 'Foo', '... got the expected name');

    my $main = $Foo->get_subroutine('main');
    isa_ok($main, 'B::MOP::Subroutine');

    my $add  = $Foo->get_subroutine('add');
    isa_ok($add, 'B::MOP::Subroutine');

    my ($add_ref) = $main->list_subroutines_referenced;
    is($add_ref, 'Foo::add', '... got the expected subroutine reference');
};



done_testing;
