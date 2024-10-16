<!----------------------------------------------------------------------------->
# TODO
<!----------------------------------------------------------------------------->

- visit_op_boolean in the InferTypes
    - it needs to be written
    - but we need to think about types a bit first
        - how do coercions work?


- SymbolTable::Entry is B::PADNAME objects
    - COP_SEQ_RANGE_LOW
    - COP_SEQ_RANGE_HIGH
        Sequence numbers representing the scope
        within which a lexical is visible.
        Meaningless if PADNAMEt_OUTER is set.
    - use this with the `sequence_id` method of the B::MOP::Opcodes::COP opcodes



- Pretty print Perl code from the AST
    - make one that includes types as well

- Look into nextstate hints
    - https://metacpan.org/pod/B::Concise##hints
    - this tells me when strict is turned off
        - so I can prevent it during runtime

- Look into op FLAGS more
    - https://metacpan.org/pod/B::Concise#OP-flags-abbreviations
    - this tells me return context information


### Subroutine Signatures

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
