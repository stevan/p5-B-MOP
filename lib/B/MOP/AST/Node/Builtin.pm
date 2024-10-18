
use v5.40;
use experimental qw[ class ];

## Ints

class B::MOP::AST::Node::Builtin::Returns::Int :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::Int->new) }
}

class B::MOP::AST::Node::Builtin::Returns::Float :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::Float->new) }
}

class B::MOP::AST::Node::Builtin::Returns::Numeric :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::Numeric->new) }
}

class B::MOP::AST::Node::Builtin::Returns::String :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::String->new) }
}

class B::MOP::AST::Node::Builtin::Returns::Bool :isa(B::MOP::AST::Node::UnOp) {
    ADJUST { $self->type->resolve(B::MOP::Type::Bool->new) }
}

## Numerics ...

class B::MOP::AST::Node::Builtin::Int :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}

class B::MOP::AST::Node::Builtin::Hex :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}
class B::MOP::AST::Node::Builtin::Ord :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}
class B::MOP::AST::Node::Builtin::Oct :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}

class B::MOP::AST::Node::Builtin::Ceil  :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}
class B::MOP::AST::Node::Builtin::Floor :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}

class B::MOP::AST::Node::Builtin::Abs :isa(B::MOP::AST::Node::Builtin::Returns::Numeric) {}

class B::MOP::AST::Node::Builtin::Cos  :isa(B::MOP::AST::Node::Builtin::Returns::Float) {}
class B::MOP::AST::Node::Builtin::Exp  :isa(B::MOP::AST::Node::Builtin::Returns::Float) {}
class B::MOP::AST::Node::Builtin::Log  :isa(B::MOP::AST::Node::Builtin::Returns::Float) {}
class B::MOP::AST::Node::Builtin::Sin  :isa(B::MOP::AST::Node::Builtin::Returns::Float) {}
class B::MOP::AST::Node::Builtin::Sqrt :isa(B::MOP::AST::Node::Builtin::Returns::Float) {}

## Strings ...

class B::MOP::AST::Node::Builtin::Chr       :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::Fc        :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::Lc        :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::LcFirst   :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::Uc        :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::UcFirst   :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::Length    :isa(B::MOP::AST::Node::Builtin::Returns::Int)    {}
class B::MOP::AST::Node::Builtin::Quotemeta :isa(B::MOP::AST::Node::Builtin::Returns::String) {}

class B::MOP::AST::Node::Builtin::Chomp::Scalar :isa(B::MOP::AST::Node::Builtin::Returns::Int) {}
class B::MOP::AST::Node::Builtin::Chop::Scalar  :isa(B::MOP::AST::Node::Builtin::Returns::String) {}

## Objects ...

class B::MOP::AST::Node::Builtin::Blessed :isa(B::MOP::AST::Node::Builtin::Returns::String) {}

## Refs ...

class B::MOP::AST::Node::Builtin::Ref     :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::RefType :isa(B::MOP::AST::Node::Builtin::Returns::String) {}
class B::MOP::AST::Node::Builtin::RefAddr :isa(B::MOP::AST::Node::Builtin::Returns::Int)    {}

## Misc

class B::MOP::AST::Node::Builtin::Scalar :isa(B::MOP::AST::Node::UnOp) {}

class B::MOP::AST::Node::Builtin::Defined   :isa(B::MOP::AST::Node::Builtin::Returns::Bool) {}
class B::MOP::AST::Node::Builtin::IsWeak    :isa(B::MOP::AST::Node::Builtin::Returns::Bool) {}
class B::MOP::AST::Node::Builtin::IsTainted :isa(B::MOP::AST::Node::Builtin::Returns::Bool) {}
