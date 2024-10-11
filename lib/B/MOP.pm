
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

use B::MOP::Tools::BuildCallGraph;
use B::MOP::Tools::ResolveCalls;
use B::MOP::Tools::InferTypes;
use B::MOP::Tools::FinalizeTypes;

class B::MOP {
    field %lookup;

    method load_package ($pkg) {
        my $package = B::MOP::Package->new( name => $pkg );
        $lookup{ $pkg } = $package;
    }

    method get_all_packages { sort { $a->name cmp $b->name } values %lookup }

    method get_package ($pkg) { $lookup{ $pkg } }

    method accept ($v) {
        foreach my $package ($self->get_all_packages) {
            $package->accept($v);
        }
        $v->visit($self);
    }

    method finalize {
        my $call_graph_builder = B::MOP::Tools::BuildCallGraph->new( mop => $self );
        $self->accept($call_graph_builder);
    }
}
