
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp::Boolean :isa(B::MOP::AST::Node::BinOp) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Bool->new);
    }
}

class B::MOP::AST::Node::BinOp::EqualTo     :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::NotEqualTo  :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::LessThan    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::GreaterThan :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::LessThan::OrEqualTo    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::GreaterThan::OrEqualTo :isa(B::MOP::AST::Node::BinOp::Boolean) {}

