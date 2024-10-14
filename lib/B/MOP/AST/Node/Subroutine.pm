
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Subroutine :isa(B::MOP::AST::Node) {
    field $block :param :reader;
    field $exit  :param :reader;

    method accept ($v) {
        $block->accept($v);
        $v->visit($self);
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            block => $block->to_JSON($full),
        }
    }
}
