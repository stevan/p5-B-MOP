
use v5.40;
use experimental qw[ class ];

class B::MOP::Type {

    method name { __CLASS__ =~ s/^B::MOP::Type:://r }
}
class B::MOP::Type::String  :isa(B::MOP::Type) {}
class B::MOP::Type::Numeric :isa(B::MOP::Type) {}
class B::MOP::Type::Int     :isa(B::MOP::Type::Numeric) {}
class B::MOP::Type::Float   :isa(B::MOP::Type::Numeric) {}
