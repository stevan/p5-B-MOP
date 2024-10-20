<!----------------------------------------------------------------------------->
# ROADMAP
<!----------------------------------------------------------------------------->

This is a roadmap to an MVP that aims to prove the viability of this idea.

## Step 1. - Opcodes & AST

- Define a minimal set of opcodes
    - All Int,Float,Bool & String operations
    - All Array, Hash and Ref operations
    - Functions & Closures
    - Skip (for now)
        - OOP
        - Glob stuff
        - I/O & Unix stuff

- Implement that minimal set of opcodes
    - edge case behavior can be punted
        - some stuff we want to deprecate
        - other stuff may need support

- Implement the ASTs needed to model these opcodes

## Step 2. - Serialization

- Once we have a full set of Opcodes & AST Nodes
    - stabilize their structures
    - we need to be able to serialize/deserialize them
        - without loss of information & connections
        - this allows us to decouple things from `perl`
            - So tools can operate in a manner isolated from other phases/stages

## Step 3. - ???

## Step 4. - Profit!
