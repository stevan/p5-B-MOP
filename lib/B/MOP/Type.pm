
use v5.40;
use experimental qw[ class ];

class B::MOP::Type {
    use overload '""' => 'to_string';

    field $rel :param = undef;

    method name { __CLASS__ =~ s/^B::MOP::Type:://r }

    method cast ($type) {
        return blessed($type)->new(
            rel => B::MOP::Type::Relation->new(
                lhs => $type,
                rhs => $self,
            )
        );
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

class B::MOP::Type::Scalar  :isa(B::MOP::Type) {}

class B::MOP::Type::Bool    :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::String  :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::Numeric :isa(B::MOP::Type::Scalar) {}

class B::MOP::Type::Int     :isa(B::MOP::Type::Numeric) {}
class B::MOP::Type::Float   :isa(B::MOP::Type::Numeric) {}

class B::MOP::Type::Variable {
    use overload '""' => 'to_string';

    field $type :param :reader = undef;

    field $id :reader;

    my $ID_SEQ = 0;

    ADJUST {
        $id = ++$ID_SEQ;
    }

    method is_resolved { !! $type }
    method resolve ($t) { $type = $t }

    method cast_into ($a) {
        $type = $type->cast($a);
        $self;
    }

    method to_string {
        sprintf '`a:%d(%s)' => $id, $type // '~';
    }
}

class B::MOP::Type::Relation {
    use overload '""' => 'to_string';

    use constant IS_SAME_TYPE    => '=='; # Int     == Int
    use constant IS_SUB_TYPE     =>  '>'; # Int      > Numeric
    use constant IS_SUPER_TYPE   =>  '<'; # Numeric <  Int
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

    method types_are_equal  { $relation == IS_SAME_TYPE    }
    method can_upcast_to    { $relation == IS_SUPER_TYPE   }
    method can_downcast_to  { $relation == IS_SUB_TYPE     }
    method are_incompatible { $relation == IS_INCOMPATIBLE }

    method to_string {
        sprintf '(%s %s %s)' => $lhs, $relation, $rhs
    }
}










