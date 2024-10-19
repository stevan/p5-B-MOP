
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp :isa(B::MOP::AST::Node::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        $v->visit($self, $lhs->accept($v), $rhs->accept($v));
    }
}
