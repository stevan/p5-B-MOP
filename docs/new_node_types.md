<!----------------------------------------------------------------------------->
# Creating New AST Nodes
<!----------------------------------------------------------------------------->

## Setup a new test file

- copy a test file
    - remove all `check_*` calls
        - so that it just fetches the subroutine and dumps the AST
    - change the body of Foo::test
        - it should be the simplest example possible
            - see other tests for what I mean
- run the test, with DEBUG=1
    - `DEBUG=1 perl -I lib t/000-my-test.t`
    - it will likely error, so take a look at the opcode tree
        - `DEBUG=1 perl -MO-Concise,-stash=Foo -I lib t/000-my-test.t`
        - scroll up to the top to see the contents of Foo::test

## Creating the new Opcodes

- open up B::MOP::Opcode
    - look at what other code does and copy it
    - the error from running the test should tell you what to do
        - `Failed to get op(B::MOP::Opcode::SEQ) for B::BINOP=SCALAR(0x14c5daf38)`
        - this tells you to add a `B::MOP::Opcode::SEQ` class
            - and it should inherit from `B::MOP::Opcode::BINOP`

- keep running the test and creating new ops
    - when this is done you will get a new error
        - now it is time to create the AST nodes

## Creating new AST nodes

- this takes some thinking, but mostly aligns with the Opcode
    - again, look at what other code does, and copy it

- the error now will say something like this:

```
!! Cannot find AST node for: B::MOP::Opcode::SEQ=OBJECT(0x15bd4b410)
   op[BINOP](5519819856) : seq = string eq
       `--> next: op[UNOP](5519819792) : padsv_store = padsv scalar assignment
```

- The nodes all go into `B::MOP::AST::Node` namespace, and inherit from that class
    - several classes are often stored in a single .pm file
        - so if you don't see something specific, find the next best thing
            - or poke into you see something similar to what you are doing

- In this example, we have a BinOp for boolean string comparisons.
    - the simplest thing was to create a new sub-namespace for string Boolean BinOps
        - `B::MOP::AST::Node::BinOp::String::`
            - and copy the other `B::MOP::AST::Node::BinOp::` subclasses for this
                - ex: `B::MOP::AST::Node::BinOp::LessThan`
                    - becomes`B::MOP::AST::Node::BinOp::String::LessThan`

- now open up `B::MOP::AST`
    - find a spot inside `build_expression` to add an `elsif` for the new ops
        - again, look around, is there something similar?
            - copy it


