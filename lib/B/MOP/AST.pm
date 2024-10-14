
use v5.40;
use experimental qw[ class ];

use B::MOP::Type;
use B::MOP::Opcode;

use B::MOP::AST::Node;
use B::MOP::AST::SymbolTable;
use B::MOP::AST::Visitor;

use B::MOP::AST::Node::Subroutine;
use B::MOP::AST::Node::Statement;
use B::MOP::AST::Node::Local;
use B::MOP::AST::Node::Glob;
use B::MOP::AST::Node::Const;
use B::MOP::AST::Node::Call;
use B::MOP::AST::Node::Block;
use B::MOP::AST::Node::Argument;
use B::MOP::AST::Node::BinOp::Assign;
use B::MOP::AST::Node::BinOp::Numeric;

class B::MOP::AST {
    use constant DEBUG => $ENV{DEBUG_AST} // 0;

    field $cv   :reader;
    field $env  :reader;
    field $tree :reader;

    my sub collect_pad ($cv) {
        my ($pad) = $cv->PADLIST->ARRAY;
        return [ $pad isa B::NULL ? () : $pad->ARRAY ];
    }

    my sub collect_ops ($cv) {
        my @ops;
        my $next = $cv->START;
        until ($next isa B::NULL) {
            push @ops => B::MOP::Opcode->get( $next );
            $next = $next->next;
        }
        return @ops;
    }

    my sub collect_args ($mark) {
        die "collect_args(PUSHMARK)"
            unless $mark isa B::MOP::Opcode::PUSHMARK;
        my @args;
        my $next = $mark->sibling;
        while (defined $next) {
            push @args => $next;
            $next = $next->sibling;
        }
        return @args;
    }

    method build ($c) {
        $cv  = $c;
        $env = B::MOP::AST::SymbolTable->new( pad => collect_pad($cv) );

        my @ops  = collect_ops($cv);
        my $exit = pop @ops;

        if (DEBUG) {
            my $line_no = 0;
            say ">> ",$cv->GV->NAME," --------------------------------------------";
            say join "\n" => map {sprintf ' %03d : %s', $line_no++, $_->DUMP } @ops;
            say "<< ",$cv->GV->NAME," --------------------------------------------";
        }

        $tree = B::MOP::AST::Node::Subroutine->new(
            exit  => $exit,
            block => B::MOP::AST::Node::Block->new(
                statements => [
                    map  {     $self->build_statement( $_ ) }
                    grep { $_ isa B::MOP::Opcode::NEXTSTATE }
                    @ops
                ]
            )
        );

        $self;
    }

    method build_statement ($nextstate) {
        return B::MOP::AST::Node::Statement->new(
            nextstate  => $nextstate,
            expression => $self->build_expression(
                $nextstate->sibling
            )
        );
    }

    method build_expression ($op) {
        ## ---------------------------------------------------------------------
        ## constants
        ## ---------------------------------------------------------------------
        if ($op isa B::MOP::Opcode::CONST) {
            return B::MOP::AST::Node::Const->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Math Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ADD) {
            my $node_class = 'B::MOP::AST::Node::BinOp::Add';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::Add';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::MULTIPLY) {
            my $node_class = 'B::MOP::AST::Node::BinOp::Multiply';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::Multiply';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SUBTRACT) {
            my $node_class = 'B::MOP::AST::Node::BinOp::Subtract';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::Subtract';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        ## ---------------------------------------------------------------------
        ## Pad Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::PADSV) {
            my $node_class = 'B::MOP::AST::Node::Local::Fetch';
            if ($op->flags->is_declaration) {
                $node_class = 'B::MOP::AST::Node::Local::Declare';
            }
            return $node_class->new( env => $env, op => $op );
        }
        elsif ($op isa B::MOP::Opcode::PADSV_STORE) {
            my $node_class = 'B::MOP::AST::Node::Local::Store';
            if ($op->flags->is_declaration) {
                $node_class = 'B::MOP::AST::Node::Local::Declare::AndStore';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                rhs => $self->build_expression( $op->first ),
            );
        }
        elsif ($op isa B::MOP::Opcode::PADAV) {
            return B::MOP::AST::Node::Local::Fetch->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Sub arg Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ARGCHECK) {
            my ($params, $optional_params, $slurpiness) = $op->get_aux_list($cv);
            return B::MOP::AST::Node::Argument::Check->new(
                env             => $env,
                op              => $op,
                params          => $params,
                optional_params => $optional_params,
                slurpiness      => $slurpiness,
            );
        }
        elsif ($op isa B::MOP::Opcode::ARGELEM) {
            return B::MOP::AST::Node::Argument::Element->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Call Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ENTERSUB) {
            my $mark = $op->first;
            my @args = collect_args($mark);
            my $glob = $args[-1]->next;

            return B::MOP::AST::Node::Call::Subroutine->new(
                env  => $env,
                op   => $op,
                glob => $glob->gv,
                args => [ map { $self->build_expression( $_ ) } @args ]
            );
        }
        ## ---------------------------------------------------------------------
        ## Assignment
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::SASSIGN) {
            return B::MOP::AST::Node::BinOp::Assign->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->last ),
                rhs => $self->build_expression( $op->first ),
            );
        }
        ## ---------------------------------------------------------------------
        ## Array Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::AELEMFAST_LEX) {
            return B::MOP::AST::Node::Local::Array::Element::Const->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Glob Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::GV) {
            return B::MOP::AST::Node::Glob::Fetch->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        else {
            say "(((((--------------------------)))))";
            say "!! Cannot find AST node for: $op";
            say "   ",$op->DUMP;
            say "       `--> next: ",$op->next->DUMP;
            say "(((((--------------------------)))))";
            die;
        }
    }

    method accept ($v) { $tree->accept($v) }

    method to_JSON ($full=false) {
        +{
            env  => $env->to_JSON($full),
            tree => $tree->to_JSON,
        }
    }
}

