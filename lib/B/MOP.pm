
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

class B::MOP {
    field %lookup;
    field @packages;

    method load_package ($pkg) {
        my $package = B::MOP::Package->new( name => $pkg );
        push @packages => $package;
        $lookup{ $pkg } = $package;
    }

    method get_package ($pkg) { $lookup{ $pkg } }

    method finalize {
        say ">> Finalizing MOP";
        foreach my $package (@packages) {
            $package->finalize($self);
        }
        say "<< MOP Finalized";
    }
}
