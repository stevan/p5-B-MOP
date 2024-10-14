
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Visitor {
    field $f      :param;
    field $accept :param = undef;

    method visit ($node) {
        if ($accept) {
            $f->($node) if $node->isa($accept);
        }
        else {
            $f->($node);
        }
    }
}

