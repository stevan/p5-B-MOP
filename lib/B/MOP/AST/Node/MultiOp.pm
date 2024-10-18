
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::MultiOp :isa(B::MOP::AST::Node::Expression) {
    field $children :param :reader;

    method accept ($v) {
        $v->visit($self, map { $_->accept($v) } @$children);
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            children => [ map $_->to_JSON($full), @$children ]
        }
    }
}
