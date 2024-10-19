
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::CollectAllTypes {
    field $subroutine :param :reader;
    field $f          :param :reader = undef;

    field @types :reader;

    ADJUST {
        $f //= sub ($t) { $t };
    }

    method collect_all_types {
        @types = (); # clear them before we collect them (again) ...
        my $ast = $subroutine->ast;
        foreach my $symbol ($ast->env->get_all_symbols) {
            push @types => $f->( $symbol->type_var );
        }
        $ast->accept($self);
        return @types;
    }

    method collect_all_type_errors {
        grep $_->has_error, $self->collect_all_types
    }

    method visit ($node, @) {
        return unless $node isa B::MOP::AST::Abstract::HasTypeVariable;
        push @types => $f->( $node->type_var );
    }
}
