
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::MultiOp::String :isa(B::MOP::AST::Node::MultiOp) {
    ADJUST { $self->type_var->resolve(B::MOP::Type::String->new) }
}

class B::MOP::AST::Node::MultiOp::String::Concat :isa(B::MOP::AST::Node::MultiOp::String) {}

class B::MOP::AST::Node::MultiOp::String::Concat::AndAssign  :isa(B::MOP::AST::Node::MultiOp::String) {}
class B::MOP::AST::Node::MultiOp::String::Concat::AndDeclare :isa(B::MOP::AST::Node::MultiOp::String) {}

