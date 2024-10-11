
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Subroutine;

class B::MOP::Package {
    field $name :param :reader;
    field $stash       :reader;

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
                    package => $self,
                    name    => $name,
                    body    => $code,
                );

                $lookup{ $name } = $sub;
            }
        }
    }

    method get_all_subroutines { sort { $a->name cmp $b->name } values %lookup }

    method has_subroutine ($name) { exists $lookup{ $name } }
    method get_subroutine ($name) {        $lookup{ $name } }

    method accept ($v) {
        foreach my $subroutine ($self->get_all_subroutines) {
            $subroutine->accept($v);
        }
        $v->visit($self);
    }
}
