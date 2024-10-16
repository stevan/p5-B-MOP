
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
use B::MOP::AST::Node::BinOp::Boolean;
use B::MOP::AST::Node::MultiOp::String;

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

    my sub collect_multiconcat_children ($op) {
        die "collect_multiconcat_children(MULTICONCAT)"
            unless $op isa B::MOP::Opcode::MULTICONCAT;

        my @children;
        my $next = $op->first('next');
        while (defined $next) {
            push @children => $next;
            $next = $next->sibling;
        }
        return @children;
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
        ## Comparison Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::EQ) {
            return B::MOP::AST::Node::BinOp::EqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::NE) {
            return B::MOP::AST::Node::BinOp::NotEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::LT) {
            return B::MOP::AST::Node::BinOp::LessThan->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::LE) {
            return B::MOP::AST::Node::BinOp::LessThan::OrEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::GT) {
            return B::MOP::AST::Node::BinOp::GreaterThan->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::GE) {
            return B::MOP::AST::Node::BinOp::GreaterThan::OrEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        ## ---------------------------------------------------------------------
        ## String Comparison Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::SEQ) {
            return B::MOP::AST::Node::BinOp::String::EqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SNE) {
            return B::MOP::AST::Node::BinOp::String::NotEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SLT) {
            return B::MOP::AST::Node::BinOp::String::LessThan->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SLE) {
            return B::MOP::AST::Node::BinOp::String::LessThan::OrEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SGT) {
            return B::MOP::AST::Node::BinOp::String::GreaterThan->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SGE) {
            return B::MOP::AST::Node::BinOp::String::GreaterThan::OrEqualTo->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        ## ---------------------------------------------------------------------
        ## String Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::MULTICONCAT) {

            my ($num_args, $string, @segments) = $op->get_aux_list($cv);
            #say "GOT ($num_args) segments in [${string}] at ",join ', ' => @segments;

            my @c = collect_multiconcat_children($op);
            #say "GOT CHILDREN:\n",join "\n" => map $_->DUMP, @c;

            my @children;
            my $prev_index = 0;
            foreach my ($i, $segment) (indexed @segments) {
                if ($segment == -1) {
                    push @children => $self->build_expression(shift @c) if @c;
                }
                else {
                    if ($children[-1] isa B::MOP::AST::Node::Const::Literal) {
                        push @children => $self->build_expression(shift @c);
                    }

                    my $str = substr $string, $prev_index, $segment;
                    push @children => B::MOP::AST::Node::Const::Literal->new(
                        env     => $env,
                        op      => B::MOP::Opcode::NOOP->new,
                        literal => $str,
                        type    => B::MOP::Type::String->new
                    );
                    $prev_index += $segment;
                }
            }

            my $node_class = 'B::MOP::AST::Node::MultiOp::String::Concat';
            if ($op->flags->is_declaration) {
                $node_class = 'B::MOP::AST::Node::MultiOp::String::Concat::AndDeclare';
            }
            elsif ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::MultiOp::String::Concat::AndAssign';
            }
            return $node_class->new(
                env      => $env,
                op       => $op,
                children => \@children,
            );
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
        elsif ($op isa B::MOP::Opcode::DIVIDE) {
            my $node_class = 'B::MOP::AST::Node::BinOp::Divide';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::Divide';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::MODULO) {
            my $node_class = 'B::MOP::AST::Node::BinOp::Modulo';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::Modulo';
            }
            return $node_class->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::POW) {
            my $node_class = 'B::MOP::AST::Node::BinOp::PowerOf';
            if ($op->flags->is_mutator_varient) {
                $node_class = 'B::MOP::AST::Node::BinOp::Assign::PowerOf';
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
            my $glob = ($args[-1] // $mark)->next;

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
            say "       `--> next: ",$op->next ? $op->next->DUMP : '~';
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

