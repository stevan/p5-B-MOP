
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp :isa(B::MOP::AST::Node::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        $rhs->accept($v);
        $lhs->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            lhs => $lhs->to_JSON,
            rhs => $rhs->to_JSON,
        }
    }
}
