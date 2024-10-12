
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::InferTypes;
use B::MOP::Tools::AST::FinalizeTypes;

class B::MOP::Tools::TypeChecker {
    use constant DEBUG => $ENV{DEBUG_TYPES} // 0;

    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        DEBUG && say '>> CHECKING >> ',$subroutine->name,' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>';
        $subroutine->ast->accept(B::MOP::Tools::AST::InferTypes->new( mop => $mop ));
        $subroutine->ast->accept(B::MOP::Tools::AST::FinalizeTypes->new( env => $subroutine->ast->env ));
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
