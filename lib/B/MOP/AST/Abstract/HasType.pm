
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Abstract::HasType {
    field $type :reader;

    ADJUST {
        $type = B::MOP::Type::Variable->new;
    }

    method set_type ($a) {
        if ($type->is_resolved) {
            $type->cast_into($a->type);
        } else {
            $type->resolve($a->type);
        }
    }
}
