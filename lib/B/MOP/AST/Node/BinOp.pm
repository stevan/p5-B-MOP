
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp :isa(B::MOP::AST::Node::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        $v->visit($self, $lhs->accept($v), $rhs->accept($v));
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            lhs => $lhs->to_JSON($full),
            rhs => $rhs->to_JSON($full),
        }
    }
}
