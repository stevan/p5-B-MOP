
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::ResolveCalls {
    field $mop :param :reader;

    field @callsites :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Call::Subroutine;
        my $cv  = $node->lhs->glob->cv;
        my $pkg = $mop->get_package( $cv->stash_name );
        my $sub = $pkg->get_subroutine( $cv->name );
        $node->resolve_call($sub);
        push @callsites => $node;
    }

    method subroutines_called {
        my %seen;
        [ map {
            my $sub = $_->subroutine;
            my $name = $sub->fully_qualified_name;
            if (exists $seen{$name}) {
                ();
            } else {
                $seen{$name}++;
                $sub;
            }
        } @callsites ];
    }
}
