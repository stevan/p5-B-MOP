
use v5.40;
use experimental qw[ class ];

class B::MOP::Type {
    use overload '""' => 'to_string';

    field $prev :param = undef;

    method has_prev { defined $prev }
    method get_prev {         $prev }

    method name { __CLASS__ =~ s/^B::MOP::Type:://r }

    method is_same_type    ($type) { __CLASS__ eq blessed $type }
    method can_cast_to     ($type) { my $x = $self->compare($type); defined $x && $x !=  0 }
    method can_upcast_to   ($type) { my $x = $self->compare($type); defined $x && $x ==  1 }
    method can_downcast_to ($type) { my $x = $self->compare($type); defined $x && $x == -1 }

    method cast ($type) {
        return unless $self->can_cast_to($type);
        return blessed($type)->new( prev => $self );
    }

    method compare ($type) {
        __CLASS__ eq blessed $type               # if types are equal
            ? 0                                  # ... return 0
            : $type->isa(__CLASS__)              # if type is subclass
                ? -1                             # ... return -1
                : __CLASS__->isa(blessed $type)  # if we are subclass of type
                    ? 1                          # .. return 1
                    : undef                      # we have no relation
    }                                            # ... return undef

    method to_string {
        if ($prev) {
            my $rel = $self->compare($prev);
            sprintf '`%s[%s %s]' =>
                $self->name,
                ($rel >= 0 ? '>' : '<'),
                $prev->to_string;
        } else {
            sprintf '`%s' => $self->name;
        }
    }
}

class B::MOP::Type::Scalar  :isa(B::MOP::Type) {}

class B::MOP::Type::Bool    :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::String  :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::Numeric :isa(B::MOP::Type::Scalar) {}

class B::MOP::Type::Int     :isa(B::MOP::Type::Numeric) {}
class B::MOP::Type::Float   :isa(B::MOP::Type::Numeric) {}
