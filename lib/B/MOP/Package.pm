
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Subroutine;

class B::MOP::Package {
    field $name :param :reader;
    field $stash       :reader;

    field %lookup;

    field $modules_required :reader = [];

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

    method set_modules_required ($modules) { $modules_required = $modules }

    method depends_on ($p) { !! scalar grep { $p->name eq $_ } @$modules_required }

    method get_all_subroutines { sort { $a->depends_on($b) ? -1 : 1 } values %lookup }

    method has_subroutine ($name) { exists $lookup{ $name } }
    method get_subroutine ($name) {        $lookup{ $name } }

    method accept ($v) {
        foreach my $subroutine ($self->get_all_subroutines) {
            $subroutine->accept($v);
        }
        $v->visit($self);
    }
}
