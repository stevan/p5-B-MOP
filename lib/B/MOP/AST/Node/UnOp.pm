
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::UnOp :isa(B::MOP::AST::Node::Expression) {
    field $operand :param :reader;

    method accept ($v) {
        $v->visit($self, $operand->accept($v));
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            operand => $operand->to_JSON($full),
        }
    }
}
