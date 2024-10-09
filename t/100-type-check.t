#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;

package Foo {
    sub test {
        my $x = 10;
        my $y = $x;
        my $z = $y;
    }
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    subtest '... testing the pad' => sub {
        my ($x, $y, $z) = $test->pad_variables;
        isa_ok($x, 'B::MOP::Variable');
        is($x->name, '$x', '... got the expected name for $x');
        isa_ok($x->get_type, 'B::MOP::Type::Int');

        isa_ok($y, 'B::MOP::Variable');
        is($y->name, '$y', '... got the expected name for $y');
        isa_ok($y->get_type, 'B::MOP::Type::Int');

        isa_ok($z, 'B::MOP::Variable');
        is($z->name, '$z', '... got the expected name for $z');
        isa_ok($z->get_type, 'B::MOP::Type::Int');
    };

    subtest '... testing the AST' => sub {
        my $ast  = $test->ast;
        isa_ok($ast,  'B::MOP::AST::Subroutine');

        my $block = $ast->block;
        isa_ok($block, 'B::MOP::AST::Block');

        my ($assign_x, $assign_y, $assign_z) = $block->statements->@*;

        subtest '... testing first statement' => sub {
            isa_ok($assign_x, 'B::MOP::AST::Statement');
            isa_ok($assign_x->expression, 'B::MOP::AST::Local::Store');
            my $value = $assign_x->expression->rhs;
            isa_ok($value, 'B::MOP::AST::Const');

            ok($assign_x->expression->has_type, '.. the expression has a type');
            isa_ok($assign_x->expression->get_type, 'B::MOP::Type::Int');

            my $x = $assign_x->expression->pad_variable;
            isa_ok($x, 'B::MOP::Variable');
            is($x->name, '$x', '... got the expected name for $x');

            isa_ok($value->get_type, 'B::MOP::Type::Int');
            is($value->get_literal, 10, '... got the expected literal');
        };

        subtest '... testing second statement' => sub {
            isa_ok($assign_y, 'B::MOP::AST::Statement');
            isa_ok($assign_y->expression, 'B::MOP::AST::Local::Store');

            ok($assign_y->expression->has_type, '.. the expression has a type');
            isa_ok($assign_y->expression->get_type, 'B::MOP::Type::Int');

            my $value = $assign_y->expression->rhs;
            isa_ok($value, 'B::MOP::AST::Local::Fetch');

            ok($assign_y->expression->rhs->has_type, '.. the expression has a type');
            isa_ok($assign_y->expression->rhs->get_type, 'B::MOP::Type::Int');

            my $x = $value->pad_variable;
            isa_ok($x, 'B::MOP::Variable');
            is($x->name, '$x', '... got the expected name for $x');

            my $y = $assign_y->expression->pad_variable;
            isa_ok($y, 'B::MOP::Variable');
            is($y->name, '$y', '... got the expected name for $y');
        };

        subtest '... testing third statement' => sub {
            isa_ok($assign_z, 'B::MOP::AST::Statement');
            isa_ok($assign_z->expression, 'B::MOP::AST::Local::Store');

            ok($assign_z->expression->has_type, '.. the expression has a type');
            isa_ok($assign_z->expression->get_type, 'B::MOP::Type::Int');

            my $value = $assign_z->expression->rhs;
            isa_ok($value, 'B::MOP::AST::Local::Fetch');

            ok($assign_z->expression->rhs->has_type, '.. the expression has a type');
            isa_ok($assign_z->expression->rhs->get_type, 'B::MOP::Type::Int');

            my $y = $value->pad_variable;
            isa_ok($y, 'B::MOP::Variable');
            is($y->name, '$y', '... got the expected name for $y');

            my $z = $assign_z->expression->pad_variable;
            isa_ok($z, 'B::MOP::Variable');
            is($z->name, '$z', '... got the expected name for $z');
        };
    };

};


done_testing;
