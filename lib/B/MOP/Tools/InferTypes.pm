
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::InferTypes {

    method visit ($node) {
        if ($node isa B::MOP::AST::Local::Store) {
            my $node_type   = $node->type;
            my $rhs_type    = $node->rhs->type;
            my $target      = $node->target;
            my $target_type = $target->type;

            #say $node->name," - node: $node_type (- $target_type) rhs: $rhs_type";
            $node->set_type($node->rhs->type);
            #say $node->name," + node: $node_type (- $target_type) rhs: $rhs_type";
            $target->set_type($node->type);
            #say $node->name," + node: $node_type (+ $target_type) rhs: $rhs_type";
        }
        elsif ($node isa B::MOP::AST::Local::Fetch) {
            my $node_type   = $node->type;
            my $target      = $node->target;
            my $target_type = $target->type;

            #say $node->name," - node: $node_type (- $target_type)";
            $node->set_type($node->target->type);
            #say $node->name," + node: $node_type (+ $target_type)";
        }
        elsif ($node isa B::MOP::AST::Op::Numeric) {
            my $node_type = $node->type;
            my $lhs_type  = $node->lhs->type;
            my $rhs_type  = $node->rhs->type;

            my $hs_rel = B::MOP::Type::Relation->new(
                lhs => $lhs_type->type,
                rhs => $rhs_type->type,
            );

            say $node->name," - node: $node_type lhs: $lhs_type rhs: $rhs_type";
            say $node->name," - node: $node_type ? $hs_rel";
            if ($hs_rel->types_are_equal) {
                $node->set_type($node->lhs->type);
                say $node->name," + node: $node_type lhs: $lhs_type rhs: $rhs_type";
            }
            elsif ($hs_rel->are_incompatible) {
                die join "\n  ",
                    "TYPE ERROR : $hs_rel",
                        "in ".$node->name." = {",
                        "    node_type = $node_type",
                        "    lhs_type  = $lhs_type",
                        "    rhs_type  = $rhs_type",
                        "}\n";
            }

        }
    }
}
