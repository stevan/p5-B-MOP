
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;

class B::MOP::Subroutine {
    field $name :param :reader;
    field $body :param :reader;

    field $cv  :reader;
    field $ast :reader;

    ADJUST {
        $cv  = B::svref_2object($body);
        $ast = B::MOP::AST->new->build( $cv );
    }
}
