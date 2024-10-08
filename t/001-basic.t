#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B;
use B::MOP;

package Foo {
    sub test {
        my $x;
        $x = 10;
        my $y = 100 + $x;
    }
}

subtest '... simple' => sub {
    my $root = B::MOP->new->load('Foo');
    my $Foo  = $root->get_package('Foo');
    my $test = $Foo->get_subroutine('test');
    my $ast  = $test->ast;

    isa_ok($root, 'B::MOP');
    isa_ok($Foo,  'B::MOP::Package');
    isa_ok($test, 'B::MOP::Subroutine');
    isa_ok($ast,  'B::MOP::AST::Subroutine');

    say Dump( $test->ast->to_JSON );
};


done_testing;
