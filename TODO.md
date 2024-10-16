<!----------------------------------------------------------------------------->
# TODO
<!----------------------------------------------------------------------------->

- write a short tutorial on adding an op, then adding a node

- make a B::MOP::Type::Warning
    - set it whenever we downgrade something

- improve the has_common_superclass, it is kinda stupid
    - and poorly named

- create a visitor that will "normalize" the nodes
    - it would create "phantom" nodes (see below)
    - a good example is scalar declaration & definition
        - for plain delcaration it is fine
        - for `my $foo = 10` it is Local::Store
            - it should be `Op::Assign(Local::Declare, Const)`
            - or maybe `Local::Declare(Op::Assign(Local::Fetch, Const))`
            - or maybe something better
        - this also applies to multiconcat
            - add mutator varients with a target
    - point is to normalize the nodes a bit more
        - so that you dont need to know that multiconcat can handle
            - declaration of target
            - storing into a target
            - op-equals mutation of target
            - and probably more


<!----------------------------------------------------------------------------->

- SymbolTable::Entry is B::PADNAME objects
    - COP_SEQ_RANGE_LOW
    - COP_SEQ_RANGE_HIGH
        Sequence numbers representing the scope
        within which a lexical is visible.
        Meaningless if PADNAMEt_OUTER is set.
    - use this with the `sequence_id` method of the B::MOP::Opcodes::COP opcodes

- Look into nextstate hints
    - https://metacpan.org/pod/B::Concise##hints
    - this tells me when strict is turned off
        - so I can prevent it during runtime


<!----------------------------------------------------------------------------->
### Subroutine Signatures
<!----------------------------------------------------------------------------->

- Arity for Optionals, Slurpiness, etc.
    [x] arity check work for unused ($) parameters
    [-] arity check work for optional parameters
    [-] arity check with slurpiness

- Type Signature needs to handle ...
    - Optional parameters
    - Slurpiness


<!----------------------------------------------------------------------------->
## AST
<!----------------------------------------------------------------------------->

- to_JSON
    - clean this up more
    - add two modes (full and not full)

- add "phantom" nodes
    - for nodes that do not directly relate to actual code
        - argcheck/argelem statements are invisible to users
            - they are better thought of as an expression, not statement
    - we could also use this for nodes we would want to compile away
        - this is not something we do yet, but this would be a good way to handle it
    - should we represent the nodes that perl compiled away like this?
        - not sure we have all the info reminaing in order to do this

<!----------------------------------------------------------------------------->
## Notes:

`perl -I lib -MO=Concise,-main,-exec,-stash=Foo t/001-basic.pl`

<!----------------------------------------------------------------------------->
