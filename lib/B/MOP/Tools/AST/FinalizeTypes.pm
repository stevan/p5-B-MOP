
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::FinalizeTypes {
    field $env :param :reader;

    method visit ($node) {
        if ($node isa B::MOP::AST::Statement) {
            $node->set_type($node->expression->type);
        }
        elsif ($node isa B::MOP::AST::Block) {
            $node->set_type($node->statements->[-1]->type);
        }
        elsif ($node isa B::MOP::AST::Subroutine) {
            $node->set_type($node->block->type);

            $node->set_signature(
                B::MOP::Type::Signature->new(
                    parameters  => [ $env->get_all_arguments ],
                    return_type => $node->type,
                )
            );
        }
    }
}
