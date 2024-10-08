
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Subroutine;

class B::MOP::Package {
    field $root :param :reader;
    field $name :param :reader;

    field $stash       :reader;
    field @subroutines :reader;

    field %lookup;

    ADJUST {
        {
            no strict 'refs';
            $stash = \%{"${name}::"};
        }

        foreach my $name ( keys %$stash ) {
            if ( my $code = *{ $stash->{$name} }{CODE} ) {

                # FIXME:
                # skip XS subs ...

                # FIXME:
                # check COMPSTASH to make sure it comes
                # from our package, and skip if not
                # use Sub::Metadata for this??

                my $sub = B::MOP::Subroutine->new(
                    name    => $name,
                    body    => $code,
                    package => $self,
                );

                $lookup{ $name } = $sub;
                push @subroutines => $sub;
            }
        }
    }

    method has_subroutine ($name) { exists $lookup{ $name } }
    method get_subroutine ($name) {        $lookup{ $name } }
}
