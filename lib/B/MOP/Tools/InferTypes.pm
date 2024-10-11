
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::TypeError {
    use overload '""' => 'to_string';

    field $node :param :reader;
    field $rel  :param :reader;

    method to_string {
        join "\n  ",
            "TYPE ERROR : $rel",
                "in ".$node->name." = {",
                "    node_type = ".$node->type,
                ($node->can('lhs') ? "    lhs_type  = ".$node->lhs->type    : ()),
                ($node->can('rhs') ? "    rhs_type  = ".$node->rhs->type    : ()),
                ($node->has_target ? "    target    = ".$node->target->type : ()),
                "}\n";
    }
}

class B::MOP::Tools::InferTypes {
    field $env :param :reader;

    method visit ($node) {
        return unless $node isa B::MOP::AST::Expression;

        if ($node isa B::MOP::AST::Local::Store) {
            my $node_type   = $node->type;
            my $rhs_type    = $node->rhs->type;
            my $target      = $node->target;
            my $target_type = $target->type;

            my $rhs_to_node = $rhs_type->relates_to($node_type);

            say '==BEGIN== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->rhs->name," : ",$node->rhs->type;
            say '==BEGIN== ',$node->name,' =====================================';
            say "[ rhs -> node ] = $rhs_to_node";

            say "rhs->node: $rhs_to_node";
            if ($rhs_to_node->are_incompatible) {
                say "- Types are incompatible ($rhs_to_node)!!!!";
                $node->type->type_error(B::MOP::Tools::TypeError->new( node => $node, rel => $rhs_to_node));
            }
            else {
                say "+ Types are compatible ($rhs_to_node)!!!!";
                $node->set_type($node->rhs->type);
                $node_type = $node->type;
            }

            my $node_to_target = $node_type->relates_to($target_type);
            say "node->target: $node_to_target";
            if ($node_to_target->are_incompatible) {
                say "- Types are incompatible ($node_to_target)!!!!";
                $node->type->type_error(B::MOP::Tools::TypeError->new( node => $node, rel => $node_to_target));
                return;
            }
            else {
                say "+ Types are compatible ($node_to_target)!!!!";
                $target->set_type($node->type);
            }

            say '===END=== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->rhs->type;
            say '===END=== ',$node->name,' =====================================';

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

            my $lhs_to_node = $lhs_type->relates_to($node_type);
            my $lhs_to_rhs  = $lhs_type->relates_to($rhs_type);
            my $rhs_to_node = $rhs_type->relates_to($node_type);

            say '==BEGIN== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-lhs = ",$node->lhs->name," : ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->name," : ",$node->rhs->type;
            say '==BEGIN== ',$node->name,' =====================================';

            say "[ lhs ->  rhs ] = $lhs_to_rhs";
            say "[ lhs -> node ] = $lhs_to_node";
            say "[ rhs -> node ] = $rhs_to_node";

            if ($lhs_to_node->are_incompatible) {
                $node->type->type_error(B::MOP::Tools::TypeError->new( node => $node, rel => $lhs_to_node));
                say $node->name," ! TEST 1 FAILED lhs is compat with node (lhs->node: $lhs_to_node)";
                return;
            }
            else {
                say $node->name," ? TEST 1 lhs is compat with node (lhs->node: $lhs_to_node)";
            }

            if ($rhs_to_node->are_incompatible) {
                $node->type->type_error(B::MOP::Tools::TypeError->new( node => $node, rel => $rhs_to_node));
                say $node->name," ! TEST 2 FAILED rhs is compat with node (rhs->node: $rhs_to_node)";
                return;
            }
            else {
                say $node->name," ? TEST 2 rhs is compat with node (rhs->node: $rhs_to_node)";
            }

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
                            $node->lhs->target->set_type($node->type) if $node->lhs->has_target;
                            $node->rhs->set_type($node->type);
                            $node->rhs->target->set_type($node->type) if $node->rhs->has_target;
                            say $node->name," @@@ END 4 we can upcase lhs and rhs to node ($node_type)";
                        }
                        else {
                            say $node->name," ^^^ WTF!!!! this should never happen (hs->node: $hs_to_node)";
                        }
                    }
                }
                else {
                    say $node->name," - STATE 2.2 lhs != rhs are not the same (lhs->rhs: $lhs_to_rhs)";

                    if ($lhs_to_rhs->can_downcast_to) {
                        say $node->name," - STATE 2.2.1 lhs can downcast to rhs (lhs->rhs: $lhs_to_rhs)";
                        say $node->name," ### END 5 ????";
                    }
                    elsif ($lhs_to_rhs->can_upcast_to) {
                        say $node->name," - STATE 2.2.2 lhs can upcase to rhs (lhs->rhs: $lhs_to_rhs)";
                        say $node->name," ### END 6 ????";
                    }
                    else {
                        say $node->name," ^^^ WTF!!!! this should never happen (lhs->rhs: $lhs_to_rhs)";
                    }
                }
            }

            say '===END=== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-lhs = ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->type;
            say '===END=== ',$node->name,' =====================================';
        }
    }
}
