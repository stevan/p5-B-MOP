
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Statement :isa(B::MOP::AST::Node) {
    field $nextstate  :param :reader;
    field $expression :param :reader;

    method accept ($v) {
        $expression->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            nextstate  => { nextstate => 1 },
            expression => $expression->to_JSON
        }
    }
}
