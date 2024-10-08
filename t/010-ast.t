#!perl

use v5.40;
use experimental qw[ class ];

use B ();
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
    field $first;
    field $parent;
    field $sibling;

    method type { (blessed($b) =~ /^B\:\:(.*)/)[0] }
    method name { $b->name }
    method desc { $b->desc }
    method addr { ${ $b }  }

    method next    { $next    //= B::MOP::Opcodes->get( $b->next    ) }
    method first   { $first   //= B::MOP::Opcodes->get( $b->first   ) }
    method parent  { $parent  //= B::MOP::Opcodes->get( $b->parent  ) }
    method sibling { $sibling //= B::MOP::Opcodes->get( $b->sibling ) }

    method DUMP {
        sprintf 'op[%s](%d) : %s = %s',
                $self->type, $self->addr,
                $self->name, $self->desc;
    }
}

class B::MOP::Opcode::COP    :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::UNOP   :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::SVOP   :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PVOP   :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PADOP  :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::METHOP :isa(B::MOP::Opcode::OP) {}

class B::MOP::Opcode::LOGOP    :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::UNOP_UAX :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::BINOP    :isa(B::MOP::Opcode::UNOP) {}

class B::MOP::Opcode::LISTOP :isa(B::MOP::Opcode::BINOP) {}
class B::MOP::Opcode::LOOP   :isa(B::MOP::Opcode::LISTOP) {}
class B::MOP::Opcode::PMOP   :isa(B::MOP::Opcode::LISTOP) {}

## -----------------------------------------------------------------------------

class B::MOP::Opcode::NEXTSTATE :isa(B::MOP::Opcode::COP) {}

class B::MOP::Opcode::ENTERSUB :isa(B::MOP::Opcode::UNOP) {}
class B::MOP::Opcode::LEAVESUB :isa(B::MOP::Opcode::UNOP) {}

class B::MOP::Opcode::CONST :isa(B::MOP::Opcode::SVOP) {}

class B::MOP::Opcode::PADSV       :isa(B::MOP::Opcode::OP) {}
class B::MOP::Opcode::PADSV_STORE :isa(B::MOP::Opcode::UNOP) {}

class B::MOP::Opcode::ADD :isa(B::MOP::Opcode::BINOP) {}

## -----------------------------------------------------------------------------

class B::MOP::Opcode::Statement {
    field $ops :param;

    method ops { @$ops }
}

class B::MOP::Opcode::Statements {
    field @statements :reader;

    method add_statement ($s) { push @statements => $s }
}

## -----------------------------------------------------------------------------

class B::MOP::AST::Statement {}

class B::MOP::AST::Lexical::Declare :isa(B::MOP::AST::Statement) {}
class B::MOP::AST::Lexical::Assign  :isa(B::MOP::AST::Statement) {}

subtest '... simple' => sub {
    my $cv = B::svref_2object(
        sub {
            my $x;
            $x = 10;
            my $y = 100 + $x;
        }
    );

    my @opcodes;
    my $next = $cv->START;
    until ($next isa B::NULL) {
        push @opcodes => B::MOP::Opcodes->get( $next );
        $next = $next->next;
    }

    my $statements = B::MOP::Opcode::Statements->new;

    my $exit = pop @opcodes;

    my @statements;
    while (@opcodes) {
        my $op = shift @opcodes;
        if ( $op isa B::MOP::Opcode::NEXTSTATE ) {
            my @body;
            while (@opcodes) {
                last if $opcodes[0] isa B::MOP::Opcode::NEXTSTATE;
                push @body => shift @opcodes;
            }
            $statements->add_statement(
                B::MOP::Opcode::Statement->new( ops => \@body )
            );
        }
    }

    foreach my $statement ($statements->statements) {
        say ';;';
        say $_->DUMP foreach $statement->ops;
        say ';;';
    }
    say $exit->DUMP;

};


done_testing;
