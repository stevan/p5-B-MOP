
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Loop :isa(B::MOP::AST::Node::Expression) {
    field $statements :param :reader;

    method accept ($v) {
        $v->visit($self, map { $_->accept($v) } @$statements);
    }
}
