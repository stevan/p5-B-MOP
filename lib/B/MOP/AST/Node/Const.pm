
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Const :isa(B::MOP::AST::Node::Expression) {
    ADJUST {
        my $sv = $self->op->sv;
        if ($sv->type eq B::MOP::Opcode::Value::Types->IV) {
            $self->type_var->resolve(B::MOP::Type::Int->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->NV) {
            $self->type_var->resolve(B::MOP::Type::Float->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->PV) {
            $self->type_var->resolve(B::MOP::Type::String->new);
        }
    }

    method get_literal { $self->op->sv->literal }
}

class B::MOP::AST::Node::Const::Literal :isa(B::MOP::AST::Node::Expression) {
    field $literal :param :reader;
    field $type    :param;

    ADJUST {
        $self->type_var->resolve($type);
    }

    method get_literal { $literal }
}
