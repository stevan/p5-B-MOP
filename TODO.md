<!----------------------------------------------------------------------------->
# TODO
<!----------------------------------------------------------------------------->

- Handle the various private flags from opcode.h
    - CONST opcode needs some work

<!----------------------------------------------------------------------------->
## Type System
<!----------------------------------------------------------------------------->

- make a B::MOP::Type::Warning
    - set it whenever we downgrade something

- improve the has_common_superclass, it is kinda stupid
    - and poorly named

- should the BinOps have a Signature object?
    - for most cases we know the type boundaries
        - since Perl makes a distinction between string and numeric ops
    - but still this might be an improvement?

- how should we handle `my Int $x` ??
    - `Int` is stored as STASH for the SV
    - but `Int` has to exist (meaning we have to create it)

### How should arrays work?

- track all additions to the array and infer type
    - downgrade/upgrade type with each addition so that all fit

### How should references work?

- do we need parameterized types for this??

<!----------------------------------------------------------------------------->
## Subroutine Signatures
<!----------------------------------------------------------------------------->

- Arity for Optionals, Slurpiness, etc.
    [x] arity check work for unused ($) parameters
    [-] arity check work for optional parameters
    [-] arity check with slurpiness

- Type Signature needs to handle ...
    [-] args other than scalars
    [-] Optional parameters (with defaults)
    [-] Slurpiness

<!----------------------------------------------------------------------------->
## AST
<!----------------------------------------------------------------------------->

- add "phantom" nodes
    - for nodes that do not directly relate to actual code
        - argcheck/argelem statements are invisible to users
            - they are better thought of as an expression, not statement
    - we could also use this for nodes we would want to compile away
        - this is not something we do yet, but this would be a good way to handle it
    - should we represent the nodes that perl compiled away like this?
        - not sure we have all the info reminaing in order to do this

### AST Visitors

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


- create a visitor that selectively copies the AST tree
    - basically a general purpose transformer
        - if the node is matched
            - transform it
            - otherwise copy it
        - attach any child nodes to new copy
            - return copy

<!----------------------------------------------------------------------------->
## Logging
<!----------------------------------------------------------------------------->

[-] add CHECK_TYPES env var which is on by default
    - you can turn it off in shell
    - and it will also disable tests to avoid noisy (expected) failures

[-] fix the DEBUG_AST which dumps opcodes
[-] fix the DEBUG in the tests to be DEBUG_TEST
    - maybe add wrapper functions to catch exceptions
        - so if the types blew up we can still dump the unresolved AST

[-] add a proper Logging module
    - copy the stuff from Yakt/Acktor/ELO for this
    - basically one with multiple levels (INFO,WARN,ERROR,DEBUG)
        - and colors
        - and automatic formatting


<!----------------------------------------------------------------------------->
## Misc Ideas
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
        - so I can prevent it during runtime??


<!----------------------------------------------------------------------------->
## Notes:

`perl -I lib -MO=Concise,-main,-exec,-stash=Foo t/001-basic.pl`

<!----------------------------------------------------------------------------->
