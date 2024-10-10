#!perl

use v5.40;
use experimental qw[ class ];

use YAML qw[ Dump ];
use Test::More;

use B::MOP;
use B::MOP::Type;

my $scalar  = B::MOP::Type::Scalar->new;
my $bool    = B::MOP::Type::Bool->new;
my $string  = B::MOP::Type::String->new;
my $numeric = B::MOP::Type::Numeric->new;
my $int     = B::MOP::Type::Int->new;
my $float   = B::MOP::Type::Float->new;

subtest '... tests type variables' => sub {
    pass B::MOP::Type::Variable->new( type => $int );
    pass B::MOP::Type::Variable->new( type => $numeric );
};

subtest '... tests type relations' => sub {
    pass B::MOP::Type::Relation->new( lhs => $int,     rhs => $int );
    pass B::MOP::Type::Relation->new( lhs => $int,     rhs => $numeric );
    pass B::MOP::Type::Relation->new( lhs => $numeric, rhs => $int );
    pass B::MOP::Type::Relation->new( lhs => $bool,    rhs => $int );
    pass B::MOP::Type::Relation->new( lhs => $bool,    rhs => $scalar );

    pass B::MOP::Type::Relation->new( lhs => $int->cast($numeric), rhs => $int );
};

subtest '... casting type variables' => sub {
    my $a1 = B::MOP::Type::Variable->new( type => $int );
    my $a2 = B::MOP::Type::Variable->new( type => $bool );

    pass $a1;
    pass $a2;

    pass $a1->cast_type_into($a2);
};

done_testing;
