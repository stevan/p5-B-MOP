
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp::Logical :isa(B::MOP::AST::Node::BinOp) {}

class B::MOP::AST::Node::BinOp::Logical::And       :isa(B::MOP::AST::Node::BinOp::Logical) {}
class B::MOP::AST::Node::BinOp::Logical::Or        :isa(B::MOP::AST::Node::BinOp::Logical) {}
class B::MOP::AST::Node::BinOp::Logical::DefinedOr :isa(B::MOP::AST::Node::BinOp::Logical) {}
