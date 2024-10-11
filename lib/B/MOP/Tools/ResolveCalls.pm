
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::ResolveCalls;

class B::MOP::Tools::ResolveCalls {
    field $mop :param :reader;

    method visit ($subroutine) {
        return unless $subroutine isa B::MOP::Subroutine;

        $subroutine->ast->accept(
            B::MOP::Tools::AST::ResolveCalls->new( mop => $mop )
        );
    }
}
