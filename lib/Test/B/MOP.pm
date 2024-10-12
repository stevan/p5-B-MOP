
use v5.40;
use experimental qw[ builtin ];
use builtin      qw[ export_lexically ];

package Test::B::MOP {
    use Test::More;

    sub import (@) {
        export_lexically(
            '&check_env'             => \&check_env,
            '&check_signature'       => \&check_signature,
            '&check_statement_types' => \&check_statement_types,
            '&check_type_error'      => \&check_type_error,
        );
    }

    sub check_env ($sub, @spec) {
        my $ast = $sub->ast;
        subtest '... checking env' => sub {
            my @symbols = $ast->env->get_all_symbols;

            is(scalar(@symbols), scalar(@spec), '... correct # of symbols - got('.(scalar @symbols).') expected('.(scalar @spec).')');

            foreach my ($i, $entry) (indexed @symbols) {
                my ($name, $type) = $spec[$i]->@*;
                is($name, $entry->name, "... got the right name for arg[$i]($name) - got($name) expected(".$entry->name.")");
                ok($type->is_exactly($entry->type->type), "... got the right type for arg[$i]($name) - got($type) expected(".$entry->type->type.")");
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
                my ($name, $type) = $param_spec->[$i]->@*;
                is($name, $param->name, "... got the right name for param[$i]($name) - got($name) expected(".$param->name.")");
                ok($type->is_exactly($param->type->type), "... got the right type for param[$i]($name) - got($type) expected(".$param->type->type.")");
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
                ok($type->is_exactly($statement->type->type), "... got the right type for statement[$i] - got($type) expected(".$statement->type->type.")");
            }
        }
    }

    sub check_type_error ($node, $error_rel) {
        subtest '... checking type error' => sub {
            my $type_var = $node->type;
            isa_ok($type_var, 'B::MOP::Type::Variable');
            ok($type_var->has_error, "... the type($type_var) has an error");

            my $error = $type_var->err;
            isa_ok($error, 'B::MOP::Type::Error');

            is($node->name, $error->node->name, '... error node and node are the same');
            is($error_rel->to_string, $error->rel->to_string, '... got the expected error');
        }
    }

}
