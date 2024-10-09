#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub test {
        my @array;
        $array[0] = 10;
    }
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    subtest '... testing the pad' => sub {
        my ($array) = $test->pad_variables;
        isa_ok($array, 'B::MOP::Variable');
        is($array->name, '@array', '... got the expected name for @array');
    };

    subtest '... testing the AST' => sub {
        my $ast  = $test->ast;
        isa_ok($ast,  'B::MOP::AST::Subroutine');

        my $block = $ast->block;
        isa_ok($block, 'B::MOP::AST::Block');

        my ($declare_array, $assign_array) = $block->statements->@*;

        subtest '... testing first statement' => sub {
            isa_ok($declare_array, 'B::MOP::AST::Statement');
            isa_ok($declare_array->expression, 'B::MOP::AST::Local::Fetch');

            my $array = $declare_array->expression->get_target;
            isa_ok($array, 'B::MOP::Variable');
            is($array->name, '@array', '... got the expected name for @array');
        };

        subtest '... testing second statement' => sub {
            isa_ok($assign_array, 'B::MOP::AST::Statement');

            my $assign = $assign_array->expression;
            isa_ok($assign, 'B::MOP::AST::Op::Assign');

            isa_ok($assign->lhs, 'B::MOP::AST::Local::Array::Element::Const');
            isa_ok($assign->rhs, 'B::MOP::AST::Const');

            my $array = $assign->lhs->get_target;
            isa_ok($array, 'B::MOP::Variable');
            is($array->name, '@array', '... got the expected name for @array');

            isa_ok($assign->rhs->get_type, 'B::MOP::Type::Int');
            is($assign->rhs->get_literal, 10, '... got the expected literal');
        };
    };

    say Dump $test->ast->to_JSON if $ENV{DEBUG};
};


done_testing;
