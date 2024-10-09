
use v5.40;
use experimental qw[ class ];

use B ();
use B::MOP::AST;
use B::MOP::Opcode;
use B::MOP::Variable;

class B::MOP::Subroutine {
    field $name :param :reader;
    field $body :param :reader;

    field $cv  :reader;
    field @ops :reader;
    field $ast :reader;
    field @pad;

    ADJUST {
        $cv = B::svref_2object($body);

        # wrap the ops ...

        my $next = $cv->START;
        until ($next isa B::NULL) {
            push @ops => B::MOP::Opcode->get( $next );
            $next = $next->next;
        }

        # collect the pad ...

        if (!(($cv->PADLIST->ARRAY)[0] isa B::NULL)) {
            foreach my ($i, $entry) (indexed(($cv->PADLIST->ARRAY)[0]->ARRAY)) {
                next if $entry->IsUndef                 # skip undef stuff ...
                     || $entry->PVX =~ /Object\:\:Pad/; # skip Object::Pad hack
                $pad[$i] = B::MOP::Variable->new( entry => $entry );
            }
        }

        # build the AST ...

        $ast = B::MOP::AST->new->build_subroutine( @ops );

        # connect all the ops with pad targets to those variables
        $ast->accept(B::MOP::AST::Visitor->new(
            accept => 'B::MOP::AST::Expression', f => sub ($node) {
                return unless $node->has_pad_target;
                return if $node->has_target;
                my $target = $self->pad_lookup( $node->pad_target_index );
                $node->set_target($target);
            }
        ));

        $ast->accept(B::MOP::AST::Visitor->new(
            accept => 'B::MOP::AST::Expression', f => sub ($node) {
                if ($node isa 'B::MOP::AST::Local::Store') {

                    my $node_type   = $node->get_type;
                    my $target_type = $node->rhs->get_type;

                    if (my $new_type = $node_type->cast($target_type)) {
                        $node->set_type($new_type);

                        if ($node->has_pad_target) {
                            my $pad_target = $node->get_target;
                            my $pad_type   = $pad_target->get_type;
                            if (my $new_pad_type = $pad_type->cast($new_type)) {
                                $pad_target->set_type( $new_pad_type );
                            }
                            else {
                                die "TYPE ERROR: Cannot cast pad(".$pad_target->name.")[$pad_type] to $new_type"
                                    unless $pad_type->is_same_type($new_type);
                            }
                        }
                    }
                    else {
                        die "TYPE ERROR: Cannot cast $node_type to $target_type"
                            unless $node_type->is_same_type($target_type);
                    }
                }
                elsif ($node isa 'B::MOP::AST::Local::Fetch') {
                    my $node_type = $node->get_type;

                    if ($node->has_pad_target) {
                        my $pad_target = $node->get_target;
                        my $pad_type   = $pad_target->get_type;
                        if (my $new_type = $node_type->cast($pad_type)) {
                            $node->set_type($new_type);
                        }
                        else {
                            die "TYPE ERROR: Cannot cast $node_type to $pad_type"
                                unless $node_type->is_same_type($pad_type);
                        }
                    }
                }
                elsif ($node isa 'B::MOP::AST::Op::Numeric') {
                    my $node_type = $node->get_type;
                    my $lhs_type  = $node->lhs->get_type;
                    my $rhs_type  = $node->rhs->get_type;

                    say ">> node($node_type) lhs($lhs_type) rhs($rhs_type)";

                    if ($lhs_type->is_same_type($rhs_type)) {
                        say ">> lhs($lhs_type) == rhs($rhs_type)";
                        if (my $new_type = $node_type->cast($lhs_type)) {
                            say ">> new($new_type) for $node";
                            $node->set_type($new_type);
                        }
                        else {
                            say ">> could not cast $node_type to lhs($lhs_type) for $node";
                        }
                    }
                    else {
                        say ">> lhs($lhs_type) != rhs($rhs_type)";
                    }
                }
            }
        ));

    }

    method pad_variables { grep defined, @pad }

    method pad_lookup ($index) {
        return unless @pad;
        return $pad[ $index ];
    }
}
