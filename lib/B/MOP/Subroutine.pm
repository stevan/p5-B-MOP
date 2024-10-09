
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
        $ast->accept(B::MOP::AST::Visitor->new( f => sub ($node) {
            return unless $node isa B::MOP::AST::Expression;
            #say '----------------------------------------------';
            #say "$node has target at ", $node->pad_target_index;
            #say "$node has pad target? ", $node->has_pad_target ? "Y" : "N";
            return unless $node->has_pad_target;
            #say "$node has target? ", $node->has_pad_target ? "Y" : "N";
            return if $node->has_target;

            my $target = $self->pad_lookup( $node->pad_target_index );
            #say "NO TARGET FOR YOU!" unless $target;
            return unless $target;
            #say sprintf "Setting $node target %s for %s" => $target->name, $node->node_type;
            $node->set_target($target);
        }));

        $ast->accept(B::MOP::AST::Visitor->new( f => sub ($node) {
            return unless $node isa B::MOP::AST::Expression;
        }));
    }

    method pad_variables { grep defined, @pad }

    method pad_lookup ($index) {
        return unless @pad;
        return $pad[ $index ];
    }
}
