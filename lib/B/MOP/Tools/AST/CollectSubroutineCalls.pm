
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::CollectSubroutineCalls {
    field $mop :param :reader;

    field @calls :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Node::Call::Subroutine;
        push @calls => $node->glob->cv;
    }

    method subroutines_called {
        my %seen;
        [ map {
            my $name = $_->fully_qualified_name;
            if (exists $seen{$name}) {
                ();
            } else {
                $seen{$name}++;
                $_;
            }
        } @calls ];
    }
}
