
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- the multiconcat op
    - with a nested multiconcat

=cut

package Foo {
    sub test {
        my $x = "foo";
        my $y = "bar";
        my $z = $x . ($x . "baz") . $y;
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
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
    );

    subtest '... testing last statement' => sub {
        my $declare_z = $test->ast->tree->block->statements->[-1]->expression;
        isa_ok($declare_z, 'B::MOP::AST::Node::MultiOp::String::Concat::AndDeclare');

        # my $z = $x . ($x . "baz") . $y;
        my (
            $fetch_x,
            $multiconcat,
            $fetch_y
        ) = $declare_z->children->@*;

        isa_ok($fetch_x, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_x->target->name, '$x', '... got the expected name');
        isa_ok($fetch_y, 'B::MOP::AST::Node::Local::Fetch');
        is($fetch_y->target->name, '$y', '... got the expected name');

        subtest '... testing nested multiconcat' => sub {
            isa_ok($multiconcat, 'B::MOP::AST::Node::MultiOp::String::Concat');

            # ($x . "baz");
            my (
                $fetch_x,
                $baz_const,
            ) = $multiconcat->children->@*;

            isa_ok($fetch_x, 'B::MOP::AST::Node::Local::Fetch');
            is($fetch_x->target->name, '$x', '... got the expected name');

            isa_ok($baz_const, 'B::MOP::AST::Node::Const::Literal');
            is($baz_const->literal, 'baz', '... got the expected literal');

        };
    };

    say node_to_json($test) if $ENV{DEBUG};
};


done_testing;
