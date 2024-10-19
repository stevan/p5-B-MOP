
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Call :isa(B::MOP::AST::Node::Expression) {
    field $glob :param :reader;
    field $args :param :reader;

    field $subroutine :reader;

    method arity { scalar @$args }

    method is_resolved { !! $subroutine }
    method resolve_call ($sub) { $subroutine = $sub }

    method accept ($v) {
        $v->visit($self, map { $_->accept($v) } @$args);
    }
}

class B::MOP::AST::Node::Call::Subroutine :isa(B::MOP::AST::Node::Call) {}
