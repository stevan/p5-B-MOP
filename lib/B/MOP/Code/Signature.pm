
use v5.40;
use experimental qw[ class ];

class B::MOP::Code::Signature {
    field $params :param;

    field $is_slurpy = false;

    ADJUST {
        $is_slurpy = !!($params->[-1] =~ /^[@%]/) if @$params;
    }

    method arity { $is_slurpy ? -1 : scalar @$params }

    method param_list { @$params }
    method is_param  ($name) { !! grep { $name eq $_ } @$params }
}
