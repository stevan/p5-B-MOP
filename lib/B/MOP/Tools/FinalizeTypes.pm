
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::FinalizeTypes {

    method visit ($node) {
        if ($node isa B::MOP::AST::Statement) {
            $node->set_type($node->expression->type);
        }
        elsif ($node isa B::MOP::AST::Block) {
            $node->set_type($node->statements->[-1]->type);
        }
        elsif ($node isa B::MOP::AST::Subroutine) {
            $node->set_type($node->block->type);
        }
    }
}
