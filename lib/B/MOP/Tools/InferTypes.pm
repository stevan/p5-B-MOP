
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::InferTypes;

class B::MOP::Tools::InferTypes {
    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        $subroutine->ast->accept(B::MOP::Tools::AST::InferTypes->new( mop => $mop ));
    }

    method visit_package ($package) {

    }

    method visit ($a) {
        return $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        return $self->visit_package($a)    if $a isa B::MOP::Package;
    }
}
