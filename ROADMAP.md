<!----------------------------------------------------------------------------->
# ROADMAP
<!----------------------------------------------------------------------------->

This is a roadmap to an MVP that aims to prove the viability of this idea.

## Step 1. - Opcodes & AST

- Define & Implement a minimal set of opcodes
    - All Int,Float,Bool & String operations
    - All Array, Hash and Ref operations
    - Functions & Closures
    - Skip (for now)
        - OOP
        - Glob stuff
        - I/O & Unix stuff
    - edge case behavior can be punted
        - some stuff we want to deprecate
        - other stuff may need support

- Define & Implement the ASTs needed to model these opcodes
    - we probably need to make sure the AST captures all relevant opcode data
        - so that the opcodes do not need to be the starting point
            - enabling Guacamole ASTs, etc.

## Step 2. - Stabilization & Serialization

- Once we have a full set of Opcodes & AST Nodes
    - stabilize their structures
    - we need to be able to serialize/deserialize them
        - without loss of information & connections
            - this will include info about how to handle
                - breaking thing up appropriately (files, JSON nodes, etc)
                - reassembling them correctly (rebuilding connections, etc.)
        - this allows us to decouple things from `perl`
            - So tools can be written in other langauges
                - that operate on these structures

- Build tools to generate Opcodes from the AST
    - this is gives Guacamole, etc. a path
    - we already have the AST from the Opcodes

## Step 3. -

- We now have the following:
    - A spec for the Perl AST
    - A spec for the Perl Opcodes
    - All tools built should operate on the spec level only
        - the process is reversable
            - AST => Ops
            - Ops => AST
    - All that is missing is the runtime, so ...

- Build a "reference implementation" in Perl of `perl`
    - this should be both
        - a AST tree walking interpreter
        - a VM that consumes opcodes
    - the key thing is to figure out
        - the stack
        - the runloop
        - stash/pad storage
    - NOTE: this doesn't have to be in Perl
        - but it is the quickest approach

## Step 4. - Profit!

- ???
