#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use B::MOP;

package Foo {
    sub bar ($x, $y) { my @z = ($x + $y) }
    sub baz { 'BAZ' }
}

subtest '... simple package test' => sub {
    my $Foo = B::MOP->new->load_package('Foo');

    is($Foo->name, 'Foo', '... got the expected name');

    my %subroutines = $Foo->subroutines;
    is((scalar keys %subroutines), 2, '... we have 2 subroutines');
    ok(exists $subroutines{bar}, '... we have a bar subroutine');
    ok(exists $subroutines{baz}, '... we have a baz subroutine');

    subtest '... test the baz subroutine' => sub {
        my @opcodes = qw[
            nextstate
            const
            leavesub
        ];
        my $baz = $subroutines{baz};
        isa_ok($baz, 'B::MOP::Subroutine');

        foreach my ($i, $op) (indexed $baz->opcodes) {
            is($op->name, $opcodes[$i], '... got the expected opcodes in &baz');
        }

        is($baz->parameters->arity, 0, '... arity is 0 on baz');
    };

    subtest '... test the bar subroutine' => sub {
        my $bar = $subroutines{bar};
        isa_ok($bar, 'B::MOP::Subroutine');

        is($bar->parameters->arity, 2, '... arity is 2 on bar');

        my @args = ('$x', '$y');

        foreach my ($i, $entry) (indexed $bar->parameters->params) {
            is($entry->name, $args[$i], '... got the expected arg in &bar');
            ok(!$entry->is_invocant, '... not an invocant');
            ok(!$entry->is_field, '... not an field');
            ok(!$entry->is_our, '... not an our');
            ok($entry->is_my, '... but is a normal lexical');
        }

        my @lexicals = ('@z');

        foreach my ($i, $entry) (indexed $bar->pad) {
            is($entry->name, $lexicals[$i], '... got the expected lexical in &bar');
            ok(!$entry->is_invocant, '... not an invocant');
            ok(!$entry->is_field, '... not an field');
            ok(!$entry->is_our, '... not an our');
            ok($entry->is_my, '... but is a normal lexical');
        }
    }
};

done_testing;
