
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::InferTypes {

    method visit ($node) {
        if ($node isa B::MOP::AST::Local::Store) {
            my $node_type   = $node->type;
            my $rhs_type    = $node->rhs->type;
            my $target      = $node->target;
            my $target_type = $target->type;

            say $node->name," - node: $node_type (- $target_type) rhs: $rhs_type";
            $node->set_type($node->rhs->type);
            say $node->name," + node: $node_type (- $target_type) rhs: $rhs_type";
            $target->set_type($node->type);
            say $node->name," + node: $node_type (+ $target_type) rhs: $rhs_type";
        }
        elsif ($node isa B::MOP::AST::Local::Fetch) {
            my $node_type   = $node->type;
            my $target      = $node->target;
            my $target_type = $target->type;

            say $node->name," - node: $node_type (- $target_type)";
            $node->set_type($node->target->type);
            say $node->name," + node: $node_type (+ $target_type)";
        }
    }
}
