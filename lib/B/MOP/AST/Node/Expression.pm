
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Expression :isa(B::MOP::AST::Node) {
    field $env :param :reader;
    field $op  :param :reader;

    field $target :reader;

    ADJUST {
        if ($op->has_target) {
            my $t = $env->get_symbol_by_index( $op->target_index );
            unless ($t->is_temporary) {
                $target = $t;
                $target->trace( $self );
            }
        }
    }

    method has_target { !! $target }
}
