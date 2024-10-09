
use v5.40;
use experimental qw[ class ];

use B::MOP::AST;

class B::MOP::Tools::PropogateTypeInformation {
    field $subroutine :param :reader;

    method visit ($node) {
        return $self->visit_local_store( $node ) if $node isa B::MOP::AST::Local::Store;
        return $self->visit_local_fetch( $node ) if $node isa B::MOP::AST::Local::Fetch;
        return $self->visit_numeric_op( $node )  if $node isa B::MOP::AST::Op::Numeric;
        return $self->visit_statement( $node )   if $node isa B::MOP::AST::Statement;
        return $self->visit_block( $node )       if $node isa B::MOP::AST::Block;
        return $self->visit_subroutine($node)    if $node isa B::MOP::AST::Subroutine;
    }

    method visit_subroutine ($node) {
        # TODO:
        # set the type of the subroutine ...
        # return type is the type of the last statement of block
        # arg types can be taken from the pad types
    }

    method visit_block ($node) {
        $node->set_type( $node->statements->[-1]->get_type );
    }

    method visit_statement ($node) {
        $node->set_type( $node->expression->get_type );
    }

    method visit_local_fetch ($node) {
        my $node_type = $node->get_type;

        if ($node->has_pad_target) {
            my $pad_target = $node->get_target;
            my $pad_type   = $pad_target->get_type;
            if (my $new_type = $node_type->cast($pad_type)) {
                $node->set_type($new_type);
            }
            else {
                die "TYPE ERROR: Cannot cast $node_type to $pad_type"
                    unless $node_type->is_same_type($pad_type);
            }
        }
    }

    method visit_local_store ($node) {
        my $node_type   = $node->get_type;
        my $target_type = $node->rhs->get_type;

        if (my $new_type = $node_type->cast($target_type)) {
            $node->set_type($new_type);

            if ($node->has_pad_target) {
                my $pad_target = $node->get_target;
                my $pad_type   = $pad_target->get_type;
                if (my $new_pad_type = $pad_type->cast($new_type)) {
                    $pad_target->set_type( $new_pad_type );
                }
                else {
                    die "TYPE ERROR: Cannot cast pad(".$pad_target->name.")[$pad_type] to $new_type"
                        unless $pad_type->is_same_type($new_type);
                }
            }
        }
        else {
            die "TYPE ERROR: Cannot cast $node_type to $target_type"
                unless $node_type->is_same_type($target_type);
        }
    }

    method visit_numeric_op ($node) {
        my $node_type = $node->get_type;
        my $lhs_type  = $node->lhs->get_type;
        my $rhs_type  = $node->rhs->get_type;

        say ">> node($node_type) = lhs($lhs_type) <op> rhs($rhs_type)";

        if ($lhs_type->is_same_type($rhs_type)) {
            say ">> lhs($lhs_type) == rhs($rhs_type)";
            if (my $new_type = $node_type->cast($lhs_type)) {
                say ">> new($new_type) for $node";
                $node->set_type($new_type);
            }
            else {
                say ">> could not cast $node_type to lhs($lhs_type) for $node";
            }
        }
        else {
            say ">> lhs($lhs_type) != rhs($rhs_type)";
        }
    }
}
