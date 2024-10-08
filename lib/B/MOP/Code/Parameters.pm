
use v5.40;
use experimental qw[ class ];

class B::MOP::Code::Parameters {
    field $params :param;

    method params { @$params }
    method arity  { scalar @$params }

    method has_param ($name) {
        !! grep { $name eq $_->name } @$params;
    }
}
