
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;
use B::MOP::Opcode;
use B::MOP::Variable;

class B::MOP::Subroutine {
    field $name :param :reader;
    field $body :param :reader;

    field $cv  :reader;
    field @ops :reader;
    field $ast :reader;
    field @pad;

    ADJUST {
        $cv = B::svref_2object($body);

        # wrap the ops ...

        my $next = $cv->START;
        until ($next isa B::NULL) {
            push @ops => B::MOP::Opcode->get( $next );
            $next = $next->next;
        }

        # collect the pad ...

        if (!(($cv->PADLIST->ARRAY)[0] isa B::NULL)) {
            foreach my ($i, $entry) (indexed(($cv->PADLIST->ARRAY)[0]->ARRAY)) {
                next if $entry->IsUndef                 # skip undef stuff ...
                     || $entry->PVX =~ /Object\:\:Pad/; # skip Object::Pad hack
                $pad[$i] = B::MOP::Variable->new( entry => $entry );
            }
        }

        # build the AST ...

        $ast = B::MOP::AST->new->build_subroutine( @ops );
    }

    method pad { grep defined, @pad }

    method pad_lookup ($index) {
        return if ($cv->PADLIST->ARRAY)[0] isa B::NULL;
        return B::MOP::Variable->new( entry =>
            (($cv->PADLIST->ARRAY)[0]->ARRAY)[$index]
        );
    }
}
