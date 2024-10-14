
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Expression :isa(B::MOP::AST::Node) {
    field $env :param :reader;
    field $op  :param :reader;

    field $target :reader;

    ADJUST {
        if ($op->has_target) {
            $target = $env->get_symbol_by_index( $op->target_index );
            $target->trace( $self );
        }
    }

    method has_target { !! $target }

    method to_JSON ($full=false) {
        return +{
            $self->SUPER::to_JSON($full)->%*,
            ($target && !$target->is_temporary ? ('$target' => $target->to_JSON($full)) : ()),
        }
    }
}
