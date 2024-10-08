
use v5.40;
use experimental qw[ class ];

use B::MOP::Opcode;

class B::MOP::AST {

    method build_expression ($op) {
        if ($op isa B::MOP::Opcode::CONST) {
            return B::MOP::AST::Const->new( op => $op );
        }
        elsif ($op isa B::MOP::Opcode::ADD) {
            return B::MOP::AST::Op::Add->new(
                op => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::MULTIPLY) {
            return B::MOP::AST::Op::Multiply->new(
                op => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::SUBTRACT) {
            return B::MOP::AST::Op::Subtract->new(
                op => $op,
                lhs => $self->build_expression( $op->first ),
                rhs => $self->build_expression( $op->last ),
            );
        }
        elsif ($op isa B::MOP::Opcode::PADSV) {
            return B::MOP::AST::Local::Fetch->new( op => $op );
        }
        elsif ($op isa B::MOP::Opcode::PADSV_STORE) {
            return B::MOP::AST::Local::Store->new(
                op    => $op,
                value => $self->build_expression( $op->first ),
            );
        }
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

class B::MOP::AST::Expression {
    field $op :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
        }
    }
}

class B::MOP::AST::Local::Fetch :isa(B::MOP::AST::Expression) {}
class B::MOP::AST::Local::Store :isa(B::MOP::AST::Expression) {
    field $value :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
            value => $value->to_JSON,
        }
    }
}

class B::MOP::AST::Const :isa(B::MOP::AST::Expression) {}

class B::MOP::AST::Expression::BinOp :isa(B::MOP::AST::Expression) {
    field $lhs :param :reader;
    field $rhs :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
            lhs => $lhs->to_JSON,
            rhs => $rhs->to_JSON,
        }
    }
}

class B::MOP::AST::Op::Add      :isa(B::MOP::AST::Expression::BinOp) {}
class B::MOP::AST::Op::Subtract :isa(B::MOP::AST::Expression::BinOp) {}
class B::MOP::AST::Op::Multiply :isa(B::MOP::AST::Expression::BinOp) {}


## -----------------------------------------------------------------------------

class B::MOP::AST::Statement {
    field $nextstate  :param :reader;
    field $expression :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
            nextstate  => { nextstate => 1 },
            expression => $expression->to_JSON
        }
    }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Block {
    field $statements :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
            statements => [ map $_->to_JSON, @$statements ]
        }
    }
}

class B::MOP::AST::Subroutine {
    field $block :param :reader;
    field $exit  :param :reader;

    method to_JSON {
        return +{
            type => __CLASS__,
            block => $block->to_JSON,
            exit => { leavesub => 1 },
        }
    }
}

## -----------------------------------------------------------------------------
