
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Glob::Fetch :isa(B::MOP::AST::Node::Expression) {
    method glob { $self->op->gv }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            '&NAME' => $self->op->gv->name,
        }
    }
}
