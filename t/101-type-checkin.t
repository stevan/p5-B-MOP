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
        my $z = $x + $y;
    }
}

my $Foo = B::MOP->new->load_package('Foo');
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    $test->ast->accept(B::MOP::AST::Visitor->new( f => sub ($n) {
        if ($n->has_type) {
            say Dump [ $n->get_type->name, $n->to_JSON ];
        } else {
            say Dump [ "NO TYPE", $n->to_JSON ];
        }
    }));

};


done_testing;
