
use v5.40;
use experimental qw[ class ];

use B::MOP::Tools::AST::CollectSubroutineCalls;

class B::MOP::Tools::BuildDependencyGraph {
    field $mop :param :reader;

    method visit_subroutine ($subroutine) {
        my $collector = B::MOP::Tools::AST::CollectSubroutineCalls->new( mop => $mop );
        $subroutine->ast->accept($collector);
        $subroutine->set_subroutines_called($collector->subroutines_called);
    }

    method visit_package ($package) {
        my %seen;
        my @depends_on;
        foreach my $s ($package->get_all_subroutines) {
            foreach my $c ($s->subroutines_called->@*) {
                if ($c->stash_name ne $package->name) {
                    unless (exists $seen{ $c->stash_name }) {
                        push @depends_on => $c->stash_name;
                        $seen{ $c->stash_name }++;
                    }
                }
            }
        }
        $package->set_modules_required(\@depends_on);
    }

    method visit ($a) {
        $self->visit_subroutine($a) if $a isa B::MOP::Subroutine;
        $self->visit_package($a)    if $a isa B::MOP::Package;
        return;
    }
}
