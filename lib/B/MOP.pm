
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

use B::MOP::Tools::BuildDependencyGraph;
use B::MOP::Tools::ResolveAllCalls;
use B::MOP::Tools::TypeChecker;

use B::MOP::Tools::AST::Dumper::Perl;

class B::MOP {
    field %lookup;

    method load_package ($pkg) {
        my $package = B::MOP::Package->new( name => $pkg );
        $lookup{ $pkg } = $package;
    }

    method get_all_packages { sort { $a->depends_on($b) ? 1 : -1 } values %lookup }

    method get_package ($pkg) { $lookup{ $pkg } }

    method accept ($v) {
        foreach my $package ($self->get_all_packages) {
            $package->accept($v);
        }
    }

    method finalize {
        $self->accept(B::MOP::Tools::BuildDependencyGraph->new( mop => $self ));
        $self->accept(B::MOP::Tools::ResolveAllCalls->new( mop => $self ));
        $self->accept(B::MOP::Tools::TypeChecker->new( mop => $self ));
    }
}
