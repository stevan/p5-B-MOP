
use v5.40;
use experimental qw[ class ];

class B::MOP::AST::Node::Const :isa(B::MOP::AST::Node::Expression) {
    ADJUST {
        my $sv = $self->op->sv;
        if ($sv->type eq B::MOP::Opcode::Value::Types->IV) {
            $self->type->resolve(B::MOP::Type::Int->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->NV) {
            $self->type->resolve(B::MOP::Type::Float->new);
        }
        elsif ($sv->type eq B::MOP::Opcode::Value::Types->PV) {
            $self->type->resolve(B::MOP::Type::String->new);
        }
    }

    method get_literal { $self->op->sv->literal }

    method to_JSON {
        return +{
            $self->SUPER::to_JSON->%*,
            __literal => {
                value => $self->get_literal // 'undef',
            }
        }
    }
}
