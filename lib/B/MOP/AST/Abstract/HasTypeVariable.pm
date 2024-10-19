
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Abstract::HasTypeVariable {
    field $type_var :reader;

    ADJUST {
        $type_var = B::MOP::Type::Variable->new;
    }

    method set_type ($a) {
        if ($type_var->is_resolved) {
            $type_var->cast_into($a->type);
        } else {
            $type_var->resolve($a->type);
        }
    }
}
