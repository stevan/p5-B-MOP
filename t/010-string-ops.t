
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

package Foo {
    sub test {
        my $x = "foo";
        my $y = "bar";
        my $z = $x . "test" . $y . "baz" . $x;
        $y = $x . "test";
        $z .= $x . "test" . $y;
        my $r = "test" . $y . "bar" . $z . $x;
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    check_env($test,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$r', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
    );

    my (
        $declare_z,
        $set_y,
        $set_z,
        $declare_r
    ) = grep $_ isa B::MOP::AST::Node::MultiOp,
        map $_->expression,
        $test->ast->tree->block->statements->@*;

    subtest '... test statement 1' => sub {
        isa_ok($declare_z, 'B::MOP::AST::Node::MultiOp::String::Concat::AndDeclare');

        # my $z = $x . "test" . $y . "baz" . $x;
        my (
            $fetch_x1,
            $test_const,
            $fetch_y,
            $baz_const,
            $fetch_x2
        ) = $declare_z->children->@*;

        isa_ok($fetch_x1, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x1->target->name, '$x', '... got the expected name');
        isa_ok($test_const, 'B::MOP::AST::Node::Const::Literal');
        is($test_const->literal, 'test', '... got the expected literal');
        isa_ok($fetch_y, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_y->target->name, '$y', '... got the expected name');
        isa_ok($baz_const, 'B::MOP::AST::Node::Const::Literal');
        is($baz_const->literal, 'baz', '... got the expected literal');
        isa_ok($fetch_x2, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x2->target->name, '$x', '... got the expected name');
    };


    subtest '... test statement 2' => sub {
        isa_ok($set_y, 'B::MOP::AST::Node::MultiOp::String::Concat');

        # $y = $x . "test";
        my (
            $fetch_x,
            $test_const,
        ) = $set_y->children->@*;

        isa_ok($fetch_x, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x->target->name, '$x', '... got the expected name');
        isa_ok($test_const, 'B::MOP::AST::Node::Const::Literal');
        is($test_const->literal, 'test', '... got the expected literal');
    };

    subtest '... test statement 3' => sub {
        isa_ok($set_z, 'B::MOP::AST::Node::MultiOp::String::Concat');

        # $z .= $x . "test" . $y;
        my (
            $fetch_x,
            $test_const,
            $fetch_y,
        ) = $set_z->children->@*;

        isa_ok($fetch_x, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x->target->name, '$x', '... got the expected name');
        isa_ok($test_const, 'B::MOP::AST::Node::Const::Literal');
        is($test_const->literal, 'test', '... got the expected literal');
        isa_ok($fetch_y, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_y->target->name, '$y', '... got the expected name');
    };

    subtest '... test statement 4' => sub {
        isa_ok($declare_r, 'B::MOP::AST::Node::MultiOp::String::Concat::AndDeclare');

        # my $r = "test" . $y . "bar" . $z . $x;
        my (
            $test_const,
            $fetch_y,
            $bar_const,
            $fetch_z,
            $fetch_x,
        ) = $declare_r->children->@*;

        isa_ok($test_const, 'B::MOP::AST::Node::Const::Literal');
        is($test_const->literal, 'test', '... got the expected literal');
        isa_ok($fetch_y, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_y->target->name, '$y', '... got the expected name');
        isa_ok($bar_const, 'B::MOP::AST::Node::Const::Literal');
        is($bar_const->literal, 'bar', '... got the expected literal');
        isa_ok($fetch_z, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_z->target->name, '$z', '... got the expected name');
        isa_ok($fetch_x, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x->target->name, '$x', '... got the expected name');
    };

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
