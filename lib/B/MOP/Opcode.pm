
use v5.40;
use experimental qw[ class ];

use B ();

package B::MOP::Opcode {

    my %opcode_cache;
    sub get ($, $b) {
        return if $b isa B::NULL;
        $opcode_cache{ ${$b} } //= do {
            my $op_class = join '::' => 'B::MOP::Opcode', (uc $b->name);
            $op_class->new( b => $b );
        };
    }

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::OP {
        field $b :param :reader;

        field $next;
        field $parent;
        field $sibling;

        method type { (blessed($b) =~ /^B\:\:(.*)/)[0] }
        method name { $b->name }
        method desc { $b->desc }
        method addr { ${ $b }  }

        method next    { $next    //= B::MOP::Opcode->get( $b->next    ) }
        method parent  { $parent  //= B::MOP::Opcode->get( $b->parent  ) }
        method sibling { $sibling //= B::MOP::Opcode->get( $b->sibling ) }

        method DUMP {
            sprintf 'op[%s](%d) : %s = %s',
                    $self->type, $self->addr,
                    $self->name, $self->desc;
        }
    }

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::COP    :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::UNOP   :isa(B::MOP::Opcode::OP) {
        field $first;
        method first { $first //= B::MOP::Opcode->get( $self->b->first ) }
    }
    class B::MOP::Opcode::SVOP   :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::PVOP   :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::PADOP  :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::METHOP :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::LOGOP    :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::UNOP_UAX :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::BINOP    :isa(B::MOP::Opcode::UNOP) {
        field $last;
        method last { $last //= B::MOP::Opcode->get( $self->b->last ) }
    }

    class B::MOP::Opcode::LISTOP :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::LOOP   :isa(B::MOP::Opcode::LISTOP) {}
    class B::MOP::Opcode::PMOP   :isa(B::MOP::Opcode::LISTOP) {}

    ## -------------------------------------------------------------------------

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

    ## -------------------------------------------------------------------------
}
