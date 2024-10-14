
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp::Numeric :isa(B::MOP::AST::Node::BinOp) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Numeric->new);
    }
}

class B::MOP::AST::Node::BinOp::Add      :isa(B::MOP::AST::Node::BinOp::Numeric) {}
class B::MOP::AST::Node::BinOp::Subtract :isa(B::MOP::AST::Node::BinOp::Numeric) {}
class B::MOP::AST::Node::BinOp::Multiply :isa(B::MOP::AST::Node::BinOp::Numeric) {}

class B::MOP::AST::Node::BinOp::Assign::Add      :isa(B::MOP::AST::Node::BinOp::Numeric) {}
class B::MOP::AST::Node::BinOp::Assign::Subtract :isa(B::MOP::AST::Node::BinOp::Numeric) {}
class B::MOP::AST::Node::BinOp::Assign::Multiply :isa(B::MOP::AST::Node::BinOp::Numeric) {}

