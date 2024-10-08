
use v5.40;
use experimental qw[ class ];

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

class B::MOP::AST::Type {}
class B::MOP::AST::Type::String  :isa(B::MOP::AST::Type) {}
class B::MOP::AST::Type::Numeric :isa(B::MOP::AST::Type) {}
class B::MOP::AST::Type::Int     :isa(B::MOP::AST::Type::Numeric) {}
class B::MOP::AST::Type::Float   :isa(B::MOP::AST::Type::Numeric) {}

## -----------------------------------------------------------------------------

class B::MOP::AST::Visitor {
    field $f :param;
    method visit ($node) { $f->($node) }
}

class B::MOP::AST::Node {
    field $type;

    method has_type      { !! $type   }
    method get_type      { $type      }
    method set_type ($t) { $type = $t }

    method node_type { __CLASS__ =~ s/B::MOP::AST:://r }

    method accept ($v) { $v->visit($self) }
}

class B::MOP::AST::Expression :isa(B::MOP::AST::Node) {
    field $op :param :reader;

    method to_JSON {
        return +{
            CLASS => __CLASS__,
        }
    }
}

class B::MOP::AST::Local :isa(B::MOP::AST::Expression) {
    field $pad_variable :reader;

    method set_pad_variable ($var) { $pad_variable = $var }

    method pad_index { $self->op->targ }
}

class B::MOP::AST::Local::Fetch :isa(B::MOP::AST::Local) {}
class B::MOP::AST::Local::Store :isa(B::MOP::AST::Local) {
    field $rhs :param :reader;

    method accept ($v) {
        $rhs->accept($v);
        $v->visit($self);
    }

    method to_JSON {
        return +{
            CLASS => __CLASS__,
            rhs => $rhs->to_JSON,
        }
    }
}

class B::MOP::AST::Local::Array::Element::Const :isa(B::MOP::AST::Local) {}

class B::MOP::AST::Const :isa(B::MOP::AST::Expression) {
    ADJUST {
        my $sv = $self->op->sv;
        if ($sv->type eq B::MOP::Opcode::SV::Types->IV) {
            $self->set_type(B::MOP::AST::Type::Int->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::SV::Types->NV) {
            $self->set_type(B::MOP::AST::Type::Float->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::SV::Types->PV) {
            $self->set_type(B::MOP::AST::Type::String->new);
        }
    }

    method get_literal { $self->op->sv->literal }
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
            CLASS => __CLASS__,
            lhs => $lhs->to_JSON,
            rhs => $rhs->to_JSON,
        }
    }
}

class B::MOP::AST::Op::Add      :isa(B::MOP::AST::Expression::BinOp) {}
class B::MOP::AST::Op::Subtract :isa(B::MOP::AST::Expression::BinOp) {}
class B::MOP::AST::Op::Multiply :isa(B::MOP::AST::Expression::BinOp) {}

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
            CLASS => __CLASS__,
            nextstate  => { nextstate => 1 },
            expression => $expression->to_JSON
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Block :isa(B::MOP::AST::Node) {
    field $statements :param :reader;

    method accept ($v) {
        $_->accept($v) foreach @$statements;
        $v->visit($self);
    }

    method to_JSON {
        return +{
            CLASS => __CLASS__,
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
            CLASS => __CLASS__,
            block => $block->to_JSON,
            exit => { leavesub => 1 },
        }
    }
}

## -----------------------------------------------------------------------------
