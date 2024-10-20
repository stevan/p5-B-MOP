
use v5.40;
use experimental qw[ class ];

class B::MOP::Type {
    use overload '""' => 'to_string';

    field $rel :param = undef;

    method has_relation { !! $rel }
    method relation     {    $rel }

    method superclass { mro::get_linear_isa(__CLASS__)->[1] }

    method name  { __CLASS__ =~ s/^B::MOP::Type:://r }

    method cast ($type) {
        return $type->clone(
            rel => B::MOP::Type::Relation->new(
                lhs => $type,
                rhs => $self,
            )
        );
    }

    method is_same_as ($t) {
        #say ">> IS SAME AS? ",__CLASS__," ?= ",blessed $t;
        __CLASS__ eq blessed $t }

    method is_exactly ($t) {
        #say "! entering: $self with: $t";
        return false
            if !$self->is_same_as($t);
        #say "! $self is the same as: $t";
        return true
            if !$rel && !$t->has_relation;
        #say "! $self and $t have relations";
        #say ">> rel-rhs: ",$rel->rhs," is same as ",$t->relation->rhs;
        return $rel->rhs->is_same_as($t->relation->rhs)
            if $rel && $t->has_relation;
        #say "?? dunno ??";
        return false;
    }

    method clone (%args) {
        $args{rel} //= $rel;
        return __CLASS__->new(%args);
    }

    method to_string {
        if ($rel) {
            sprintf '*%s[%s %s]' =>
                $self->name,
                $rel->relation,
                $rel->rhs->to_string;
        } else {
            sprintf '*%s' => $self->name;
        }
    }
}

class B::MOP::Type::Void    :isa(B::MOP::Type) {}
class B::MOP::Type::Scalar  :isa(B::MOP::Type) {}

class B::MOP::Type::Bool    :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::String  :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::Numeric :isa(B::MOP::Type::Scalar) {}

class B::MOP::Type::Int     :isa(B::MOP::Type::Numeric) {}
class B::MOP::Type::Float   :isa(B::MOP::Type::Numeric) {}

# ...

class B::MOP::Type::Ref :isa(B::MOP::Type::Scalar) {
    field $inner_type :param :reader = undef;

    method set_inner_type ($t) { $inner_type = $t }

    method cast_inner_type ($type) {
        # NOTE:
        # Decide if this method is a good idea or not.
        # It probably is not, but perhaps there are
        # some scenarios where we want to be able to
        # do this. So I will keep it for now, but with
        # this note.
        return __CLASS__->new(
            inner_type => $inner_type->cast($type),
            rel        => B::MOP::Type::Relation->new(
                lhs => $type,
                rhs => $inner_type,
            )
        );
    }

    method is_same_as ($t) {
        #say ">> >> REF->IS SAME AS?";
        my $x = $self->SUPER::is_same_as($t);
        #say ">> >> REF->INNER->IS SAME AS?";
        $x && $inner_type->is_same_as($t isa __CLASS__ ? $t->inner_type : $t)
    }

    method clone (%args) {
        $args{rel}        //= $self->relation if $self->has_relation;
        $args{inner_type} //= $inner_type;
        return __CLASS__->new(%args);
    }

    method to_string {
        my $rel = $self->relation;
        if ($rel) {
            sprintf '*%s{ %s }[%s %s]' =>
                $self->name,
                $inner_type->to_string,
                $rel->relation,
                $rel->rhs->to_string;
        } else {
            sprintf '*%s{ %s }' => $self->name, $inner_type->to_string;
        }
    }
}

# ...

class B::MOP::Type::Signature {
    use overload '""' => 'to_string';

    field $parameters  :param :reader = [];
    field $return_type :param :reader = undef;

    ADJUST {
        $return_type //= B::MOP::Type::Void->new;
    }

    method to_string {
        sprintf '(%s) -> %s' =>
            (join ', ' => map { sprintf '%s %s' => $_->type->to_string, $_->name } @$parameters),
            ($return_type->to_string),
        ;
    }
}

class B::MOP::Type::Variable {
    use overload '""' => 'to_string';

    field $type :param :reader = undef;

    field $id  :reader;
    field $err :reader;

    our $ID_SEQ = 0;

    ADJUST {
        $id = ++$ID_SEQ;
        #warn "Created TypeVar($id)";
    }

    method is_resolved { !! $type }
    method resolve ($t) { $type = $t }

    method has_error { !! $err }
    method type_error ($e) { $err = $e }

    method cast_into ($a) {
        $type = $type->cast($a)
            unless $type->is_same_as($a);
        $self;
    }

    method is_same_as ($a) {
        return unless $type && $a->is_resolved;
        return $type->is_same_as($a->type);
    }

    method relates_to ($a) {
        B::MOP::Type::Relation->new( lhs => $type, rhs => $a->type );
    }

    method stringify {
        return sprintf '!E:%d(%s)' => $id, $err->rel if $err;
        return sprintf '`a:%d(%s)' => $id, $type // '~';
    }

    method to_string {
        return sprintf '`a:%d(%s)' => $id, $type // '~';
    }
}

class B::MOP::Type::Relation {
    use overload '""' => 'to_string';

    use constant IS_SAME_TYPE    => '=='; # Int     == Int
    use constant IS_SUB_TYPE     => ':>'; # Int      > Numeric
    use constant IS_SUPER_TYPE   => '<:'; # Numeric <  Int
    use constant IS_INCOMPATIBLE => '!='; # Bool    != Int

    field $lhs :param :reader;
    field $rhs :param :reader;

    field $relation :reader;

    ADJUST {
        if (blessed $lhs eq blessed $rhs) {
            $relation = B::MOP::Type::Relation->IS_SAME_TYPE;
        }
        elsif ($lhs->isa(blessed $rhs)) {
            $relation = B::MOP::Type::Relation->IS_SUB_TYPE;
        }
        elsif ($rhs->isa(blessed $lhs)) {
            $relation = B::MOP::Type::Relation->IS_SUPER_TYPE;
        }
        else {
            $relation = B::MOP::Type::Relation->IS_INCOMPATIBLE;
        }
    }

    method types_are_equal  { $relation eq IS_SAME_TYPE    }
    method can_upcast_to    { $relation eq IS_SUPER_TYPE   }
    method can_downcast_to  { $relation eq IS_SUB_TYPE     }
    method are_incompatible { $relation eq IS_INCOMPATIBLE }

    method has_common_superclass {
        my @lhs_mro = mro::get_linear_isa(blessed $lhs)->@*;
        my @rhs_mro = mro::get_linear_isa(blessed $rhs)->@*;
        foreach my ($i, $lhs) (indexed @lhs_mro) {
            last if $lhs eq 'B::MOP::Type';
            return $lhs if scalar grep $lhs eq $_, @rhs_mro;
        }
        return;
    }

    method to_string {
        sprintf '(%s %s %s)' => $lhs, $relation, $rhs
    }
}

class B::MOP::Type::Error {
    use overload '""' => 'to_string';

    field $node :param :reader;
    field $rel  :param :reader;

    method to_string {
        join "\n  ",
            "TYPE ERROR : $rel",
                "in ".$node->name." = {",
                "    node_type = ".$node->type_var,
                ($node->can('lhs') ? "    lhs_type  = ".$node->lhs->type_var    : ()),
                ($node->can('rhs') ? "    rhs_type  = ".$node->rhs->type_var    : ()),
                ($node->has_target ? "    target    = ".$node->target->type_var : ()),
                "}\n";
    }
}








