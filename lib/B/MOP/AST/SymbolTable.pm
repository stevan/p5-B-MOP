
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::SymbolTable {
    field $pad :param :reader;

    field %lookup;
    field @index;

    ADJUST {
        foreach my ($i, $var) (indexed @$pad) {
            my $entry;
            if ($var->IsUndef) {
                $entry = B::MOP::AST::SymbolTable::Temp->new;
            } else {
                $entry = B::MOP::AST::SymbolTable::Entry->new( entry => $var );
                $lookup{ $entry->name } = $entry;
            }
            $index[ $i ] = $entry;
        }
    }

    method get_symbol_by_index ($i) { $index[ $i ]  }
    method get_symbol_by_name  ($n) { $lookup{ $n } }

    method get_all_symbols   { grep !$_->is_temporary, @index }
    method get_all_arguments { grep $_->is_argument,  @index }

    method to_JSON ($full=false) {
        +{
            __class__ => __CLASS__,
            ($full ? (temp_count => scalar grep $_->is_temporary, @index) : ()),
            '@entries' => [ map $_->to_JSON($full), grep !$_->is_temporary, @index ],
        };
    }
}

class B::MOP::AST::SymbolTable::Temp {
    method is_temporary { true }
    method is_argument  { false }
}

class B::MOP::AST::SymbolTable::Entry :isa(B::MOP::AST::Abstract::HasTypeVariable) {
    field $entry :param;

    field $is_argument :reader = false;
    field @trace;

    ADJUST {
        # TODO: check for non scalars as well
        $self->type_var->resolve(B::MOP::Type::Scalar->new);
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
            __class__  => __CLASS__,
            name       => $self->name,
            location   => ($is_argument ? 'ARGUMENT' : 'LOCAL'),
            type       => $self->type_var->to_JSON,
            range      => (sprintf '%d..%d', $entry->COP_SEQ_RANGE_LOW, $entry->COP_SEQ_RANGE_HIGH),
            ($full ? ('@trace' => [
                map { join ' : ' => $_->name, $_->type_var->to_JSON } @trace
            ]) : ())
        }
    }
}
