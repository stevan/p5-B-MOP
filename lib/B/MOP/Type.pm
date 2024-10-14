
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
        return blessed($type)->new(
            rel => B::MOP::Type::Relation->new(
                lhs => $type,
                rhs => $self,
            )
        );
    }

    method is_same_as ($t) { __CLASS__ eq blessed $t }

    method is_exactly ($t) {
        return false
            unless $self->is_same_as($t);
        return true
            if !$rel && !$t->has_relation;
        return $rel->rhs->is_same_as($t->relation->rhs)
            if $rel && $t->has_relation;
        return false;
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

class B::MOP::Type::Signature {
    use overload '""' => 'to_string';

    field $parameters  :param :reader = [];
    field $return_type :param :reader = undef;

    ADJUST {
        $return_type //= B::MOP::Type::Void->new;
    }

    method to_JSON ($full=false) {
        +{
            params      => [ (map $_->to_JSON($full), @$parameters) ],
            return_type => $return_type->to_string,
        }
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

    my $ID_SEQ = 0;

    ADJUST {
        $id = ++$ID_SEQ;
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

    method to_JSON ($full=false) {
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
                "    node_type = ".$node->type,
                ($node->can('lhs') ? "    lhs_type  = ".$node->lhs->type    : ()),
                ($node->can('rhs') ? "    rhs_type  = ".$node->rhs->type    : ()),
                ($node->has_target ? "    target    = ".$node->target->type : ()),
                "}\n";
    }
}








