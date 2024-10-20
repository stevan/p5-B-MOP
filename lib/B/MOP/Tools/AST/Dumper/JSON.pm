
use v5.40;
use experimental qw[ class ];

use JSON ();

class B::MOP::Tools::AST::Dumper::JSON {
    field $subroutine :param :reader;

    our $JSON = JSON->new->utf8->canonical->pretty;

    method dump_JSON { return $JSON->encode($self->dump) }

    # ...

    my sub entry_to_JSON ($entry) {
        return +{
            name        => $entry->name,
            type        => $entry->type_var->stringify,
            '$location' => ($entry->is_argument ? 'ARGUMENT' : 'LOCAL'),
            '@range'    => (sprintf '%d..%d', $entry->get_scope_range),
            '@trace'    => [ map { join ' : ' => $_->name, $_->type_var->stringify } $entry->get_full_trace ]
        }
    }

    my sub env_to_JSON ($env) {
        return +{ entries => [ map entry_to_JSON($_), $env->get_all_symbols ] }
    }

    my sub target_to_JSON ($target) {
        return if !$target;
        return ('$target' => +{
            name => $target->name,
            type => $target->type_var->stringify,
        });
    }

    my sub node_to_JSON($node, %rest) {
        return +{
            node => $node->name,
            type => $node->type_var->stringify,
            %rest,
        }
    }

    my sub expr_to_JSON($node, %rest) {
        node_to_JSON(
            $node,
            target_to_JSON( $node->target ),
            %rest
        )
    }

    ## ...

    method dump {
        my $env = env_to_JSON( $subroutine->ast->env );
        my $ast = $subroutine->ast->accept($self);
        return +{
            stash  => $subroutine->package->name,
            name   => $subroutine->name,
            '%env' => $env,
            '@ast' => $ast,
        };
    }

    method visit ($node, @acc) {
        return $self->visit_const($node, @acc)          if $node isa B::MOP::AST::Node::Const
                                                        || $node isa B::MOP::AST::Node::Const::Literal;
        return $self->visit_local_store($node, @acc)    if $node isa B::MOP::AST::Node::Local::Store;
        return $self->visit_unop($node, @acc)           if $node isa B::MOP::AST::Node::UnOp;
        return $self->visit_binop($node, @acc)          if $node isa B::MOP::AST::Node::BinOp;
        return $self->visit_multiop($node, @acc)        if $node isa B::MOP::AST::Node::MultiOp;
        return $self->visit_call($node, @acc)           if $node isa B::MOP::AST::Node::Call;
        return $self->visit_block($node, @acc)          if $node isa B::MOP::AST::Node::Block;
        return $self->visit_loop($node, @acc)           if $node isa B::MOP::AST::Node::Loop;
        return $self->visit_statement($node, @acc)      if $node isa B::MOP::AST::Node::Statement;
        return $self->visit_subroutine($node, @acc)     if $node isa B::MOP::AST::Node::Subroutine;

        # catch other stuff ...
        return $self->visit_expression($node, @acc)     if $node isa B::MOP::AST::Node::Expression;
        return;
    }

    method visit_expression ($node, @acc) {
        expr_to_JSON($node)
    }

    method visit_multiop ($node, @acc) {
        expr_to_JSON($node, children => \@acc )
    }

    method visit_const ($node, @acc) {
        expr_to_JSON($node, literal => $node->get_literal // 'undef' )
    }

    method visit_local_store ($node, @acc) {
        my ($rhs) = @acc;
        expr_to_JSON($node, rhs => $rhs )
    }

    method visit_unop ($node, @acc) {
        my ($operand) = @acc;
        expr_to_JSON($node, operand => $operand )
    }

    method visit_binop ($node, @acc) {
        my ($lhs, $rhs) = @acc;
        expr_to_JSON($node, lhs => $lhs, rhs => $rhs )
    }

    method visit_block ($node, @acc) {
        node_to_JSON($node, statements => \@acc )
    }

    method visit_call ($node, @acc) {
        expr_to_JSON($node,
            callee  => $node->glob->name,
            '@args' => \@acc,
            ($node->is_resolved
                ? ('&resolved' => $node->subroutine->fully_qualified_name)
                : ())
        )
    }

    method visit_loop ($node, @acc) {
        expr_to_JSON($node, statements => \@acc )
    }

    method visit_subroutine ($node, @acc) {
        my ($block) = @acc;
        node_to_JSON($node, block => $block)
    }

    method visit_statement ($node, @acc) {
        my ($expr) = @acc;
        node_to_JSON($node,
            sequence_id => $node->nextstate->sequence_id,
            expression  => $expr
        )
    }


}
