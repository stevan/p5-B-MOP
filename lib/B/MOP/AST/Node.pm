
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node :isa(B::MOP::AST::Abstract::HasType) {
    field $id :reader;

    my $ID_SEQ = 0;
    ADJUST { $id = ++$ID_SEQ }

    method name { sprintf '%s[%d]' => $self->node_type, $id }

    method node_type { __CLASS__ =~ s/B::MOP::AST::Node:://r }

    method accept ($v) { $v->visit($self) }

    method to_JSON ($full=false) {
        return +{
            node => $self->name,
            type => $self->type->to_JSON($full),
        }
    }
}
