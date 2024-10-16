
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::BinOp::Boolean :isa(B::MOP::AST::Node::BinOp) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Bool->new);
    }
}

# Numeric

# NOTE:
# should this be in a Numeric:: subnamespace?
# or does it not really matter since the type
# checker can operate on specific nodes

class B::MOP::AST::Node::BinOp::EqualTo     :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::NotEqualTo  :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::LessThan    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::GreaterThan :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::LessThan::OrEqualTo    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::GreaterThan::OrEqualTo :isa(B::MOP::AST::Node::BinOp::Boolean) {}

# String

class B::MOP::AST::Node::BinOp::String::EqualTo     :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::String::NotEqualTo  :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::String::LessThan    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::String::GreaterThan :isa(B::MOP::AST::Node::BinOp::Boolean) {}

class B::MOP::AST::Node::BinOp::String::LessThan::OrEqualTo    :isa(B::MOP::AST::Node::BinOp::Boolean) {}
class B::MOP::AST::Node::BinOp::String::GreaterThan::OrEqualTo :isa(B::MOP::AST::Node::BinOp::Boolean) {}

