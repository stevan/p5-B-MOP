
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::InferTypes {

    my sub binop_type_error ($node, $rel) {
        join "\n  ",
            "TYPE ERROR : $rel",
                "in ".$node->name." = {",
                "    node_type = ".$node->type,
                "    lhs_type  = ".$node->lhs->type,
                "    rhs_type  = ".$node->rhs->type,
                "}\n";
    }

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

            my $lhs_to_node = B::MOP::Type::Relation->new(
                lhs => $lhs_type->type,
                rhs => $node_type->type,
            );

            my $lhs_to_rhs = B::MOP::Type::Relation->new(
                lhs => $lhs_type->type,
                rhs => $rhs_type->type,
            );

            my $rhs_to_node = B::MOP::Type::Relation->new(
                lhs => $rhs_type->type,
                rhs => $node_type->type,
            );

            say '==BEGIN== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->type;
            say '==BEGIN== ',$node->name,' =====================================';
            say "[ lhs ->  rhs ] = $lhs_to_rhs";
            say "[ lhs -> node ] = $lhs_to_node";
            say "[ rhs -> node ] = $rhs_to_node";

            die binop_type_error($node, $lhs_to_node)
                if $lhs_to_node->are_incompatible;

            say $node->name," ? TEST 1 lhs is compat with node (lhs->node: $lhs_to_node)";

            die binop_type_error($node, $lhs_to_node)
                if $lhs_to_node->are_incompatible;

            say $node->name," ? TEST 2 rhs is compat with node (rhs->node: $rhs_to_node)";

            say $node->name," ! The operands are compatible with the nodes required type";

            if ($lhs_to_rhs->are_incompatible) {
                say $node->name," - STATE 1 lhs and rhs are not compat (lhs->rhs: $lhs_to_rhs)";
                say $node->name," @@@ END 1 do nothing, the nodes are not compatible, but are within the node type";
            }
            else {
                say $node->name," - STATE 2 lhs and rhs are compat (lhs->rhs: $lhs_to_rhs)";
                if ($lhs_to_rhs->types_are_equal) {
                    say $node->name," - STATE 2.1 lhs == rhs are the same (lhs->rhs: $lhs_to_rhs)";

                    my $hs_to_node = $lhs_to_node;
                    if ($hs_to_node->types_are_equal) {
                        say $node->name," - STATE 2.1.1 lhs == rhs == node";
                        say $node->name," @@@ END 2 do nothing, the nodes are all the same type ";
                    }
                    else {
                        say $node->name," - STATE 2.1.2 lhs == rhs != node";
                        if ($hs_to_node->can_downcast_to) {
                            say $node->name," - STATE 2.1.2.2 hs can downcast node (hs->node: $hs_to_node)";
                            $node->set_type($node->lhs->type);
                            say $node->name," @@@ END 3 we have upcast-ed (hs->node: $hs_to_node) to ",$node->type;
                        }
                        elsif ($hs_to_node->can_upcast_to) {
                            say $node->name," - STATE 2.1.2.2 hs can upcast to node (hs->node: $hs_to_node)";
                            $node->lhs->set_type($node->type);
                            $node->rhs->set_type($node->type);
                            say $node->name," @@@ END 4 we can upcase lhs and rhs to node ($node_type)";
                        }
                        else {
                            say $node->name," ^^^ WTF!!!! this should never happen (hs->node: $hs_to_node)";
                        }
                    }
                }
                else {
                    say $node->name," - STATE 2.2 lhs != rhs are not the same (lhs->rhs: $lhs_to_rhs)";
                    say $node->name," @@@ END 5 do nothing, lhs is not equal to rhs, but the lhs & rhs & nodes are compatible";;
                }
            }

            say '===END=== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->type;
            say '===END=== ',$node->name,' =====================================';
        }
    }
}
