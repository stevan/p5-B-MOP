
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::ResolveCalls;

class B::MOP::Tools::ResolveAllCalls {
    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        $subroutine->ast->accept(B::MOP::Tools::AST::ResolveCalls->new( mop => $mop ));
    }

    method visit_package ($package) {
        # ... nothing for now
    }

    method visit ($a) {
        $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        $self->visit_package($a)    if $a isa B::MOP::Package;
        return;
    }
}
