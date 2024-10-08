
use v5.40;
use experimental qw[ class ];

use B        ();
use constant ();

class B::MOP::Opcodes {
    our @OPCODES;
    BEGIN {
        @OPCODES = qw[
            const

            argelem

            gv

            entersub

            pushmark
        ];
        foreach my $opcode (@OPCODES) {
            constant->import( uc $opcode, $opcode );
        }
    }
}
