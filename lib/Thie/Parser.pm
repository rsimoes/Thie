package Thie::Parser;

use strict;
use warnings FATAL => "all";
use utf8;
use charnames ();
use Marpa::XS;

# VERSION

sub rule_names { map {
    my $name = charnames::viacode( ord $_ );
    $name =~ s/[[:space:]-]/_/g;
    $name } @_ }

sub rhs_disjuncts {
    my ($lhs, $rhs) = @_;
    return map { [ $lhs => ref $_ eq "ARRAY" ? $_ : [$_] ] } @$rhs }

#my @token = do {
#    no warnings "qw";
#    rhs_disjuncts(
#        token => [ qw(identifier boolean number character string),
#                   rule_names(qw[ ( ) ' ` , . ]),
#                   join( "_", rule_names("#", "(") ),
#                   join( "_", rule_names(",", "@") ) ] ) };

my @delimiter = rhs_disjuncts(
    delimiter => ["whitespace", rule_names(qw[ ( ) " ]) ] );

my @whitespace = rhs_disjuncts( whitespace => [rule_names(" ", "\n")] );
my $comment = [ comment => [ join( "_", rule_names("/", "*") ),
                             qw(whitespace token* whitespace),
                             join( "_", rule_names("*", "/") ) ] ];
my @atmosphere = rhs_disjuncts( atmosphere => [qw(whitespace comment)] );

my $intertoken_space = [ intertoken_space => ["atmosphere*"] ];

#my @identifier = rhs_disjuncts( identifier => [
    [qw(initial subsequent*)], "peculiar_identifier" ] );

my @initial    = rhs_disjuncts( initial => [qw(letter special_initial)] );

my @letter     = rhs_disjuncts( letter => [ rule_names("a".."z", "A".."Z") ] );

my @special_initial = rhs_disjuncts(
    special_initial => [ rule_names(qw[ ! $ & * / : < = > ^ _ ~ ]) ] );

my @subsequent = rhs_disjuncts(
    subsequent => [qw(initial digit special_subsequent)] );

my @digit      = rhs_disjuncts( digit => [ rule_names(0..9) ] );

my @special_subsequent = rhs_disjuncts(
    special_subsequent => [rule_names( qw[ + - . @ ] ) ] );

my @peculiar_identifier = rhs_disjuncts(
    peculiar_identifier => [ rule_names( qw[ + - … ] ) ] );

my @syntactic_keyword = rhs_disjuncts( syntactic_keyword => [
    qw(expression_keyword else define unquote unquote_splicing),
    join( "_", rule_names("=", ">") ) ] );

my @expression_keyword = rhs_disjuncts( expression_keyword => [
    qw(quote lambda if set! begin cond and or case let let* letrec do delay
       quasiquote)] );

my $variable = [ variable => ["identifier"] ];

my @boolean  = rhs_disjuncts( boolean => [qw(true false)] );

my %character = ( lhs => "character" );
#<character> --> #\ <any character>
#     | #\ <character name>
#<character name> --> space | newline
my @character_name = rhs_disjuncts( character_name => [rule_names(" ", "\n")] );
my $string = [ string => [rule_names("\""), "string_element*", rule_names("\"")] ];
my %string_element = ( lhs => "string_element" );
my %number = ( lhs => "number" );

my @rules = (@token, @delimiter, @whitespace, $comment, @atmosphere,
             $intertoken_space, @identifier, @initial, @letter,
             @special_initial, @subsequent, @digit, @special_subsequent,
             @peculiar_identifier, @syntactic_keyword, @expression_keyword,
             $variable, @boolean, \%character, @character_name, $string,
             \%string_element, \%number);



my $grammar = Marpa::XS::Grammar->new( {
    start   => "token",
    trace_rules => 1,
    rules   => \@rules,
    terminals => [qw(number string_element character)] } );
$grammar->precompute;

1;

__END__

==bnf

<token> --> <identifier> | <boolean> | <number>
     | <character> | <string>
     | ( | ) | #( | ' | ` | , | ,@ | .
<delimiter> --> <whitespace> | ( | ) | " | ;
<whitespace> --> <space or newline>
<comment> --> ;  <all subsequent characters up to a
                 line break>
<atmosphere> --> <whitespace> | <comment>
<intertoken space> --> <atmosphere>*

<identifier> --> <initial> <subsequent>*
     | <peculiar identifier>
<initial> --> <letter> | <special initial>
<letter> --> a | b | c | ... | z

<special initial> --> ! | $ | % | & | * | / | : | < | =
     | > | ? | ^ | _ | ~
<subsequent> --> <initial> | <digit>
     | <special subsequent>
<digit> --> 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
<special subsequent> --> + | - | . | @
<peculiar identifier> --> + | - | ...
<syntactic keyword> --> <expression keyword>
     | else | => | define
     | unquote | unquote-splicing
<expression keyword> --> quote | lambda | if
     | set! | begin | cond | and | or | case
     | let | let* | letrec | do | delay
     | quasiquote

`<variable> => <'any <identifier> that isn't
                also a <syntactic keyword>>

<boolean> --> #t | #f
<character> --> #\ <any character>
     | #\ <character name>
<character name> --> space | newline

<string> --> " <string element>* "
<string element> --> <any character other than " or \>
     | \" | \\

<number> --> <num 2>| <num 8>
     | <num 10>| <num 16>
