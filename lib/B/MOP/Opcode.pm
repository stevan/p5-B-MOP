
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
                die "Failed to get op($op_class) for $b because:\n\t$e\n";
            }
        };
    }

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::Container::Types {
        BEGIN {
            constant->import( $_, $_ ) foreach qw[ SV AV HV ]
        }
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

    class B::MOP::Opcode::Flags {
        field $b :param :reader;

        method returns_void   { !! (($b->flags & B::OPf_WANT) == B::OPf_WANT_VOID  ) }
        method returns_scalar { !! (($b->flags & B::OPf_WANT) == B::OPf_WANT_SCALAR) }
        method returns_list   { !! (($b->flags & B::OPf_WANT) == B::OPf_WANT_LIST  ) }

        method has_arguments      { !! ($b->flags & B::OPf_KIDS   ) } # the op has arguments
        method was_parenthesized  { !! ($b->flags & B::OPf_PARENS ) } # was called with ()
        method return_container   { !! ($b->flags & B::OPf_REF    ) } # Return container, not value
        method is_lvalue          { !! ($b->flags & B::OPf_MOD    ) } # will modifiy the value
        method is_mutator_varient { !! ($b->flags & B::OPf_STACKED) } # ex: $x += 10
        method is_special         { !! ($b->flags & B::OPf_SPECIAL) } # Do something weird (see op.h)

        # does this op create a new variable?
        method is_declaration { !! ($b->private & B::OPpLVAL_INTRO) }

        method has_pad_target { !! ($b->private & B::OPpTARGET_MY) }
    }

    class B::MOP::Opcode::NOOP {
        method type { 'NOOP' }
        method name { 'noop' }
        method desc { 'noop' }
        method addr { -1  }

        method flags { die "No Flags on NOOP" }

        method next    { return }
        method parent  { return }
        method sibling { return }

        method has_target   { false }
        method target_index { -1    }

        method DUMP {
            sprintf 'op[%s](%d) : %s = %s',
                    $self->type, $self->addr,
                    $self->name, $self->desc;
        }
    }

    class B::MOP::Opcode::OP {
        field $b :param :reader;

        field $next;
        field $parent;
        field $sibling;

        method type { (blessed($b) =~ /^B\:\:(.*)/)[0] }
        method name { $b->name }
        method desc { $b->desc }
        method addr { ${ $b }  }

        method flags { B::MOP::Opcode::Flags->new( b => $b ) }

        method next ($next_try='next') {
            my $o = $self->b->next;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
            $next //= B::MOP::Opcode->get( $o );
        }

        method parent ($next_try='parent') {
            my $o = $self->b->parent;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
            $parent //= B::MOP::Opcode->get( $o );
        }

        method sibling ($next_try='sibling') {
            my $o = $self->b->sibling;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
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

    class B::MOP::Opcode::COP :isa(B::MOP::Opcode::OP) {
        method sequence_id { $self->b->cop_seq }

        method DUMP {
            $self->SUPER::DUMP." - #".$self->sequence_id
        }
    }


    class B::MOP::Opcode::UNOP :isa(B::MOP::Opcode::OP) {
        field $first;
        method first ($next_try='first') {
            my $o = $self->b->first;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
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

    class B::MOP::Opcode::LOGOP :isa(B::MOP::Opcode::UNOP) {
        field $other;
        method other ($next_try='other') {
            my $o = $self->b->other;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
            $other //= B::MOP::Opcode->get( $o );
        }
    }

    class B::MOP::Opcode::UNOP_UAX :isa(B::MOP::Opcode::UNOP) {
        method get_aux_list ($cv) { $self->b->aux_list($cv) }
    }

    class B::MOP::Opcode::BINOP :isa(B::MOP::Opcode::UNOP) {
        field $last;
        method last ($next_try='last') {
            my $o = $self->b->last;
            return if $o isa B::NULL;
            $o = $o->$next_try if $o->name eq 'null';
            $last //= B::MOP::Opcode->get( $o );
        }
    }

    class B::MOP::Opcode::LISTOP :isa(B::MOP::Opcode::BINOP) {
        field $children;

        method children {
            return $children if defined $children;
            my @kids;
            my $next = $self->next;
            while (defined $next) {
                push @kids => $next;
                $next = $next->sibling->sibling;
            }
            return $children = \@kids;
        }
    }

    class B::MOP::Opcode::LOOP :isa(B::MOP::Opcode::LISTOP) {
        field $redoop;
        field $nextop;
        field $lastop;
    }

    ## -------------------------------------------------------------------------

    class B::MOP::Opcode::ARGCHECK :isa(B::MOP::Opcode::UNOP_UAX) {}
    class B::MOP::Opcode::ARGELEM  :isa(B::MOP::Opcode::UNOP_UAX) {
        method arg_type {
            my $flag = $self->b->private & B::OPpARGELEM_MASK;
            return B::MOP::Opcode::Container::Types->SV if $flag == B::OPpARGELEM_SV;
            return B::MOP::Opcode::Container::Types->AV if $flag == B::OPpARGELEM_AV;
            return B::MOP::Opcode::Container::Types->HV if $flag == B::OPpARGELEM_HV;
        }

        method is_SV { !! (($self->b->private & B::OPpARGELEM_MASK) == B::OPpARGELEM_SV) }
        method is_AV { !! (($self->b->private & B::OPpARGELEM_MASK) == B::OPpARGELEM_AV) }
        method is_HV { !! (($self->b->private & B::OPpARGELEM_MASK) == B::OPpARGELEM_HV) }
    }

    class B::MOP::Opcode::NEXTSTATE :isa(B::MOP::Opcode::COP) {}

    class B::MOP::Opcode::PUSHMARK :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::ENTERSUB :isa(B::MOP::Opcode::UNOP) {
        # called in an arg list for another call - foo(foo())
        method is_in_args { !! ($self->b->private & B::OPpENTERSUB_INARGS) }
    }
    class B::MOP::Opcode::LEAVESUB :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::RETURN   :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::ENTERLOOP :isa(B::MOP::Opcode::LOOP) {}
    class B::MOP::Opcode::LEAVELOOP :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::LINESEQ :isa(B::MOP::Opcode::LISTOP) {}

    class B::MOP::Opcode::CONST :isa(B::MOP::Opcode::SVOP) {
        # TODO:
        # Handle the various constant flags from opcode.h
        #   - OPpCONST_NOVER
        #   - OPpCONST_TOKEN_BITS
        #   - OPpCONST_SHORTCIRCUIT
        #   - OPpCONST_TOKEN_SHIFT
        #   - OPpCONST_STRICT
        #   - OPpCONST_ENTERED
        #   - OPpCONST_BARE
        #   - OPpCONST_TOKEN_MASK
        #   - OPpCONST_TOKEN_LINE
        #   - OPpCONST_TOKEN_FILE
        #   - OPpCONST_TOKEN_PACKAGE

        method sv { B::MOP::Opcode::Value::Literal->new( b => $self->b->sv ) }
    }

    class B::MOP::Opcode::RV2CV :isa(B::MOP::Opcode::SVOP) {}

    class B::MOP::Opcode::GV :isa(B::MOP::Opcode::SVOP) {}

    class B::MOP::Opcode::PADSV       :isa(B::MOP::Opcode::OP) {}
    class B::MOP::Opcode::PADAV       :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::PADSV_STORE :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::ADD      :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SUBTRACT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::MULTIPLY :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::DIVIDE   :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::MODULO   :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::POW      :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::POSTINC :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::PREINC  :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::POSTDEC :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::PREDEC  :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::EQ :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::NE :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::LT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::LE :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::GT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::GE :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::SEQ :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SNE :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SLT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SLE :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SGT :isa(B::MOP::Opcode::BINOP) {}
    class B::MOP::Opcode::SGE :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::AND :isa(B::MOP::Opcode::LOGOP) {}
    class B::MOP::Opcode::OR  :isa(B::MOP::Opcode::LOGOP) {}
    class B::MOP::Opcode::DOR :isa(B::MOP::Opcode::LOGOP) {}

    class B::MOP::Opcode::MULTICONCAT :isa(B::MOP::Opcode::UNOP_UAX) {
        method will_append_target     { !! ($self->b->private & B::OPpMULTICONCAT_APPEND)    }
        method is_optimized_sprintf   { !! ($self->b->private & B::OPpMULTICONCAT_FAKE)      }
        method is_string_iterpolation { !! ($self->b->private & B::OPpMULTICONCAT_STRINGIFY) }
    }

    class B::MOP::Opcode::INT     :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::REF     :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::SCALAR  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::DEFINED :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::IS_WEAK    :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::IS_TAINTED :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::REFADDR :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::REFTYPE :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::CEIL  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::FLOOR :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::HEX :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::OCT :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::ORD :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::CHR       :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::FC        :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::LC        :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::LCFIRST   :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::UC        :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::UCFIRST   :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::LENGTH    :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::SCHOMP    :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::SCHOP     :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::QUOTEMETA :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::ABS :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::COS  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::EXP  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::LOG  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::SIN  :isa(B::MOP::Opcode::UNOP) {}
    class B::MOP::Opcode::SQRT :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::BLESSED :isa(B::MOP::Opcode::UNOP) {}

    class B::MOP::Opcode::SASSIGN :isa(B::MOP::Opcode::BINOP) {}

    class B::MOP::Opcode::AELEMFAST_LEX :isa(B::MOP::Opcode::OP) {}

    class B::MOP::Opcode::NULL      :isa(B::MOP::Opcode::OP) {}

    ## -------------------------------------------------------------------------
}
