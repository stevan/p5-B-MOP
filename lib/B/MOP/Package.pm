
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Subroutine;

class B::MOP::Package {
    field $name :param :reader;

    field $stash       :reader;
    field %subroutines :reader;

    ADJUST {
        no strict 'refs';
        $stash = \%{"${name}::"};
    }

    method load_subroutines {
        foreach my $name ( keys %$stash ) {
            if ( my $code = *{ $stash->{$name} }{CODE} ) {
                $subroutines{ $name } = B::MOP::Subroutine->new(
                    name => $name,
                    body => $code
                )->load;
            }
        }
    }

    method load {
        $self->load_subroutines;
        $self;
    }
}
