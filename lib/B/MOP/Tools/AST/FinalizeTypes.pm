
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::FinalizeTypes {
    field $env :param :reader;

    our $JSON = JSON->new->utf8->canonical->pretty;

    method visit ($node, @) {
        if ($node isa B::MOP::AST::Node::Statement) {
            if ($node->expression isa B::MOP::AST::Node::MultiOp) {
                $node->set_type($node->expression->target->type);
            }
            else {
                $node->set_type($node->expression->type);
            }
        }
        elsif ($node isa B::MOP::AST::Node::Loop) {
            $node->set_type($node->statements->[-1]->type);
        }
        elsif ($node isa B::MOP::AST::Node::Block) {
            $node->set_type($node->statements->[-1]->type);
        }
        elsif ($node isa B::MOP::AST::Node::Subroutine) {
            $node->set_type($node->block->type);
        }
        else {
            unless ($node->type->is_resolved) {
                die join "\n" => (
                    "Found an unresolved type in node(".$node->name.")",
                    $JSON->encode($node->to_JSON(true)),
                );
            }

        }
        return;
    }
}
