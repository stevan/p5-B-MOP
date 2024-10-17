<!----------------------------------------------------------------------------->
# B::MOP
<!----------------------------------------------------------------------------->
## A compile time MOP for Perl
<!----------------------------------------------------------------------------->

This is a crazy experiment to see if we can create an AST for Perl using the
opcode tree as input (instead of the source text).

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
load any subroutines it finds. Next is to finalize the MOP, this is a multi-phase
process which does the followings steps:

1. Builds a dependency graph between packages and subroutines
    - detects all callsites and connects them to the subroutines
    - checks for cross package calls and notes dependency
2. Resolve all subroutine calls
    - this will check arity between caller and callee at this time
    - connect all callsites with sub being called
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

```perl
my $mop = B::MOP->new;
my $Foo = $mop->load_package('Foo');
$mop->finalize;

my $test = $Foo->get_subroutine('test');
say json_encode($test->to_JSON);
```

From here you can see this by dumping the AST, which gives you this.

Note that types are all stored inside a unique Type::Variable (ex: "`a:3") and the type keeps track of it's changes. So "`a:2(\*Int[:> \*Scalar])" is a the type variable, and the type started out as a \*Scalar but was downcast (`:>`) into an \*Int.

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
