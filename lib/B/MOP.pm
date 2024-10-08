
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

class B::MOP {
    field %lookup;

    method load_package ($pkg) {
        $lookup{ $pkg } //= B::MOP::Package->new(
            name => $pkg
        );
    }
}
