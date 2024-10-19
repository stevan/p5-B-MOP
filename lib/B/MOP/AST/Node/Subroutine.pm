
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Subroutine :isa(B::MOP::AST::Node) {
    field $block :param :reader;
    field $exit  :param :reader;

    method accept ($v) {
        $v->visit($self, $block->accept($v));
    }
}
