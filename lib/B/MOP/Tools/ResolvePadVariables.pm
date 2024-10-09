
use v5.40;
use experimental qw[ class ];

use B::MOP::AST;

class B::MOP::Tools::ResolvePadVariables {
    field $subroutine :param :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Expression;
        return unless $node->has_pad_target;
        return if $node->has_target;
        my $target = $subroutine->pad_lookup( $node->pad_target_index );
        $node->set_target($target);
    }
}
