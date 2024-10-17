<!----------------------------------------------------------------------------->
# B::MOP
<!----------------------------------------------------------------------------->
## A compile time MOP (Meta Object Protocol) for Perl
<!----------------------------------------------------------------------------->

This is a crazy experiment to statically "parse" Perl code using the `perl`
opcode tree as input (instead of the source text). The goal is to construct
a compile time MOP (Meta Object Protocol) that can introspect packages, the
subroutines within them, and the code contained within those subroutines.

This is in contrast to runtime MOPs like those provided by `Moose`, etc. In
which introspection is limited to the package/subroutine level and there is
no visibility into the code inside the subroutines.

> _TL;DR_ : You can jump to the *Example* section below if you are impatient
> and want to see some code and output. But please come back :)

### Why??

This module is used to statically analyze the parts of a Perl program
and do the following things at *compile* time.

- Build dependecy graphs down to the subroutine call level
    - most tools can only do this to the package level
- Check arity of subroutine calls
    - even with signatures, Perl only checks this at runtime
- Identify and track mutation points
    - we can track any AST node which modifies a variable

Using this information and some assumptions, we can then infer the type
usage and ultimately type check the Perl program (with some caveats).

### Huh??

Perl is a very dynamic language which contains severel features which make
it impossible to statically parse source text and build a representation
of what `perl` would construct. There are two key features which cause
the most trouble, and those are:

1. String `eval` creates new opcodes at runtime
    - this is bad because we need to know all opcodes at compile time
2. Symbol table manipulation at runtime
    - this is bad because we need this to be fixed at compile time

In order to statically understand Perl, we need to be able to "freeze"
the state of a Perl program, which means the set of opcodes and the
symbol table can not be changed during the running of the program.

In the majority of programs, prohibiting these features would not be
an issue as these features are not often used at runtime. However,
they are often used during the `BEGIN` phase of the `perl` compiler.
Specifically for things like importing subroutines, generating classes
and packages, etc.

This module aims to strike a sensible balance.

First by allowing string `eval` and symbol table manipulation to be done
at `BEGIN` time only. This lets us take advantage of Perl's metaprogramming
capabilities during the compile phase of `perl` to construct code, generate
packages, create constants, set globals, etc.

Once the `BEGIN` and `CHECK` phases have completed, this module can be used
to build a static picture of the Perl program. If the static code includes
string `eval` or symbol table manipulation (`no strict 'refs'`, etc.) then
an error will be thrown (TODO).

The truth is, you can use this module whenever you like (after `CHECK`) so
it is possible to execute runtime code to do all the "bad" stuff described
above, and once that is done, use `B::MOP` to load the results of all that.

#### Notes & Caveats

So the type system will never be on the level of languages like `Haskell`
of `OCaml`. It will likely fall somewhere around `Java`, `TypeScript` and
`C` but with caveats because it is `Perl`.

The type inferrence system makes a *lot* of assumptions and tries to find the
most derived/specific type possible. In some cases this ends up being the
base `Scalar` class which is equivalent to an `Any` type. It is Perl after
all, so what did you expect?

There are more bad features which will also need detection and prohibition,
such as (but not limited to):

- Method calls with a method variable (ex: `$object->$method()`)
    - We cannot know the value of `$method` at compile time
- Class method calls with a class variable (ex: `$class->new`)
    - We cannot know the value of `$class` at compile time
- Any use of `AUTOLOAD`
    - it's just a mess, nuff said!

Dealing with `END` blocks might also be tricky, though in theory we can
freeze them as well.

### Status

This project has basically just moved from the "hmm, can this even be done"
stage to the "lets see how far we can take this proof of concept" stage. So to
say it is still early would be an understatement. It is still quite possible
we will hit something insurmountable, but so far so good.

Currently this only works with Perl 5.40 and the intention is only ever support
the most current version of Perl. If at some point we reach a level of stability
then we can think about back-compat, but at this stage, we are ignoring it
completely and only looking ahead.

#### Opcode Status

Perl has 398 opcodes, some of which are highly specific to things like shell,
networking, I/O, etc. These are not so much parts of the language, as they are
access to features provided via the runtime. So if we (for now) remove these
we end up with aroudn 350 opcodes that need to be handled and transformed into
AST nodes.

Currently we are handling around 33 of the 350 opcodes. Some of them have
unexplored corner cases, but the core behavior is covered.

### Dependencies

Perl 5.40 is currently the only supported version, and it has only been tested
on an M2 Mac.

> _NOTE_ : It is possible that Perl will behave differently on other platforms,
> please let us know if that happens.

Currently we only depends on core Perl modules.

- `overload`
- `constant`
- `mro`
- `B`

With some other modules, mostly for testing and debugging support.

- `Test::More`
- `JSON::XS`

It also depends on some experimental features, such as:

- `class` - the new Perl OOP syntax
- `builtin` - specifically the experimental `export_lexically` builtin

### Example

Given the following Perl code.

```perl
package Foo {
    sub test {
        my $x;
        $x = 10;
        my $y = 100 + $x;
    }
}
```

First load the `Foo` package into `B::MOP`, which will inspect the package and
load any subroutines it finds.

```perl
my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;
```

Next is to finalize the MOP, this is a multi-phase process which does the
followings steps:

1. Builds a dependency graph between packages and subroutines
    - detects all callsites and connects them to the subroutines calling them
    - checks for cross package calls and notes dependency
2. Resolve all subroutine calls
    - this will check arity between caller and callee at this time
    - connect all callsites with sub being called
        - using the dependency information from the previous step
3. Check the type usage
    - this will attempt to infer the correct types for all expressions and pad variables
        - types are propogates during call-by-value/pass-by-value (mostly scalars)
        - operations are type checked based on their expected arg/return types
        - in certain situations types are up/down-cast as needed
    - if a type error occurs
        - it is noted in the tree and we continue inferring
            - if we hit something unrecoverable, we throw an error
    - and finally types are propogate up the AST tree to ..
        - the statement nodes
        - the blocks (basically takes the last statements type)
        - and finally subroutine where we also generate a signature for it

From here you can see this by dumping the AST, which gives you this.

```perl
my $test = $Foo->get_subroutine('test');
say json_encode($test->to_JSON);
```

Note that types are all stored inside a unique Type::Variable (ex: `a:3`) and the type keeps track of it's changes. So `a:2(*Int[:> *Scalar])` is a the type variable, and the type started out as a `*Scalar` but was downcast (`:>`) into an `*Int`.

```json
{
    "%env": {
        "__class__": "B::MOP::AST::SymbolTable",
        "@entries": [
            {
                "__class__": "B::MOP::AST::SymbolTable::Entry",
                "location": "LOCAL",
                "name": "$x",
                "type": "`a:2(*Int[:> *Scalar])"
            },
            {
                "__class__": "B::MOP::AST::SymbolTable::Entry",
                "location": "LOCAL",
                "name": "$y",
                "type": "`a:3(*Int[:> *Scalar])"
            }
        ]
    },
    "@ast": {
        "node": "Subroutine[12]",
        "stash": "Foo",
        "name": "test",
        "type": "`a:16(*Int[:> *Scalar])",
        "block": {
            "node": "Block[11]",
            "type": "`a:15(*Int[:> *Scalar])",
            "statements": [
                {
                    "node": "Statement[2]",
                    "type": "`a:6(*Scalar)",
                    "expression": {
                        "node": "Local::Declare[1]",
                        "type": "`a:5(*Scalar)",
                        "$target": {
                            "__class__": "B::MOP::AST::SymbolTable::Entry",
                            "location": "LOCAL",
                            "name": "$x",
                            "type": "`a:2(*Int[:> *Scalar])"
                        }
                    }
                },
                {
                    "node": "Statement[5]",
                    "type": "`a:9(*Int[:> *Scalar])",
                    "expression": {
                        "node": "Local::Store[4]",
                        "type": "`a:8(*Int[:> *Scalar])",
                        "$target": {
                            "__class__": "B::MOP::AST::SymbolTable::Entry",
                            "location": "LOCAL",
                            "name": "$x",
                            "type": "`a:2(*Int[:> *Scalar])"
                        },
                        "rhs": {
                            "node": "Const[3]",
                            "type": "`a:7(*Int)",
                            "literal": 10,
                        }
                    }
                },
                {
                    "node": "Statement[10]",
                    "type": "`a:14(*Int[:> *Scalar])",
                    "expression": {
                        "node": "Local::Declare::AndStore[9]",
                        "type": "`a:13(*Int[:> *Scalar])",
                        "$target": {
                            "__class__": "B::MOP::AST::SymbolTable::Entry",
                            "location": "LOCAL",
                            "name": "$y",
                            "type": "`a:3(*Int[:> *Scalar])"
                        },
                        "rhs": {
                            "node": "BinOp::Add[8]",
                            "type": "`a:12(*Int[:> *Numeric])",
                            "lhs": {
                                "literal": 100,
                                "node": "Const[6]",
                                "type": "`a:10(*Int)"
                            },
                            "rhs": {
                                "node": "Local::Fetch[7]",
                                "type": "`a:11(*Int[:> *Scalar])",
                                "$target": {
                                    "__class__": "B::MOP::AST::SymbolTable::Entry",
                                    "location": "LOCAL",
                                    "name": "$x",
                                    "type": "`a:2(*Int[:> *Scalar])"
                                }
                            }
                        }
                    }
                }
            ]
        }
    }
}
```
