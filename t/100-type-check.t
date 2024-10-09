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
            isa_ok($assign_x->get_type, 'B::MOP::Type::Int');

            my $exp = $assign_x->expression;
            isa_ok($exp, 'B::MOP::AST::Local::Store');
            isa_ok($exp->get_type, 'B::MOP::Type::Int');

            my $value = $exp->rhs;
            isa_ok($value, 'B::MOP::AST::Const');

            my $x = $exp->get_target;
            isa_ok($x, 'B::MOP::Variable');

            is($x->name, '$x', '... got the expected name for $x');
            isa_ok($x->get_type, 'B::MOP::Type::Int');

            isa_ok($value->get_type, 'B::MOP::Type::Int');
            is($value->get_literal, 10, '... got the expected literal');
        };

        subtest '... testing second statement' => sub {
            isa_ok($assign_y, 'B::MOP::AST::Statement');
            isa_ok($assign_y->get_type, 'B::MOP::Type::Int');

            my $exp = $assign_y->expression;
            isa_ok($exp, 'B::MOP::AST::Local::Store');
            isa_ok($exp->get_type, 'B::MOP::Type::Int');

            my $value = $exp->rhs;
            isa_ok($value, 'B::MOP::AST::Local::Fetch');
            isa_ok($exp->rhs->get_type, 'B::MOP::Type::Int');

            my $x = $value->get_target;
            isa_ok($x, 'B::MOP::Variable');

            is($x->name, '$x', '... got the expected name for $x');
            isa_ok($x->get_type, 'B::MOP::Type::Int');

            my $y = $exp->get_target;
            isa_ok($y, 'B::MOP::Variable');

            is($y->name, '$y', '... got the expected name for $y');
            isa_ok($y->get_type, 'B::MOP::Type::Int');
        };

        subtest '... testing third statement' => sub {
            isa_ok($assign_z, 'B::MOP::AST::Statement');
            isa_ok($assign_z->get_type, 'B::MOP::Type::Int');

            my $exp = $assign_z->expression;
            isa_ok($exp, 'B::MOP::AST::Local::Store');
            isa_ok($exp->get_type, 'B::MOP::Type::Int');

            my $value = $exp->rhs;
            isa_ok($value, 'B::MOP::AST::Local::Fetch');
            isa_ok($exp->rhs->get_type, 'B::MOP::Type::Int');

            my $y = $value->get_target;
            isa_ok($y, 'B::MOP::Variable');

            is($y->name, '$y', '... got the expected name for $y');
            isa_ok($y->get_type, 'B::MOP::Type::Int');

            my $z = $exp->get_target;
            isa_ok($z, 'B::MOP::Variable');

            is($z->name, '$z', '... got the expected name for $z');
            isa_ok($z->get_type, 'B::MOP::Type::Int');
        };
    };

    say Dump $test->ast->to_JSON if $ENV{DEBUG};
};


done_testing;
