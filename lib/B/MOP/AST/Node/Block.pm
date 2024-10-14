
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Block :isa(B::MOP::AST::Node) {
    field $statements :param :reader;

    method accept ($v) {
        $_->accept($v) foreach @$statements;
        $v->visit($self);
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            statements => [ map $_->to_JSON($full), @$statements ]
        }
    }
}
