
use v5.40;
use experimental qw[ class ];

use B ();

class B::MOP::Code::Lexical {
    field $entry :param;

    method name { $entry->PVX }

    method is_field    { !! $entry->FLAGS & B::PADNAMEf_FIELD }
    method is_our      { !! $entry->FLAGS & B::PADNAMEf_OUR   }
    method is_local    {  !$self->is_field  && !$self->is_our }
}
