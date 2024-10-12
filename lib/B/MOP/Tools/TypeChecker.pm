
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::InferTypes;
use B::MOP::Tools::AST::FinalizeTypes;

class B::MOP::Tools::TypeChecker {
    use constant DEBUG => $ENV{DEBUG_TYPES} // 0;

    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        DEBUG && say '>> CHECKING >> ',$subroutine->name,' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>';

        my $env = $subroutine->ast->env;
        $subroutine->ast->accept(B::MOP::Tools::AST::InferTypes->new( mop => $mop ));
        $subroutine->ast->accept(B::MOP::Tools::AST::FinalizeTypes->new( env => $env ));
        $subroutine->set_signature(
            B::MOP::Type::Signature->new(
                parameters  => [ $env->get_all_arguments ],
                return_type => $subroutine->ast->tree->type,
            )
        );

        DEBUG && say '<< CHECKED << ',$subroutine->name,' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<';
    }

    method visit_package ($package) {
        # ... nothing for now
    }

    method visit ($a) {
        return $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        return $self->visit_package($a)    if $a isa B::MOP::Package;
    }
}
