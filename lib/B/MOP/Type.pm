
use v5.40;
use experimental qw[ class ];

class B::MOP::Type {
    use overload '""' => 'to_string';

    method name { __CLASS__ =~ s/^B::MOP::Type:://r }

    method compare ($type) {
        __CLASS__ eq blessed $type
            ? 0
            : $type->isa(__CLASS__)
                ? -1
                : __CLASS__->isa(blessed $type)
                    ? 1
                    : undef
    }

    method to_string {
        sprintf '/%s/' => $self->name
    }
}

class B::MOP::Type::Scalar  :isa(B::MOP::Type) {}

class B::MOP::Type::Bool    :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::String  :isa(B::MOP::Type::Scalar) {}
class B::MOP::Type::Numeric :isa(B::MOP::Type::Scalar) {}

class B::MOP::Type::Int     :isa(B::MOP::Type::Numeric) {}
class B::MOP::Type::Float   :isa(B::MOP::Type::Numeric) {}
