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
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::adder' => sub {
    my $adder = $Foo->get_subroutine('adder');
    isa_ok($adder, 'B::MOP::Subroutine');

    subtest '... testing the pad' => sub {
        my ($x, $y, $z) = $adder->pad_variables;
        isa_ok($x, 'B::MOP::Variable');
        is($x->name, '$x', '... got the expected name for $x');
        isa_ok($x->get_type, 'B::MOP::Type::Scalar');

        isa_ok($y, 'B::MOP::Variable');
        is($y->name, '$y', '... got the expected name for $y');
        isa_ok($y->get_type, 'B::MOP::Type::Scalar');
    };

    subtest '... testing the AST' => sub {
        my $ast  = $adder->ast;
        isa_ok($ast,  'B::MOP::AST::Subroutine');

        my $block = $ast->block;
        isa_ok($block, 'B::MOP::AST::Block');
    };

    say Dump $adder->ast->to_JSON if $ENV{DEBUG};
};


done_testing;
