
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::Package;

class B::MOP {


    method load_package ($pkg) { B::MOP::Package->new( name => $pkg ) }

}
