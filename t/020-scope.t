
use v5.40;
use experimental qw[ class ];

use Test::More;

use Test::B::MOP;
use B::MOP;

=pod

This tests ...
-

=cut

package Foo {
    sub test {
        my $x = 10;
        {
            my $x = 100 + $x;
            my $y = 1000;
            $x += $y;
        }
        $x + 5;
    }
}

my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
#$mop->finalize;
isa_ok($Foo,  'B::MOP::Package');

subtest '... Foo::test' => sub {
    my $test = $Foo->get_subroutine('test');
    isa_ok($test, 'B::MOP::Subroutine');

    say node_to_json($test) if $ENV{DEBUG};

};


done_testing;
