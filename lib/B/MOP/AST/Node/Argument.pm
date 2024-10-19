
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Argument::Check :isa(B::MOP::AST::Node::Expression) {
    field $params          :param :reader;
    field $optional_params :param :reader;
    field $slurpiness      :param :reader; # can be: '\0', '@' or '%'

    ADJUST {
        $self->type_var->resolve(B::MOP::Type::Void->new);
    }
}

class B::MOP::AST::Node::Argument::Element :isa(B::MOP::AST::Node::Expression) {
    ADJUST {
        # TODO: check for types other than scalar
        $self->type_var->resolve(B::MOP::Type::Scalar->new);
        $self->target->mark_as_argument;
    }
}
