#!perl

use v5.40;
use experimental qw[ class ];

use B ();

use YAML qw[ Dump ];

use Test::More;

package B::MOP::Opcodes {
    my %opcodes;
    sub get ($, $b) {
        return if $b isa B::NULL;
        $opcodes{ ${$b} } //= do {
            my $op_class = join '::' => 'B::MOP::Opcode', (uc $b->name);
            $op_class->new( b => $b );
        };
    }
}

## -----------------------------------------------------------------------------

class B::MOP::Opcode::OP {
    field $b :param :reader;

    field $next;
    field $parent;
    field $sibling;

    method type { (blessed($b) =~ /^B\:\:(.*)/)[0] }
    method name { $b->name }
    method desc { $b->desc }
    method addr { ${ $b }  }

    method next    { $next    //= B::MOP::Opcodes->get( $b->next    ) }
    method parent  { $parent  //= B::MOP::Opcodes->get( $b->parent  ) }
    method sibling { $sibling //= B::MOP::Opcodes->get( $b->sibling ) }

    method DUMP {
        sprintf 'op[%s](%d) : %s = %s',
                $self->type, $self->addr,
                $self->name, $self->desc;
    }
}

class B::MOP::Opcode::COP    :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::UNOP   :isa(B::MOP::Opcode::OP) {
    field $first;
    method first { $first //= B::MOP::Opcodes->get( $self->b->first ) }
}
class B::MOP::Opcode::SVOP   :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PVOP   :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PADOP  :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::METHOP :isa(B::MOP::Opcode::OP) {}

class B::MOP::Opcode::LOGOP    :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::UNOP_UAX :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::BINOP    :isa(B::MOP::Opcode::UNOP) {
    field $last;
    method last { $last //= B::MOP::Opcodes->get( $self->b->last ) }
}

class B::MOP::Opcode::LISTOP :isa(B::MOP::Opcode::BINOP) {}
class B::MOP::Opcode::LOOP   :isa(B::MOP::Opcode::LISTOP) {}
class B::MOP::Opcode::PMOP   :isa(B::MOP::Opcode::LISTOP) {}

## -----------------------------------------------------------------------------

class B::MOP::Opcode::NEXTSTATE :isa(B::MOP::Opcode::COP) {}
class B::MOP::Opcode::PUSHMARK  :isa(B::MOP::Opcode::COP) {}

class B::MOP::Opcode::ENTERSUB :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::LEAVESUB :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::RETURN   :isa(B::MOP::Opcode::UNOP) {}

class B::MOP::Opcode::CONST :isa(B::MOP::Opcode::SVOP) {}

class B::MOP::Opcode::PADSV       :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PADSV_STORE :isa(B::MOP::Opcode::UNOP) {}

class B::MOP::Opcode::ADD :isa(B::MOP::Opcode::BINOP) {}

class B::MOP::Opcode::NULL      :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::LINESEQ   :isa(B::MOP::Opcode::OP) {}

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

class B::MOP::AST::Expression::AddOp :isa(B::MOP::AST::Expression::BinOp) {}


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

class B::MOP::AST::Builder {
    use constant DEBUG => $ENV{DEBUG} // 0;

    method build_expression ($op) {
        if ($op isa B::MOP::Opcode::CONST) {
            return B::MOP::AST::Const->new( op => $op );
        }
        elsif ($op isa B::MOP::Opcode::ADD) {
            return B::MOP::AST::Expression::AddOp->new(
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

    method build_subroutine ($cv) {

        my @opcodes;
        my $next = $cv->START;
        until ($next isa B::NULL) {
            push @opcodes => B::MOP::Opcodes->get( $next );
            say $opcodes[-1]->DUMP if DEBUG;
            $next = $next->next;
        }

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

subtest '... simple' => sub {
    my $cv = B::svref_2object(
        sub {
            my $x;
            $x = 10;
            my $y = 100 + $x;
        }
    );

    my $b = B::MOP::AST::Builder->new;
    my $subroutine = $b->build_subroutine( $cv );

    say Dump( $subroutine->to_JSON );

};


done_testing;
