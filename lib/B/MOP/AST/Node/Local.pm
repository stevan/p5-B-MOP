
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Local::Scalar :isa(B::MOP::AST::Node::Expression) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Scalar->new);
    }
}

class B::MOP::AST::Node::Local::Fetch :isa(B::MOP::AST::Node::Local::Scalar) {}
class B::MOP::AST::Node::Local::Store :isa(B::MOP::AST::Node::Local::Scalar) {
    field $rhs :param :reader;

    method accept ($v) {
        $rhs->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            rhs => $rhs->to_JSON,
        }
    }
}

class B::MOP::AST::Node::Local::Declare           :isa(B::MOP::AST::Node::Local::Fetch) {}
class B::MOP::AST::Node::Local::Declare::AndStore :isa(B::MOP::AST::Node::Local::Store) {}


class B::MOP::AST::Node::Local::Array::Element::Const :isa(B::MOP::AST::Node::Expression) {}
