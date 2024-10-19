
use v5.40;
use experimental qw[ builtin ];
use builtin      qw[ export_lexically ];

use B::MOP::Tools::AST::CollectAllTypes;

package Test::B::MOP {
    use constant DUMP_FULL_JSON => $ENV{DUMP_FULL_JSON} // 0;

    use Test::More;
    use JSON ();

    sub import (@) {
        export_lexically(
            '&check_env'             => \&check_env,
            '&check_signature'       => \&check_signature,
            '&check_statement_types' => \&check_statement_types,
            '&check_type_error'      => \&check_type_error,
            '&node_to_json'          => \&node_to_json,
            '&check_all_types'       => \&check_all_types,
        );
    }

    our $JSON = JSON->new->utf8->canonical->pretty;

    sub node_to_json ($node, $full=false) {
        $JSON->encode($node->to_JSON( $full || DUMP_FULL_JSON ))
    }

    sub check_env ($sub, @spec) {
        my $ast = $sub->ast;
        subtest '... checking env' => sub {
            my @symbols = $ast->env->get_all_symbols;

            is(scalar(@symbols), scalar(@spec), '... correct # of symbols - got('.(scalar @symbols).') expected('.(scalar @spec).')');

            foreach my ($i, $entry) (indexed @symbols) {
                if (defined $spec[$i]) {
                    my ($name, $type) = $spec[$i]->@*;
                    is($name, $entry->name, "... got the right name for arg[$i]($name) - got($name) expected(".$entry->name.")");
                    ok($type->is_exactly($entry->type_var->type), "... got the right type for arg[$i]($name) - got($type) expected(".$entry->type_var->type.")");
                }
                else {
                    fail("... no type provided for entry(".$entry->name.") expected(".$entry->type_var->type.")");
                }
            }
        }
    }

    sub check_signature ($sub, $param_spec, $return_type) {
        my $signature = $sub->signature;
        subtest '... checking signature' => sub {
            my $return = $signature->return_type;
            my @params = $signature->parameters->@*;

            is(scalar(@params), scalar(@$param_spec), '... correct # of params - got('.(scalar @params).') expected('.(scalar @$param_spec).')');

            foreach my ($i, $param) (indexed @params) {
                if (defined $param_spec->[$i]) {
                    my ($name, $type) = $param_spec->[$i]->@*;
                    is($name, $param->name, "... got the right name for param[$i]($name) - got($name) expected(".$param->name.")");
                    ok($type->is_exactly($param->type_var->type), "... got the right type for param[$i]($name) - got($type) expected(".$param->type_var->type.")");
                }
                else {
                    fail("... no type provided for param(".$param->name.") expected(".$param->type_var->type.")");
                }
            }

            ok($return_type->is_exactly($return->type), "... got the right return type - got($return_type) expected(".$return->type.")");
        }
    }

    sub check_statement_types ($sub, @spec) {
        my $ast = $sub->ast;
        subtest '... checking statement types' => sub {
            my @statements = $ast->tree->block->statements->@*;

            is(scalar(@statements), scalar(@spec), '... correct # of statements - got('.(scalar @statements).') expected('.(scalar @spec).')');

            foreach my ($i, $statement) (indexed @statements) {
                my $type = $spec[$i];
                if (defined $type) {
                    ok($type->is_exactly($statement->type_var->type), "... got the right type for statement[$i] - got($type) expected(".$statement->type_var->type.")");
                } else {
                    fail("... no type provided for statement(".$statement->name.") expected(".$statement->type_var->type.")");
                }
            }
        }
    }

    sub check_type_error ($node, $error_rel) {
        subtest '... checking type error' => sub {
            my $type_var = $node->type_var;
            isa_ok($type_var, 'B::MOP::Type::Variable');
            ok($type_var->has_error, "... the type($type_var) has an error");

            my $error = $type_var->err;
            isa_ok($error, 'B::MOP::Type::Error');

            is($node->name, $error->node->name, '... error node and node are the same');
            is($error_rel->to_string, $error->rel->to_string, '... got the expected error');
        }
    }

    sub check_all_types ($sub, @expected) {
        subtest '... checking all types' => sub {
            my $v   = B::MOP::Tools::AST::CollectAllTypes->new( subroutine => $sub );
            my @got = $v->collect_all_types;

            is(scalar(@got), scalar(@expected), '... correct # of type - got('.(scalar @got).') expected('.(scalar @expected).')');

            foreach my ($i, $type) (indexed @got) {
                my $expected_type = $expected[$i];
                if (defined $expected_type) {
                    ok($expected_type->is_exactly($type->type), "... got the right type got($expected_type) expected(".$type->type.")");
                }
                else {
                    fail("... no type provided expected(".$type->type.")");
                }
            }
        }
    }

}
