
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Code::Parameters;
use B::MOP::Code::Lexical;

class B::MOP::Subroutine {
    field $name :param :reader;
    field $body :param :reader;

    field $cv         :reader;
    field @opcodes    :reader;
    field @pad        :reader;
    field $parameters :reader;

    ADJUST {
        $cv = B::svref_2object($body);
    }

    method get_pad_list { ($cv->PADLIST->ARRAY)[0]->ARRAY }

    method load_parameters {
        my @padlist = $self->get_pad_list;

        my @params;
        foreach my $op (@opcodes) {
            next unless $op->name eq 'argelem';
            my $entry = $padlist[ $op->targ ];
            push @params => B::MOP::Code::Lexical->new(
                entry => $entry
            );
        }

        $parameters = B::MOP::Code::Parameters->new( params => \@params );
    }

    method load_pad {
        foreach my $entry ($self->get_pad_list) {
            next if $entry->IsUndef;
            next if $entry->PVX =~ /Object\:\:Pad/;        # skip Object::Pad hack
            next if $parameters->has_param( $entry->PVX ); # skip args ...
            push @pad => B::MOP::Code::Lexical->new( entry => $entry );
        }
    }

    method load_opcodes {
        my $op = $cv->START;
        push @opcodes => $op;

        while ($op = $op->next) {
            last if $op isa B::NULL;
            push @opcodes => $op;
        }
    }

    method load {
        $self->load_opcodes;
        $self->load_parameters;
        $self->load_pad;
        $self;
    }
}
