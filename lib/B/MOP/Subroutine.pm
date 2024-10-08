
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;
use B::MOP::Code::Lexical;

class B::MOP::Subroutine {
    field $name    :param :reader;
    field $body    :param :reader;
    field $package :param :reader;

    field $cv;
    field @pad;

    field $ast :reader;

    ADJUST {
        $cv = B::svref_2object($body);

        if (!(($cv->PADLIST->ARRAY)[0] isa B::NULL)) {
            foreach my $entry (($cv->PADLIST->ARRAY)[0]->ARRAY) {
                next if $entry->IsUndef;
                next if $entry->PVX =~ /Object\:\:Pad/; # skip Object::Pad hack
                push @pad => B::MOP::Code::Lexical->new( entry => $entry );
            }
        }

        $ast = B::MOP::AST->new->build_subroutine( $cv );
    }

    method get_locals { @pad }
}
