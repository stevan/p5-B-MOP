
use v5.40;
use experimental qw[ class ];

use B::MOP::AST;

class B::MOP::Tools::CollectArguments {
    field $subroutine :param :reader;

    field @parameters;

    method visit ($node) {
        return $self->visit_argument_check($node)   if $node isa B::MOP::AST::Argument::Check;
        return $self->visit_argument_element($node) if $node isa B::MOP::AST::Argument::Element;
        return $self->visit_subroutine($node)       if $node isa B::MOP::AST::Subroutine;
    }

    method visit_argument_check ($node) {
        # TODO: this is useful perhaps ...
    }

    method visit_argument_element ($node) {
        my $param = $node->get_target;
        $param->mark_as_argument;
        push @parameters => $param;
    }

    method visit_subroutine ($node) {
        $node->set_signature(
            B::MOP::AST::Subroutine::Signature->new(
                parameters => \@parameters
            )
        );
    }
}
