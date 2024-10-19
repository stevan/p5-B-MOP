
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Block :isa(B::MOP::AST::Node) {
    field $statements :param :reader;

    method accept ($v) {
        $v->visit($self, map { $_->accept($v) } @$statements);
    }
}
