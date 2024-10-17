
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::UnOp::Numeric :isa(B::MOP::AST::Node::UnOp) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Numeric->new);
    }
}

class B::MOP::AST::Node::UnOp::PostIncrement :isa(B::MOP::AST::Node::UnOp::Numeric) {}
class B::MOP::AST::Node::UnOp::PreIncrement  :isa(B::MOP::AST::Node::UnOp::Numeric) {}

class B::MOP::AST::Node::UnOp::PostDecrement :isa(B::MOP::AST::Node::UnOp::Numeric) {}
class B::MOP::AST::Node::UnOp::PreDecrement  :isa(B::MOP::AST::Node::UnOp::Numeric) {}


