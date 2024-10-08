
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

class B::MOP {
    field $init_cv;
    field %lookup;

    method load (@to_load) {
        foreach my $pkg (@to_load) {
            $lookup{ $pkg } //= B::MOP::Package->new(
                name => $pkg,
                root => $self,
            );
        }
        $self;
    }

    method get_package ($pkg) { $lookup{ $pkg } }

    method resolve_subroutine_call ($call) {
        my $package = $lookup{ $call->package_name };
        my $subroutine = $package->get_subroutine( $call->subroutine_name );
        return $subroutine;
    }
}
