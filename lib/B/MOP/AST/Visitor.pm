
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Visitor {
    field $f :param;

    method visit ($node, @args) {
        [ $f->($node, @args) ]
    }
}

