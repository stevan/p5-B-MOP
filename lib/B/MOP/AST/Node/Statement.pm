
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Statement :isa(B::MOP::AST::Node) {
    field $nextstate  :param :reader;
    field $expression :param :reader;

    method accept ($v) {
        $v->visit($self, $expression->accept($v));
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            sequence_id => $nextstate->sequence_id,
            expression  => $expression->to_JSON($full)
        }
    }
}
