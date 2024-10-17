
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp :isa(B::MOP::AST::Node::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        my @results;
        # evaluate the rhs first, ...
        unshift @results => $rhs->accept($v);
        # then the left ...
        unshift @results => $lhs->accept($v);
        $v->visit($self, @results);
    }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            lhs => $lhs->to_JSON($full),
            rhs => $rhs->to_JSON($full),
        }
    }
}
