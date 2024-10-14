
use v5.40;
use experimental qw[ class ];

use B::MOP::Type;
use B::MOP::Opcode;

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

        $tree = B::MOP::AST::Subroutine->new(
            exit  => $exit,
            block => B::MOP::AST::Block->new(
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
        return B::MOP::AST::Statement->new(
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
            return B::MOP::AST::Const->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Math Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ADD) {
            return B::MOP::AST::Op::Add->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::MULTIPLY) {
            return B::MOP::AST::Op::Multiply->new(
                env => $env,
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SUBTRACT) {
            return B::MOP::AST::Op::Subtract->new(
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
            return B::MOP::AST::Local::Fetch->new( env => $env, op => $op );
        }
        elsif ($op isa B::MOP::Opcode::PADSV_STORE) {
            return B::MOP::AST::Local::Store->new(
                env => $env,
                op  => $op,
                rhs => $self->build_expression( $op->first ),
            );
        }
        elsif ($op isa B::MOP::Opcode::PADAV) {
            return B::MOP::AST::Local::Fetch->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Sub arg Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ARGCHECK) {
            my ($params, $optional_params, $slurpiness) = $op->get_aux_list($cv);
            return B::MOP::AST::Argument::Check->new(
                env             => $env,
                op              => $op,
                params          => $params,
                optional_params => $optional_params,
                slurpiness      => $slurpiness,
            );
        }
        elsif ($op isa B::MOP::Opcode::ARGELEM) {
            return B::MOP::AST::Argument::Element->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Call Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ENTERSUB) {
            my $mark = $op->first;
            my @args = collect_args($mark);
            my $glob = $args[-1]->next;

            return B::MOP::AST::Call::Subroutine->new(
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
            return B::MOP::AST::Op::Assign->new(
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
            return B::MOP::AST::Local::Array::Element::Const->new( env => $env, op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Glob Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::GV) {
            return B::MOP::AST::Glob::Fetch->new( env => $env, op => $op );
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

## -----------------------------------------------------------------------------
## Tools
## -----------------------------------------------------------------------------

class B::MOP::AST::Visitor {
    field $f      :param;
    field $accept :param = undef;

    method visit ($node) {
        if ($accept) {
            $f->($node) if $node->isa($accept);
        }
        else {
            $f->($node);
        }
    }
}

class B::MOP::AST::Typed {
    field $type :reader;

    ADJUST {
        $type = B::MOP::Type::Variable->new;
    }

    method set_type ($a) {
        if ($type->is_resolved) {
            $type->cast_into($a->type);
        } else {
            $type->resolve($a->type);
        }
    }
}

## -----------------------------------------------------------------------------
## Symbol Table
## -----------------------------------------------------------------------------

class B::MOP::AST::SymbolTable::Entry :isa(B::MOP::AST::Typed) {
    field $entry :param;

    field $is_argument :reader = false;
    field @trace;

    ADJUST {
        # TODO: check for non scalars as well
        $self->type->resolve(B::MOP::Type::Scalar->new);
    }

    method mark_as_argument { $is_argument = true }

    method name { $entry->PVX }

    method is_temporary { $entry->IsUndef }
    method is_field     { !! $entry->FLAGS & B::PADNAMEf_FIELD }
    method is_our       { !! $entry->FLAGS & B::PADNAMEf_OUR   }
    method is_local     {  !$self->is_field  && !$self->is_our }

    method is_declared { !! @trace }
    method trace ($node) { push @trace => $node }

    method get_full_trace { @trace }

    method to_JSON ($full=false) {
        +{
            name     => $self->name,
            location => ($is_argument ? 'ARG' : 'LOCAL'),
            '$TYPE'  => $self->type->to_JSON,
            ($full ? ('@TRACE' => [
                map { join ' : ' => $_->name, $_->type->to_JSON } @trace
            ]) : ())
        }
    }
}

class B::MOP::AST::SymbolTable {
    field $pad :param :reader;

    field %lookup;
    field @index;

    ADJUST {
        foreach my ($i, $var) (indexed @$pad) {
            my $entry = B::MOP::AST::SymbolTable::Entry->new( entry => $var );
            $lookup{ $var->PVX } = $entry unless $entry->is_temporary;
            $index[ $i ] = $entry;
        }
    }

    method get_symbol_by_index ($i) { $index[ $i ]  }
    method get_symbol_by_name  ($n) { $lookup{ $n } }

    method get_all_symbols   { grep !$_->is_temporary, @index }
    method get_all_arguments { grep $_->is_argument,  @index }

    method to_JSON ($full=false) {
        +{
            ($full ? ('$TEMPS' => scalar grep $_->is_temporary, @index) : ()),
            '@ENTRIES' => [ map $_->to_JSON($full), grep !$_->is_temporary, @index ],
        };
    }
}

## -----------------------------------------------------------------------------
## Nodes
## -----------------------------------------------------------------------------

class B::MOP::AST::Node :isa(B::MOP::AST::Typed) {
    field $id :reader;

    my $ID_SEQ = 0;
    ADJUST { $id = ++$ID_SEQ }

    method name { sprintf '%s[%d]' => $self->node_type, $id }

    method node_type { __CLASS__ =~ s/B::MOP::AST:://r }

    method accept ($v) { $v->visit($self) }

    method to_JSON {
        return +{
            '$ID'   => $self->name,
            '$TYPE' => $self->type->to_JSON,
        }
    }
}

## -----------------------------------------------------------------------------
## Expressions
## -----------------------------------------------------------------------------

class B::MOP::AST::Expression :isa(B::MOP::AST::Node) {
    field $env :param :reader;
    field $op  :param :reader;

    field $target :reader;

    ADJUST {
        if ($op->has_target) {
            $target = $env->get_symbol_by_index( $op->target_index );
            $target->trace( $self );
        }
    }

    method has_target { !! $target }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            ($target && !$target->is_temporary ? ('__target' => $target->to_JSON) : ()),
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Glob::Fetch :isa(B::MOP::AST::Expression) {
    method glob { $self->op->gv }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            '&NAME' => $self->op->gv->name,
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Call :isa(B::MOP::AST::Expression) {
    field $glob :param :reader;
    field $args :param :reader;

    field $subroutine :reader;

    method arity { scalar @$args }

    method is_resolved { !! $subroutine }
    method resolve_call ($sub) { $subroutine = $sub }

    method accept ($v) {
        $_->accept($v) foreach @$args;
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            '$FUNC' => $glob->name,
            '@ARGS' => [ map $_->to_JSON, @$args ],
            ($subroutine ? ('*resolved' => $subroutine->fully_qualified_name) : ())
        }
    }
}

class B::MOP::AST::Call::Subroutine :isa(B::MOP::AST::Call) {}

## -----------------------------------------------------------------------------

class B::MOP::AST::Local::Scalar :isa(B::MOP::AST::Expression) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Scalar->new);
    }

    method is_declaration { $self->op->flags->is_declaration }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            is_declaration => $self->is_declaration,
        }
    }
}

class B::MOP::AST::Local::Fetch :isa(B::MOP::AST::Local::Scalar) {}
class B::MOP::AST::Local::Store :isa(B::MOP::AST::Local::Scalar) {
    field $rhs :param :reader;

    method accept ($v) {
        $rhs->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            rhs => $rhs->to_JSON,
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Local::Array::Element::Const :isa(B::MOP::AST::Expression) {}

## -----------------------------------------------------------------------------

class B::MOP::AST::Const :isa(B::MOP::AST::Expression) {
    ADJUST {
        my $sv = $self->op->sv;
        if ($sv->type eq B::MOP::Opcode::Value::Types->IV) {
            $self->type->resolve(B::MOP::Type::Int->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->NV) {
            $self->type->resolve(B::MOP::Type::Float->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->PV) {
            $self->type->resolve(B::MOP::Type::String->new);
        }
    }

    method get_literal { $self->op->sv->literal }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            __literal => {
                value => $self->get_literal // 'undef',
            }
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Expression::BinOp :isa(B::MOP::AST::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        $rhs->accept($v);
        $lhs->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            lhs => $lhs->to_JSON,
            rhs => $rhs->to_JSON,
        }
    }
}

class B::MOP::AST::Op::Numeric :isa(B::MOP::AST::Expression::BinOp) {
    ADJUST {
        $self->type->resolve(B::MOP::Type::Numeric->new);
    }
}

class B::MOP::AST::Op::Add      :isa(B::MOP::AST::Op::Numeric) {}
class B::MOP::AST::Op::Subtract :isa(B::MOP::AST::Op::Numeric) {}
class B::MOP::AST::Op::Multiply :isa(B::MOP::AST::Op::Numeric) {}

class B::MOP::AST::Op::Assign :isa(B::MOP::AST::Expression::BinOp) {}


## -----------------------------------------------------------------------------

class B::MOP::AST::Argument::Check :isa(B::MOP::AST::Expression) {
    field $params          :param :reader;
    field $optional_params :param :reader;
    field $slurpiness      :param :reader; # can be: '\0', '@' or '%'

    ADJUST {
        $self->type->resolve(B::MOP::Type::Void->new);
    }
}

class B::MOP::AST::Argument::Element :isa(B::MOP::AST::Expression) {
    ADJUST {
        # TODO: check for types other than scalar
        $self->type->resolve(B::MOP::Type::Scalar->new);
        $self->target->mark_as_argument;
    }
}

## -----------------------------------------------------------------------------
## Statements
## -----------------------------------------------------------------------------

class B::MOP::AST::Statement :isa(B::MOP::AST::Node) {
    field $nextstate  :param :reader;
    field $expression :param :reader;

    method accept ($v) {
        $expression->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            nextstate  => { nextstate => 1 },
            expression => $expression->to_JSON
        }
    }
}

class B::MOP::AST::Block :isa(B::MOP::AST::Node) {
    field $statements :param :reader;

    method accept ($v) {
        $_->accept($v) foreach @$statements;
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            statements => [ map $_->to_JSON, @$statements ]
        }
    }
}


class B::MOP::AST::Subroutine :isa(B::MOP::AST::Node) {
    field $block :param :reader;
    field $exit  :param :reader;

    method accept ($v) {
        $block->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            block     => $block->to_JSON,
            exit      => { leavesub => 1 },
        }
    }
}

## -----------------------------------------------------------------------------
