
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::InferTypes;
use B::MOP::Tools::AST::FinalizeTypes;

class B::MOP::Tools::TypeChecker {
    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        $subroutine->ast->accept(B::MOP::Tools::AST::InferTypes->new( mop => $mop ));
        $subroutine->ast->accept(B::MOP::Tools::AST::FinalizeTypes->new( env => $subroutine->ast->env ));
    }

    method visit_package ($package) {
        # ... nothing for now
    }

    method visit ($a) {
        return $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        return $self->visit_package($a)    if $a isa B::MOP::Package;
    }
}
