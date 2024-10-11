
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

    method fully_qualified_name { join '::' => $package->name, $name }

    method set_subroutines_called ($calls) { $subroutines_called = $calls }

    method accept ($v) { $v->visit($self) }
}
