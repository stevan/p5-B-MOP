
use v5.40;
use experimental qw[ class ];

my sub DUMP ($op) {
    return 'NULL' if $op isa B::NULL;
    sprintf '%s: %s = %s', $op, $op->name, $op->desc;
}

use B ();
use B::MOP::Opcodes;

use B::MOP::Code::Signature;
use B::MOP::Code::Lexical;
use B::MOP::Code::SubroutineCall;

class B::MOP::Subroutine {
    field $name    :param :reader;
    field $body    :param :reader;
    field $package :param :reader;

    field $cv;
    field @pad;

    field @opcodes   :reader;
    field $signature :reader;

    ADJUST {
        $cv = B::svref_2object($body);

        my @padlist;
        if (!(($cv->PADLIST->ARRAY)[0] isa B::NULL)) {
            @padlist = ($cv->PADLIST->ARRAY)[0]->ARRAY;
        }

        my $op = $cv->START;
        push @opcodes => $op;

        my @params;
        while ($op = $op->next) {
            last if $op isa B::NULL;
            push @opcodes => $op;
            if ($op->name eq B::MOP::Opcodes->ARGELEM) {
                push @params => $padlist[ $op->targ ]->PVX;
            }
        }

        $signature = B::MOP::Code::Signature->new( params => \@params );

        foreach my $entry (@padlist) {
            next if $entry->IsUndef;
            next if $entry->PVX =~ /Object\:\:Pad/; # skip Object::Pad hack

            push @pad => B::MOP::Code::Lexical->new(
                entry    => $entry,
                is_param => $signature->is_param( $entry->PVX )
            );
        }
    }

    method get_locals     { grep $_->is_local, @pad }
    method get_parameters { grep $_->is_param, @pad }

    method get_subroutine_calls {
        map  { B::MOP::Code::SubroutineCall->new( call => $_ ) }
        grep { $_->name eq B::MOP::Opcodes->ENTERSUB }
        @opcodes;
    }

}
