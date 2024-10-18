
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp::Assign :isa(B::MOP::AST::Node::BinOp) {}

class B::MOP::AST::Node::BinOp::Assign::Scalar :isa(B::MOP::AST::Node::BinOp::Assign) {}
