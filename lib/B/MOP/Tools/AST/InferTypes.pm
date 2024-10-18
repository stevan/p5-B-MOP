
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::InferTypes {
    use constant DEBUG => $ENV{DEBUG_TYPES} // 0;

    field $mop :param :reader;

    method visit ($node, @) {
        return unless $node isa B::MOP::AST::Node::Expression;
        $self->visit_local_store($node)     if $node isa B::MOP::AST::Node::Local::Store;
        $self->visit_local_fetch($node)     if $node isa B::MOP::AST::Node::Local::Fetch;
        $self->visit_op_numeric($node)      if $node isa B::MOP::AST::Node::BinOp::Numeric;
        $self->visit_call_subroutine($node) if $node isa B::MOP::AST::Node::Call::Subroutine;
        $self->visit_op_boolean($node)      if $node isa B::MOP::AST::Node::BinOp::Boolean;
        $self->visit_multiop_string($node)  if $node isa B::MOP::AST::Node::MultiOp::String;
        $self->visit_op_logical($node)      if $node isa B::MOP::AST::Node::BinOp::Logical;
        $self->visit_unop_numeric($node)    if $node isa B::MOP::AST::Node::UnOp::Numeric;
        $self->visit_op_assign($node)       if $node isa B::MOP::AST::Node::BinOp::Assign;
        $self->visit_builtin_scalar($node)  if $node isa B::MOP::AST::Node::Builtin::Scalar;
        $self->visit_reference($node)       if $node isa B::MOP::AST::Node::Reference;
        $self->visit_scalar_deref($node)    if $node isa B::MOP::AST::Node::Reference::Scalar::Dereference;
        return;
    }

    method visit_reference ($node) {
        $node->type->type->set_inner_type($node->operand->type->type);
    }

    method visit_scalar_deref ($node) {
        $node->set_type(
            B::MOP::Type::Variable->new( type => $node->operand->type->type->inner_type )
        );
    }

    method visit_builtin_scalar ($node) {
        my $operand_type = $node->operand->type;

        if ($operand_type->type isa B::MOP::Type::Scalar) {
            $node->set_type($operand_type);
        }
        else {
            # for Array's we will return an Int
            $node->set_type(B::MOP::Type::Variable->new( type => B::MOP::Type::Int->new ));
            # TODO:
            # I don't remember what Perl does for hashes,
            # but handle it here when needed
        }
    }

    method visit_call_subroutine ($node) {
        die "UNRESOLVED!" unless $node->is_resolved;

        if (DEBUG) {
            say '==INFER== ',$node->name,' =====================================';
            say "... subroutine = ",$node->subroutine->name;
            say '==BEGIN== ',$node->name,' =====================================';
        }

        my $call = $node->subroutine;
        my $sig  = $call->signature;
        my @args = $node->args->@*;

        # NOTE: arity was already checked in ResolveCalls

        # check args ...
        foreach my ($i, $param) (indexed $sig->parameters->@*) {
            my $arg = $args[$i];
            my $rel = $arg->type->relates_to($param->type);
            if ($rel->are_incompatible) {
                $arg->type->type_error(
                    B::MOP::Type::Error->new( node => $arg, rel => $rel));
            }
        }

        # ... all is well, set the return type to
        # the return type of the function
        $node->set_type($sig->return_type);

        if (DEBUG) {
            say '===END=== ',$node->name,' =====================================';
            say "... subroutine = ",$node->subroutine->name;
            say '===INFER=== ',$node->name,' =====================================';
        }
    }

    method visit_op_assign ($node) {
        my $lhs_type   = $node->lhs->type;
        my $rhs_type   = $node->rhs->type;
        my $lhs_to_rhs = $lhs_type->relates_to($rhs_type);

        # are the LHS and RHS comparable?
        if ($lhs_to_rhs->are_incompatible) {
            #say "they are incompatible";
            my $subclass = $lhs_to_rhs->has_common_superclass;
            #say "they have common subclass $subclass";
            my $new_type;
            if ($subclass) {
                $new_type = B::MOP::Type::Variable->new( type => $subclass->new );
            } else {
                $new_type = $node->rhs->type;
            }

            $node->lhs->set_type($new_type);
            $node->lhs->target->set_type($new_type) if $node->lhs->has_target;
            $node->set_type($new_type);

            # and set a type error
            $node->type->type_error(
                B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
        }
        else {
            # if they are the same, just use lhs
            if ($lhs_to_rhs->types_are_equal) {
                #say "they are equal";
                $node->set_type($node->lhs->type);
            }
            else {
                #say "they are not equal";
                if ($lhs_to_rhs->can_downcast_to) {
                    die "Can downcast to! FIXME";
                }
                elsif ($lhs_to_rhs->can_upcast_to) {
                    $node->lhs->set_type($node->rhs->type);
                    $node->lhs->target->set_type($node->rhs->type) if $node->lhs->has_target;
                    $node->set_type($node->lhs->type);
                }
                else {
                    # if no, there is a type error
                    $node->type->type_error(
                        B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
                }
            }
        }
    }

    method visit_local_store ($node) {
        my $node_type   = $node->type;
        my $rhs_type    = $node->rhs->type;
        my $target      = $node->target;
        my $target_type = $target->type;

        die "Node Type ($node_type) is not resolved" unless $node_type->is_resolved;
        die "RHS Type ($rhs_type) is not resolved" unless $rhs_type->is_resolved;

        my $rhs_to_node = $rhs_type->relates_to($node_type);

        if (DEBUG) {
            say '==INFER== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->rhs->name," : ",$node->rhs->type;
            say '==BEGIN== ',$node->name,' =====================================';
            say "[ rhs -> node ] = $rhs_to_node";
        }

        DEBUG && say "rhs->node: $rhs_to_node";
        if ($rhs_to_node->are_incompatible) {
            DEBUG && say "- Types are incompatible ($rhs_to_node)!!!!";
            $node->type->type_error(
                B::MOP::Type::Error->new( node => $node, rel => $rhs_to_node));
        }
        else {
            DEBUG && say "+ Types are compatible ($rhs_to_node)!!!!";
            $node->set_type($node->rhs->type);
            $node_type = $node->type;
        }

        my $node_to_target = $node_type->relates_to($target_type);
        DEBUG && say "node->target: $node_to_target";
        if ($node_to_target->are_incompatible) {
            DEBUG && say "- Types are incompatible ($node_to_target)!!!!";
            $node->type->type_error(
                B::MOP::Type::Error->new( node => $node, rel => $node_to_target));
            return;
        }
        else {
            DEBUG && say "+ Types are compatible ($node_to_target)!!!!";
            $target->set_type($node->type);
        }

        if (DEBUG) {
            say '===END=== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-rhs = ",$node->rhs->type;
            say '===INFER=== ',$node->name,' =====================================';
        }
    }

    method visit_local_fetch ($node) {
        my $node_type   = $node->type;
        my $target      = $node->target;
        my $target_type = $target->type;

        #say $node->name," - node: $node_type (- $target_type)";
        $node->set_type($node->target->type);
        #say $node->name," + node: $node_type (+ $target_type)";
    }

    method visit_multiop_string ($node) {
        if ($node->has_target) {
            $node->target->set_type($node->type);
        }
    }

    method visit_op_logical ($node) {
        my $lhs_type   = $node->lhs->type;
        my $rhs_type   = $node->rhs->type;
        my $lhs_to_rhs = $lhs_type->relates_to($rhs_type);

        # are the LHS and RHS comparable?
        if ($lhs_to_rhs->are_incompatible) {
            #say "they are incompatible";
            my $subclass = $lhs_to_rhs->has_common_superclass;
            #say "they have common subclass $subclass";
            if ($subclass) {
                $node->set_type(B::MOP::Type::Variable->new( type => $subclass->new ));
            }
            else {
                # if no, there is a type error
                $node->type->type_error(
                    B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
            }
        }
        else {
            # if they are the same, just use lhs
            if ($lhs_to_rhs->types_are_equal) {
                #say "they are equal";
                $node->set_type($node->lhs->type);
            }
            else {
                #say "they are not equal";
                my $subclass = $lhs_to_rhs->has_common_superclass;
                #say "they have common subclass ".($subclass//'~');

                if ($subclass) {
                    $node->set_type(B::MOP::Type::Variable->new( type => $subclass->new ));
                }
                else {
                    # if no, there is a type error
                    $node->type->type_error(
                        B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
                }
            }
        }
    }

    method visit_unop_numeric ($node) {
        my $node_type    = $node->type;
        my $operand_type = $node->operand->type;
        my $op_to_node   = $operand_type->relates_to($node_type);

        #say "op_to_node: $op_to_node";

        # are the operand and underlying target comparable?
        if ($op_to_node->are_incompatible) {
            #say "they are incompatible";
            my $subclass = $op_to_node->has_common_superclass;
            #say "they have common subclass $subclass";
            if (!$subclass || $subclass eq 'B::MOP::Type::Scalar') {
                # if no, there is a type error
                $node->type->type_error(
                    B::MOP::Type::Error->new( node => $node, rel => $op_to_node));
            }
        }
        else {
            # if they are the same, just use lhs
            if (!$op_to_node->types_are_equal) {
                #say "they are not equal";
                if ($op_to_node->can_downcast_to) {
                    #say "node can be upcasted to target";
                    $node->set_type($node->operand->type);
                } else {
                    # if no, there is a type error
                    $node->type->type_error(
                        B::MOP::Type::Error->new( node => $node, rel => $op_to_node));
                }
            }
        }

    }

    method visit_op_boolean ($node) {
        my $lhs_type   = $node->lhs->type;
        my $rhs_type   = $node->rhs->type;
        my $lhs_to_rhs = $lhs_type->relates_to($rhs_type);

        # are the LHS and RHS comparable?
        if ($lhs_to_rhs->are_incompatible) {
            #say "they are incompatible";
            my $subclass = $lhs_to_rhs->has_common_superclass;
            #say "they have common subclass $subclass";
            if (!$subclass || $subclass eq 'B::MOP::Type::Scalar') {
                # if no, there is a type error
                $node->type->type_error(
                    B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
            }
        }
        else {
            # if they are the same, just use lhs
            if (!$lhs_to_rhs->types_are_equal) {
                #say "they are not equal";
                my $subclass = $lhs_to_rhs->has_common_superclass;
                #say "they have common subclass ".($subclass//'~');

                if (!$subclass || $subclass eq 'B::MOP::Type::Scalar') {
                    # if no, there is a type error
                    $node->type->type_error(
                        B::MOP::Type::Error->new( node => $node, rel => $lhs_to_rhs));
                }
            }
        }

        # otherwise, it should be fine, cause the node is already a Bool
    }

    method visit_op_numeric ($node) {
        my $node_type = $node->type;
        my $lhs_type  = $node->lhs->type;
        my $rhs_type  = $node->rhs->type;

        my $lhs_to_node = $lhs_type->relates_to($node_type);
        my $lhs_to_rhs  = $lhs_type->relates_to($rhs_type);
        my $rhs_to_node = $rhs_type->relates_to($node_type);

        if (DEBUG) {
            say '==INFER== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-lhs = ",$node->lhs->name," : ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->name," : ",$node->rhs->type;
            say '==BEGIN== ',$node->name,' =====================================';

            say "[ lhs ->  rhs ] = $lhs_to_rhs";
            say "[ lhs -> node ] = $lhs_to_node";
            say "[ rhs -> node ] = $rhs_to_node";
        }

        if ($lhs_to_node->are_incompatible) {
            $node->type->type_error(
                B::MOP::Type::Error->new( node => $node, rel => $lhs_to_node));
            DEBUG && say $node->name," ! TEST 1 FAILED lhs is compat with node (lhs->node: $lhs_to_node)";
            return;
        }
        else {
            DEBUG && say $node->name," ? TEST 1 lhs is compat with node (lhs->node: $lhs_to_node)";
        }

        if ($rhs_to_node->are_incompatible) {
            $node->type->type_error(
                B::MOP::Type::Error->new( node => $node, rel => $rhs_to_node));
            DEBUG && say $node->name," ! TEST 2 FAILED rhs is compat with node (rhs->node: $rhs_to_node)";
            return;
        }
        else {
            DEBUG && say $node->name," ? TEST 2 rhs is compat with node (rhs->node: $rhs_to_node)";
        }

        DEBUG && say $node->name," ! The operands are compatible with the nodes required type";

        if ($lhs_to_rhs->are_incompatible) {
            DEBUG && say $node->name," - STATE 1 lhs and rhs are not compat (lhs->rhs: $lhs_to_rhs)";
            DEBUG && say $node->name," @@@ END 1 do nothing, the nodes are not compatible, but are within the node type";
        }
        else {
            DEBUG && say $node->name," - STATE 2 lhs and rhs are compat (lhs->rhs: $lhs_to_rhs)";
            if ($lhs_to_rhs->types_are_equal) {
                DEBUG && say $node->name," - STATE 2.1 lhs == rhs are the same (lhs->rhs: $lhs_to_rhs)";

                my $hs_to_node = $lhs_to_node;
                if ($hs_to_node->types_are_equal) {
                    DEBUG && say $node->name," - STATE 2.1.1 lhs == rhs == node";
                    DEBUG && say $node->name," @@@ END 2 do nothing, the nodes are all the same type ";
                }
                else {
                    DEBUG && say $node->name," - STATE 2.1.2 lhs == rhs != node";
                    if ($hs_to_node->can_downcast_to) {
                        DEBUG && say $node->name," - STATE 2.1.2.2 hs can downcast node (hs->node: $hs_to_node)";
                        $node->set_type($node->lhs->type);
                        DEBUG && say $node->name," @@@ END 3 we have upcast-ed (hs->node: $hs_to_node) to ",$node->type;
                    }
                    elsif ($hs_to_node->can_upcast_to) {
                        DEBUG && say $node->name," - STATE 2.1.2.2 hs can upcast to node (hs->node: $hs_to_node)";
                        $node->lhs->set_type($node->type);
                        $node->lhs->target->set_type($node->type) if $node->lhs->has_target;
                        $node->rhs->set_type($node->type);
                        $node->rhs->target->set_type($node->type) if $node->rhs->has_target;
                        DEBUG && say $node->name," @@@ END 4 we can upcase lhs and rhs to node ($node_type)";
                    }
                    else {
                        DEBUG && say $node->name," ^^^ WTF!!!! this should never happen (hs->node: $hs_to_node)";
                    }
                }
            }
            else {
                DEBUG && say $node->name," - STATE 2.2 lhs != rhs are not the same (lhs->rhs: $lhs_to_rhs)";

                if ($lhs_to_rhs->can_downcast_to) {
                    DEBUG && say $node->name," - STATE 2.2.1 lhs can downcast to rhs (lhs->rhs: $lhs_to_rhs)";
                    DEBUG && say $node->name," @@@ END 5 upcase the rhs";
                    $node->rhs->set_type($node->type);
                    $node->rhs->target->set_type($node->type) if $node->rhs->has_target;
                }
                elsif ($lhs_to_rhs->can_upcast_to) {
                    DEBUG && say $node->name," - STATE 2.2.2 lhs can upcase to rhs (lhs->rhs: $lhs_to_rhs)";
                    DEBUG && say $node->name," @@@ END 6 upcase the lhs";
                    $node->lhs->set_type($node->type);
                    $node->lhs->target->set_type($node->type) if $node->lhs->has_target;
                }
                else {
                    DEBUG && say $node->name," ^^^ WTF!!!! this should never happen (lhs->rhs: $lhs_to_rhs)";
                }
            }
        }

        if (DEBUG) {
            say '===END=== ',$node->name,' =====================================';
            say "... node     = ",$node->type;
            say "... node-lhs = ",$node->lhs->type;
            say "... node-rhs = ",$node->rhs->type;
            say '===INFER=== ',$node->name,' =====================================';
        }
    }
}

