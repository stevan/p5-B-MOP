
use v5.40;
use experimental qw[ class ];

use B ();

package B::MOP::Opcode {
    use constant DEBUG => $ENV{DEBUG_OPCODE} // 0;

    my %opcode_cache;
    sub get ($, $b) {
        return if $b isa B::NULL;
        DEBUG && say sprintf "%d : %-20s => %s", $$b, $b->name, $b;
        return if $b->name eq 'null';
        $opcode_cache{ ${$b} } //= do {
            my $op_class = join '::' => 'B::MOP::Opcode', (uc $b->name);
            try {
                $op_class->new( b => $b );
            } catch ($e) {
                die "Failed to get op($op_class) for $b";
            }
        };
    }

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::Value::Types {
        BEGIN {
            constant->import( $_, $_ ) foreach qw[ IV NV PV ]
        }
    }

    class B::MOP::Opcode::Value {
        field $b :param :reader;

        method type { B::class($b) }
    }

    class B::MOP::Opcode::Value::SV :isa(B::MOP::Opcode::Value) {}
    class B::MOP::Opcode::Value::GV :isa(B::MOP::Opcode::Value) {
        method name { $self->b->NAME }
        method cv {
            B::MOP::Opcode::Value::CV->new( b => $self->b->CV )
        }
    }

    class B::MOP::Opcode::Value::CV :isa(B::MOP::Opcode::Value) {
        method name       { $self->b->GV->NAME }
        method stash_name { $self->b->STASH->NAME }

        method fully_qualified_name {
            join '::' => $self->stash_name, $self->name
        }
    }

    class B::MOP::Opcode::Value::Literal :isa(B::MOP::Opcode::Value) {
        method literal {
            my $b = $self->b;
            return $b->int_value           if $b isa B::IV;
            return $b->NV                  if $b isa B::NV;
            return B::perlstring( $b->PV ) if $b isa B::PV;
        }
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

        method next {
            my $o = $self->b->next;
            return if $o isa B::NULL;
            $o = $o->next if $o->name eq 'null' && $o->targ;
            $next //= B::MOP::Opcode->get( $o );
        }

        method parent {
            my $o = $self->b->parent;
            return if $o isa B::NULL;
            $o = $o->parent if $o->name eq 'null' && $o->targ;
            $parent //= B::MOP::Opcode->get( $o );
        }

        method sibling {
            my $o = $self->b->sibling;
            return if $o isa B::NULL;
            $o = $o->sibling if $o->name eq 'null' && $o->targ;
            $sibling //= B::MOP::Opcode->get( $o );
        }


        method has_target   { $b->targ > 0 }
        method target_index { $b->targ     }

        # TODO:
        # We can determine if a OP will put something on
        # the stack (OPf_STACKED) or not.

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
        method first {
            my $o = $self->b->first;
            $o = $o->first if $o->name eq 'null' && $o->targ;
            $first //= B::MOP::Opcode->get( $o );
        }
    }
    class B::MOP::Opcode::SVOP :isa(B::MOP::Opcode::OP) {
        method sv { B::MOP::Opcode::Value::SV->new( b => $self->b->sv ) }
        method gv { B::MOP::Opcode::Value::GV->new( b => $self->b->gv ) }
    }
    class B::MOP::Opcode::PVOP   :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::PADOP  :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::METHOP :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::LOGOP    :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::UNOP_UAX :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::BINOP    :isa(B::MOP::Opcode::UNOP) {
        field $last;
        method last {
            my $o = $self->b->last;
            $o = $o->last if $o->name eq 'null' && $o->targ;
            $last //= B::MOP::Opcode->get( $o );
        }
    }

    class B::MOP::Opcode::LISTOP :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::LOOP   :isa(B::MOP::Opcode::LISTOP) {}
    class B::MOP::Opcode::PMOP   :isa(B::MOP::Opcode::LISTOP) {}

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::ARGCHECK :isa(B::MOP::Opcode::UNOP_UAX) {}
    class B::MOP::Opcode::ARGELEM  :isa(B::MOP::Opcode::UNOP_UAX) {}

    class B::MOP::Opcode::NEXTSTATE :isa(B::MOP::Opcode::COP) {}

    class B::MOP::Opcode::PUSHMARK :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::ENTERSUB :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::LEAVESUB :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::RETURN   :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::CONST :isa(B::MOP::Opcode::SVOP) {
        method sv { B::MOP::Opcode::Value::Literal->new( b => $self->b->sv ) }
    }

    class B::MOP::Opcode::GV :isa(B::MOP::Opcode::SVOP) {}

    class B::MOP::Opcode::PADSV       :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::PADAV       :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::PADSV_STORE :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::ADD      :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SUBTRACT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::MULTIPLY :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::SASSIGN :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::AELEMFAST_LEX :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::NULL      :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::LINESEQ   :isa(B::MOP::Opcode::OP) {}

    ## -------------------------------------------------------------------------
}
