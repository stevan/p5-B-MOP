
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::ResolveCalls;

class B::MOP::Tools::BuildCallGraph {
    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        my $resolver = B::MOP::Tools::ResolveCalls->new( mop => $mop );
        $subroutine->ast->accept($resolver);
        $subroutine->set_subroutines_called($resolver->subroutines_called);
    }

    method visit_package ($package) {
        my @depends_on;
        foreach my $s ($package->get_all_subroutines) {
            foreach my $c ($s->subroutines_called->@*) {
                if ($c->package->name ne $package->name) {
                    push @depends_on => $c->package;
                }
            }
        }
        say "DEPENDS ON: ",(join ', ' => map $_->name, @depends_on);
    }

    method visit_mop ($mop) {

    }


    method visit ($a) {
        return $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        return $self->visit_package($a)    if $a isa B::MOP::Package;
        return $self->visit_mop($a)        if $a isa B::MOP;
    }
}
