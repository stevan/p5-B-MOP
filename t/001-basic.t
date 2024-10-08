#!perl

use v5.40;
use experimental qw[ class ];

my sub DUMP ($op) {
    return 'NULL' if $op isa B::NULL;
    sprintf '%s(%d): %s = %s', blessed $op, ${$op}, $op->name, $op->desc;
}

use Test::More;

use B::MOP;
use B::MOP::Opcodes;

package Foo {
    sub add ($x, $y) { $x + $y }
    sub main () {
        return add( 10, add(100, 20) );
    }
}

subtest '... simple package test' => sub {
    my $root = B::MOP->new->load('Foo');
    isa_ok($root, 'B::MOP');

    my $Foo = $root->get_package('Foo');
    isa_ok($Foo, 'B::MOP::Package');

    is($Foo->name, 'Foo', '... got the expected name');

    my $main = $Foo->get_subroutine('main');
    isa_ok($main, 'B::MOP::Subroutine');

    my $add  = $Foo->get_subroutine('add');
    isa_ok($add, 'B::MOP::Subroutine');

    my ($add_call, $add_add_call) = $main->get_subroutine_calls;
    isa_ok($add_call, 'B::MOP::Code::SubroutineCall');
    isa_ok($add_add_call, 'B::MOP::Code::SubroutineCall');

    is($add_call->fully_qualified_name, 'Foo::add', '... got the expected call');
    is($add_add_call->fully_qualified_name, 'Foo::add', '... got the expected call');

    is(
        $add,
        $root->resolve_subroutine_call( $add_call ),
        '... got the expected subroutine for the call'
    );

    is(
        $add,
        $root->resolve_subroutine_call( $add_add_call ),
        '... got the expected subroutine for the call'
    );

    subtest '... check args for add call' => sub {
        my @args = $add_call->get_args;
        is(scalar(@args), 2, '... got 2 args');
        foreach my $op (@args) {
            is($op->name, B::MOP::Opcodes->CONST, '... got the expected opcodes');
        }
    };

    subtest '... check args for add(add) call' => sub {
        my @args = $add_add_call->get_args;
        is(scalar(@args), 6, '... got 6 args');

        my @expected = (
            B::MOP::Opcodes->CONST,
            B::MOP::Opcodes->PUSHMARK,
            B::MOP::Opcodes->CONST,
            B::MOP::Opcodes->CONST,
            B::MOP::Opcodes->GV,
            B::MOP::Opcodes->ENTERSUB,
        );

        foreach my ($i, $op) (indexed @args) {
            is($op->name, $expected[$i], '... got the expected opcodes');
        }
    };
};



done_testing;
