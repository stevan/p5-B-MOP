
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;

use B::MOP::Tools::InferTypes;
use B::MOP::Tools::FinalizeTypes;
use B::MOP::Tools::ResolveCalls;

class B::MOP::Subroutine {
    field $package :param :reader;
    field $name    :param :reader;
    field $body    :param :reader;

    field $cv  :reader;
    field $ast :reader;

    field $resolved  = false;
    field $inferred  = false;
    field $finalized = false;

    ADJUST {
        $cv  = B::svref_2object($body);
        $ast = B::MOP::AST->new->build( $cv );
    }

    method fully_qualified_name { join '::' => $package->name, $name }

    method finalize ($mop) {
        say "-->> finalizing subroutine($name)";

        try {
            $ast->accept(B::MOP::Tools::ResolveCalls->new( mop => $mop ));
            $resolved = true;
        } catch ($e) {
            warn "Errors during subroutine($name) resolving calls: $e\n";
        }

        return unless $resolved;
        say "     ** resolved calls in subroutine($name)";

        try {
            $ast->accept(B::MOP::Tools::InferTypes->new);
            $inferred = true;
        } catch ($e) {
            warn "Errors during subroutine($name) type inference: $e\n";
        }

        return unless $inferred;
        say "     ** inferred types in subroutine($name)";

        try {
            $ast->accept(B::MOP::Tools::FinalizeTypes->new( env => $ast->env ));
            $finalized = true;
        } catch ($e) {
            warn "Errors during subroutine($name) type finalization: $e\n";
        }

        return unless $finalized;
        say "     ** finalized types in subroutine($name)";

        say "--<< subroutine($name) finalized";
        return true;
    }
}
