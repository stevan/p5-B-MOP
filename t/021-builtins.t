
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
- a whole bunch of Unary Op builtins
    - specifically the ones which return values

=cut

package Foo {
    sub test {
        my $x = "10";
        my $y = int($x);
        my $z = ref($x);

        my $p = scalar($x);
        my $q = scalar($y);
        my $r = defined($y);
        my $s = is_weak($x);
        my $t = is_tainted($q);
        my $u = refaddr($r);
        my $v = reftype($r);
        my $w = ceil($r);

        my $c = floor($r);
        my $d = hex($y);
        my $e = oct($d);
        my $f = ord($s);
        my $g = chr($z);
        my $h = fc($v);
        my $i = lc($h);
        my $j = uc($g);
        my $k = ucfirst($d);
        my $l = lcfirst($d);
        my $m = length($k);
        my $n = chomp($m);
        my $o = chop($m);

        my $aa = abs($y);
        my $bb = cos($aa);
        my $cc = exp($aa);
        my $dd = log($aa);
        my $ee = sin($aa);
        my $ff = sqrt($aa);
        my $gg = quotemeta($aa);
        my $hh = blessed($aa);
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    check_env($test,
        [ '$x', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$y', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$z', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$p', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$q', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$r', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
        [ '$s', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
        # some builtins are imported as lexical subs too ...
        [ '&is_weak', B::MOP::Type::Scalar->new ],
        # and they appear in the pad as needed apparently ...
        [ '$t', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new) ],
        [ '&is_tainted', B::MOP::Type::Scalar->new ],
        [ '$u', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '&refaddr', B::MOP::Type::Scalar->new ],
        [ '$v', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '&reftype', B::MOP::Type::Scalar->new ],
        [ '$w', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '&ceil', B::MOP::Type::Scalar->new ],
        [ '$c', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '&floor', B::MOP::Type::Scalar->new ],
        [ '$d', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$e', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$f', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$g', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$h', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$i', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$j', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$k', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$l', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$m', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$n', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new) ],
        [ '$o', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],

        [ '$aa', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new) ],
        [ '$bb', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new) ],
        [ '$cc', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new) ],
        [ '$dd', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new) ],
        [ '$ee', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new) ],
        [ '$ff', B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new) ],
        [ '$gg', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '$hh', B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new) ],
        [ '&blessed', B::MOP::Type::Scalar->new ],
    );

    check_statement_types($test,
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Bool->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Int->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Numeric->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::Float->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
        B::MOP::Type::Scalar->new->cast(B::MOP::Type::String->new),
    );

    say node_to_json($test) if $ENV{DEBUG};

    use Test::Differences;
    use B::MOP::Tools::AST::Dumper::JSON;
    eq_or_diff(
        B::MOP::Tools::AST::Dumper::JSON->new( subroutine => $test )->dump,
        $test->to_JSON,
        '... how did we do?'
    );
};


done_testing;
