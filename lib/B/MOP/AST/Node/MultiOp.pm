
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::MultiOp :isa(B::MOP::AST::Node::Expression) {
    field $children :param :reader;

    method accept ($v) {
        $v->visit($self, map { $_->accept($v) } @$children);
    }
}
