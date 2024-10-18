
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Reference :isa(B::MOP::AST::Node::UnOp) {
    ADJUST {
        $self->type->resolve(
            B::MOP::Type::Ref->new(inner_type => B::MOP::Type::Scalar->new)
        );
    }
}

class B::MOP::AST::Node::Reference::Scalar::Construct :isa(B::MOP::AST::Node::Reference) {}

class B::MOP::AST::Node::Reference::Scalar::Dereference :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::Scalar->new) }
}

