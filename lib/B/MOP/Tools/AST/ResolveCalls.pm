
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::ResolveCalls {
    field $mop :param :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Call::Subroutine;
        my $cv  = $node->glob->cv;
        my $pkg = $mop->get_package( $cv->stash_name );
        my $sub = $pkg->get_subroutine( $cv->name );
        $node->resolve_call($sub);
    }
}
