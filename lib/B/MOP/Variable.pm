
use v5.40;
use experimental qw[ class ];

use B ();

class B::MOP::Variable {
    field $entry :param;
    field $type;

    field $is_argument = false;

    ADJUST {
        $type = B::MOP::Type::Scalar->new;
    }

    method get_type      { $type      }
    method set_type ($t) { $type = $t }

    method mark_as_argument { $is_argument = true }

    method name { $entry->PVX }

    method is_argument { $is_argument }
    method is_field    { !! $entry->FLAGS & B::PADNAMEf_FIELD }
    method is_our      { !! $entry->FLAGS & B::PADNAMEf_OUR   }
    method is_local    {  !$self->is_field  && !$self->is_our }
}
