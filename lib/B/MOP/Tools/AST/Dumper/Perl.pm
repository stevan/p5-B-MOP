
use v5.40;
use experimental qw[ class ];

class B::MOP::Tools::AST::Dumper::Perl {
    use constant DEBUG => $ENV{DEBUG_DUMPER} // 0;

    field $subroutine :param :reader;
    field $indent     :param :reader = '    ';

    method dump { $subroutine->ast->accept($self) }

    method visit ($node, @acc) {
        return $self->visit_subroutine($node, @acc)                  if $node isa B::MOP::AST::Node::Subroutine;
        return $self->visit_block($node, @acc)                       if $node isa B::MOP::AST::Node::Block;
        return $self->visit_statement($node, @acc)                   if $node isa B::MOP::AST::Node::Statement;

        return $self->visit_const($node, @acc)                       if $node isa B::MOP::AST::Node::Const;

        #return $self->visit_argument_element($node, @acc)            if $node isa B::MOP::AST::Node::Argument::Element;

        return $self->visit_call($node, @acc)                        if $node isa B::MOP::AST::Node::Call;

        return $self->visit_local_declare($node, @acc)               if $node isa B::MOP::AST::Node::Local::Declare;
        return $self->visit_local_declare_andstore($node, @acc)      if $node isa B::MOP::AST::Node::Local::Declare::AndStore;
        return $self->visit_local_store($node, @acc)                 if $node isa B::MOP::AST::Node::Local::Store;
        return $self->visit_local_fetch($node, @acc)                 if $node isa B::MOP::AST::Node::Local::Fetch;

        return $self->visit_binop_assign_subtract($node, @acc)       if $node isa B::MOP::AST::Node::BinOp::Assign::Subtract;
        return $self->visit_binop_assign_add($node, @acc)            if $node isa B::MOP::AST::Node::BinOp::Assign::Add;
        return $self->visit_binop_assign_multiply($node, @acc)       if $node isa B::MOP::AST::Node::BinOp::Assign::Multiply;

        return $self->visit_binop_multiply($node, @acc)              if $node isa B::MOP::AST::Node::BinOp::Multiply;
        return $self->visit_binop_add($node, @acc)                   if $node isa B::MOP::AST::Node::BinOp::Add;
        return $self->visit_binop_subtract($node, @acc)              if $node isa B::MOP::AST::Node::BinOp::Subtract;
        return;
    }

    method visit_subroutine ($node, @acc) {
        sprintf 'sub %s (%s) %s' =>
            $subroutine->name,
            (join ', ' => map $_->name, $subroutine->signature->parameters->@*),
            @acc;
    }

    method visit_block ($node, @acc) {
        join "\n" => '{', (map "${indent}${_}", @acc), '}'
    }

    method visit_statement ($node, @acc) {
        return unless @acc;
        join '' => @acc, ';'
    }

    method visit_const ($node, @acc) { $node->get_literal }

    #method visit_argument_element ($node, @) { $node->target->name }

    method visit_call ($node, @acc) {
        sprintf '%s(%s)', $node->subroutine->name, join ', ' => @acc
    }

    method visit_local_declare          ($node, @acc) { sprintf 'my %s', $node->target->name }
    method visit_local_declare_andstore ($node, @acc) {
        sprintf 'my %s = %s', $node->target->name, @acc
    }

    method visit_local_store ($node, @acc) { sprintf '%s = %s', $node->target->name, @acc }
    method visit_local_fetch ($node, @)     { $node->target->name }

    method visit_binop_assign_subtract ($node, @acc) { sprintf '%s -= %s' => @acc }
    method visit_binop_assign_add      ($node, @acc) { sprintf '%s += %s' => @acc }
    method visit_binop_assign_multiply ($node, @acc) { sprintf '%s *= %s' => @acc }

    method visit_binop_multiply ($node, @acc) { sprintf '%s * %s' => @acc }
    method visit_binop_add      ($node, @acc) { sprintf '%s + %s' => @acc }
    method visit_binop_subtract ($node, @acc) { sprintf '%s - %s' => @acc }

}

__END__

# gets the node package hierarchy
perl  -MB::MOP::AST -I lib -E 'no strict 'refs'; sub r ($n) { foreach (keys %{$n}) { if (/\:\:$/) { say $n->{$_}; r( $n->{$_} ) } } }; r(*{"B::MOP::AST::Node::"});'

