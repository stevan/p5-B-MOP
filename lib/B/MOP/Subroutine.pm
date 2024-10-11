
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

    field $subroutines_called :reader = [];

    ADJUST {
        $cv  = B::svref_2object($body);
        $ast = B::MOP::AST->new->build( $cv );
    }

    method signature { $ast->tree->signature }

    method fully_qualified_name { join '::' => $package->name, $name }

    method set_subroutines_called ($calls) { $subroutines_called = $calls }

    method depends_on ($s) {
        !! scalar grep {
            $s->fully_qualified_name eq $_->fully_qualified_name
        } @$subroutines_called;
    }

    method accept ($v) { $v->visit($self) }

    method to_JSON {
        +{
            'package' => $package->name,
            'name'    => $name,
            '@AST'     => $ast->tree->to_JSON,
        }
    }
}
