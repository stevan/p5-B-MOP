
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;

class B::MOP::Subroutine {
    field $package :param :reader;
    field $name    :param :reader;
    field $body    :param :reader;

    field $cv  :reader;
    field $ast :reader;

    field $signature;
    field $subroutines_called :reader = [];

    ADJUST {
        $cv        = B::svref_2object($body);
        $ast       = B::MOP::AST->new->build( $cv );
        $signature = B::MOP::Type::Signature->new;
    }

    method check_arity ($num_args) {
        my $arg_check = $ast->tree->block->statements->[0]->expression;
        if ($arg_check isa B::MOP::AST::Node::Argument::Check) {
            # TODO:
            # - handle optional params
            # - handle slupriness
            return $arg_check->params == $num_args;
        }
        else {
            return $num_args == 0;
        }
    }

    method signature            { $signature }
    method set_signature ($sig) { $signature = $sig }

    method fully_qualified_name { join '::' => $package->name, $name }

    method set_subroutines_called ($calls) { $subroutines_called = $calls }

    method depends_on ($s) {
        !! scalar grep {
            $s->fully_qualified_name eq $_->fully_qualified_name
        } @$subroutines_called;
    }

    method accept ($v) { $v->visit($self) }

    method to_JSON ($full=false) {
        +{
            stash  => $package->name,
            name   => $name,
            '%env' => $ast->env->to_JSON($full),
            '@ast' => $ast->tree->to_JSON($full),
        }
    }
}
