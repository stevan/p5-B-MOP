
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Opcodes;

my sub DUMP ($op) {
    return 'NULL' if $op isa B::NULL;
    sprintf '%s(%d): %s = %s', blessed $op, ${$op}, $op->name, $op->desc;
}

class B::MOP::Code::SubroutineCall {
    field $call :param;

    field $cv;
    field @args;

    ADJUST {
        my $mark = $call->first->first;
        # TODO: make sure this is a pushmark

        my $next = $mark->next;
        while (1) {
            push @args => $next;
            $next = $next->next;
            last if ${$next} == ${$call};
        }

        my $target = pop @args;
        # TODO: make sure this is a GV

        $cv = $target->gv->CV;
    }

    method get_args { @args }

    method subroutine_name { $cv->GV->NAME }
    method package_name    { $cv->GV->STASH->NAME }

    method fully_qualified_name {
        join '::' => $cv->GV->STASH->NAME, $cv->GV->NAME;
    }
}
