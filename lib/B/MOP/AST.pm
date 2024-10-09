
use v5.40;
use experimental qw[ class ];

use B::MOP::Type;
use B::MOP::Opcode;

class B::MOP::AST {
    use constant DEBUG => $ENV{DEBUG} // 0;

    method build_expression ($op) {
        ## ---------------------------------------------------------------------
        ## constants
        ## ---------------------------------------------------------------------
        if ($op isa B::MOP::Opcode::CONST) {
            return B::MOP::AST::Const->new( op => $op );
        }
        ## ---------------------------------------------------------------------
        ## Math Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::ADD) {
            return B::MOP::AST::Op::Add->new(
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::MULTIPLY) {
            return B::MOP::AST::Op::Multiply->new(
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SUBTRACT) {
            return B::MOP::AST::Op::Subtract->new(
                op  => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        ## ---------------------------------------------------------------------
        ## Pad Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::PADSV) {
            return B::MOP::AST::Local::Fetch->new( op => $op );
        }
        elsif ($op isa B::MOP::Opcode::PADAV) {
            return B::MOP::AST::Local::Fetch->new( op => $op );
        }
        elsif ($op isa B::MOP::Opcode::PADSV_STORE) {
            return B::MOP::AST::Local::Store->new(
                op  => $op,
                rhs => $self->build_expression( $op->first ),
            );
        }
        ## ---------------------------------------------------------------------
        ## Assignment
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::SASSIGN) {
            my $last = $op->last;
            $last = $last->first if $last isa B::MOP::Opcode::NULL;

            return B::MOP::AST::Op::Assign->new(
                op  => $op,
                lhs => $self->build_expression( $last ),
                rhs => $self->build_expression( $op->first ),
            );
        }
        ## ---------------------------------------------------------------------
        ## Array Ops
        ## ---------------------------------------------------------------------
        elsif ($op isa B::MOP::Opcode::AELEMFAST_LEX) {
            return B::MOP::AST::Local::Array::Element::Const->new( op => $op );
        }
        ## ---------------------------------------------------------------------
        else {
            say "(((((--------------------------)))))";
            say $op->DUMP;
            say $op->next->DUMP;
            say "(((((--------------------------)))))";
            die;
        }
    }

    method build_statement ($nextstate) {
        return B::MOP::AST::Statement->new(
            nextstate  => $nextstate,
            expression => $self->build_expression(
                $nextstate->sibling
            )
        );
    }

    method build_subroutine (@opcodes) {
        map { say $_->DUMP } @opcodes if DEBUG;

        my $exit = pop @opcodes;
        return B::MOP::AST::Subroutine->new(
            exit  => $exit,
            block => B::MOP::AST::Block->new(
                statements => [
                    map  {     $self->build_statement( $_ ) }
                    grep { $_ isa B::MOP::Opcode::NEXTSTATE }
                    @opcodes
                ]
            )
        );
    }

}

## -----------------------------------------------------------------------------

class B::MOP::AST::Visitor {
    field $f :param;
    method visit ($node) { $f->($node) }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Node {
    field $type;

    ADJUST {
        $type = B::MOP::Type::Scalar->new;
    }

    method get_type      { $type      }
    method set_type ($t) { $type = $t }

    method node_type { __CLASS__ =~ s/B::MOP::AST:://r }

    method accept ($v) { $v->visit($self) }

    method to_JSON {
        return +{
            '$NODE' => $self->node_type,
            '$TYPE' => $self->get_type->to_string,
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Expression :isa(B::MOP::AST::Node) {
    field $op :param :reader;

    field $target;

    method has_stack_target { $op->has_stack_target }
    method has_pad_target   { $op->has_pad_target   }

    method pad_target_index  { $self->op->targ }

    method has_target        { !! $target }
    method get_target        { $target }
    method set_target ($var) { $target = $var  }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            ($target ? ('_target_' => {
                    name    => $target->name,
                    type    => $self->has_pad_target ? 'PAD' : 'STACK',
                    '$TYPE' => $target->get_type->to_string,
                }) : ()),
        }
    }
}

class B::MOP::AST::Local :isa(B::MOP::AST::Expression) {}

class B::MOP::AST::Local::Fetch :isa(B::MOP::AST::Local) {}
class B::MOP::AST::Local::Store :isa(B::MOP::AST::Local) {
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

class B::MOP::AST::Local::Array::Element::Const :isa(B::MOP::AST::Local) {}

class B::MOP::AST::Const :isa(B::MOP::AST::Expression) {
    ADJUST {
        my $sv = $self->op->sv;
        if ($sv->type eq B::MOP::Opcode::SV::Types->IV) {
            $self->set_type(B::MOP::Type::Int->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::SV::Types->NV) {
            $self->set_type(B::MOP::Type::Float->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::SV::Types->PV) {
            $self->set_type(B::MOP::Type::String->new);
        }
    }

    method get_literal { $self->op->sv->literal }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            __LITERAL__ => {
                value => $self->get_literal // 'undef',
            }
        }
    }
}

class B::MOP::AST::Expression::BinOp :isa(B::MOP::AST::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method accept ($v) {
        $lhs->accept($v);
        $rhs->accept($v);
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

class B::MOP::AST::Op::Numeric :isa(B::MOP::AST::Expression::BinOp) {}

class B::MOP::AST::Op::Add      :isa(B::MOP::AST::Op::Numeric) {}
class B::MOP::AST::Op::Subtract :isa(B::MOP::AST::Op::Numeric) {}
class B::MOP::AST::Op::Multiply :isa(B::MOP::AST::Op::Numeric) {}

class B::MOP::AST::Op::Assign :isa(B::MOP::AST::Expression::BinOp) {}

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

class B::MOP::AST::Subroutine  :isa(B::MOP::AST::Node) {
    field $block :param :reader;
    field $exit  :param :reader;

    method accept ($v) {
        $block->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            block => $block->to_JSON,
            exit => { leavesub => 1 },
        }
    }
}

## -----------------------------------------------------------------------------
