
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

        $ast->accept(B::MOP::AST::Visitor->new( f => sub ($node) {
            if ($node isa B::MOP::AST::Local) {
                $node->set_pad_variable(
                    $self->pad_lookup(
                        $node->pad_index
                    )
                );
            }
        }));

        $ast->accept(B::MOP::AST::Visitor->new( f => sub ($node) {
            if ($node isa B::MOP::AST::Local::Store) {
                if ($node->has_type) {
                    # TODO: type check or upgrade/downgrade
                }
                else {
                    if (my $type = $node->rhs->get_type) {
                        $node->set_type($type);
                        $node->pad_variable->set_type($type);
                    }
                }
            }
            elsif ($node isa B::MOP::AST::Local::Fetch) {
                if (my $type = $node->pad_variable->get_type) {
                    $node->set_type($type);
                }
            }
        }));
    }

    method pad_variables { grep defined, @pad }

    method pad_lookup ($index) {
        return unless @pad;
        return $pad[ $index ];
    }
}
