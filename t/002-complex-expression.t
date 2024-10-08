#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        my $y = (100 - ($x + 5)) * 20;
    }
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    subtest '... testing the pad' => sub {
        my ($x, $y) = $test->pad;
        isa_ok($x, 'B::MOP::Variable');
        is($x->name, '$x', '... got the expected name for $x');

        isa_ok($y, 'B::MOP::Variable');
        is($y->name, '$y', '... got the expected name for $y');
    };

    subtest '... testing the AST' => sub {
        my $ast  = $test->ast;
        isa_ok($ast,  'B::MOP::AST::Subroutine');

        my $block = $ast->block;
        isa_ok($block, 'B::MOP::AST::Block');

        my ($assign_x, $assign_y) = $block->statements->@*;

        subtest '... testing first statement' => sub {
            isa_ok($assign_x, 'B::MOP::AST::Statement');
            isa_ok($assign_x->expression, 'B::MOP::AST::Local::Store');
            my $value = $assign_x->expression->rhs;
            isa_ok($value, 'B::MOP::AST::Const');

            my $x = $assign_x->expression->pad_variable;
            isa_ok($x, 'B::MOP::Variable');
            is($x->name, '$x', '... got the expected name for $x');

            isa_ok($value->get_type, 'B::MOP::AST::Type::Int');
            is($value->get_literal, 10, '... got the expected literal');
        };

        subtest '... testing second statement' => sub {
            isa_ok($assign_y, 'B::MOP::AST::Statement');
            isa_ok($assign_y->expression, 'B::MOP::AST::Local::Store');

            my $y = $assign_y->expression->pad_variable;
            isa_ok($y, 'B::MOP::Variable');
            is($y->name, '$y', '... got the expected name for $y');

            my $value = $assign_y->expression->rhs;
            isa_ok($value, 'B::MOP::AST::Op::Multiply');
            isa_ok($value->lhs, 'B::MOP::AST::Op::Subtract');
            isa_ok($value->lhs->lhs, 'B::MOP::AST::Const');
            isa_ok($value->lhs->rhs, 'B::MOP::AST::Op::Add');
            isa_ok($value->lhs->rhs->lhs, 'B::MOP::AST::Local::Fetch');
            isa_ok($value->lhs->rhs->rhs, 'B::MOP::AST::Const');
            isa_ok($value->rhs, 'B::MOP::AST::Const');

            my $x = $value->lhs->rhs->lhs->pad_variable;
            isa_ok($x, 'B::MOP::Variable');
            is($x->name, '$x', '... got the expected name for $x');

            isa_ok($value->rhs->get_type, 'B::MOP::AST::Type::Int');
            is($value->rhs->get_literal, 20, '... got the expected literal');

            isa_ok($value->lhs->lhs->get_type, 'B::MOP::AST::Type::Int');
            is($value->lhs->lhs->get_literal, 100, '... got the expected literal');

            isa_ok($value->lhs->rhs->rhs->get_type, 'B::MOP::AST::Type::Int');
            is($value->lhs->rhs->rhs->get_literal, 5, '... got the expected literal');
        };
    };

};


done_testing;
