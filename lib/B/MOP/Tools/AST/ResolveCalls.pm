
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::ResolveCalls {
    field $mop :param :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Node::Call::Subroutine;
        my $cv  = $node->glob->cv;
        my $pkg = $mop->get_package( $cv->stash_name );
        my $sub = $pkg->get_subroutine( $cv->name );

        if ($sub->check_arity($node->arity)) {
            $node->resolve_call($sub);
        }
        else {
            die "Unable to resolve call for ".$cv->fully_qualified_name
                ." because of arity mismatch, got(".$node->arity
                .") expected(".$sub->arity.")";
        }
    }
}
