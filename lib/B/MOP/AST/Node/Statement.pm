
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Statement :isa(B::MOP::AST::Node) {
    field $nextstate  :param :reader;
    field $expression :param :reader;

    method accept ($v) {
        $v->visit($self, $expression->accept($v));
    }
}
