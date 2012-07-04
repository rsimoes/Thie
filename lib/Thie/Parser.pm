package Thie::Parser;

use strict;
use warnings FATAL => "all";
use utf8;
use charnames ();
use Marpa::XS;

# VERSION

sub charname { map {
    my $name = charnames::viacode( ord $_ );
    $name =~ s/[[:space:]]/_/g;
    $name } @_ }

sub mkrules {
    my ($lhs, $rhs) = @_;
    return map { [ $lhs => ref $_ eq "ARRAY" ? $_ : [$_] ] } @$rhs }

my @tokens = mkrules(
    token => [ qw(identifier boolean number character string),
               charnames(qw[ ( ) ' ` , .]),
               join( "_", charnames("#", "(") ),
               join( "_", charnames(",", "@") ) ] );

my @delimiters = mkrules(
    delimiter => ["whitespace", charnames(qw[ ( ) "]) ] );

my @whitespace = mkrules( whitespace => [charnames(" ", "\n")] );
my $comment = [ comment => [ join( "_", charnames("/", "*") ),
                             qw(whitespace token* whitespace),
                             join( "_", charnames("*", "/") ) ] ];
my @atmosphere = mkrules( atmosphere => [qw(whitespace comment)] );

my $intertoken_space = [ intertoken_space => ["atmosphere*"] ];

my @identifier = mkrules( identifier => [
    [qw(initial subsequent*)], "peculiar_identifier" ] );

my @initial    = mkrules( initial => [qw(letter special_initial)] );

my @letter     = mkrules( letter => [ charnames("a".."z", "A".."Z") ] );

my @special_initial = mkrules(
    special_initial => [ charnames(qw[ ! $ & * / : < = > ^ _ ~ ]) ] );

my @subsequent = mkrules(
    subsequent => [qw(initial digit special_subsequent)] );

my @digit      = mkrules( charnames(0..9) );

my @special_subsequent = mkrules(
    special_subsequent => [charnames( qw[ + - . @ ] ) ] );

my @peculiar_identifier = mkrules(
    peculiar_identifier => [ charnames( qw[ + - … ] ) ] );

my @syntactic_keyword = mkrules( syntactic_keyword => [
    qw(expression_keyword else define unquote unquote_splicing),
    join( "_", charnames("=", ">") ) ] );

my @expression_keyword = mkrules( expression_keyword => [
    qw(quote lambda if set! begin cond and or case let let* letrec do delay
       quasiquote)] );

my @variable = ( variable => ["identifier"] );

my @boolean  = mkrules( boolean => [qw(true false)] );

my @character = 
<character> --> #\ <any character>
     | #\ <character name>
<character name> --> space | newline

<string> --> " <string element>* "
<string element> --> <any character other than " or \>
     | \" | \\ 

<number> --> <num 2>| <num 8>
     | <num 10>| <num 16>


my @rules = (@token, @delimiter, @whitespace, $comment, @atmosphere,
             $intertoken_space, @identifier, @initial, @letter,
             @special_initial, @subsequent, @digit, @special_subsequent,
             @peculiar_identifier, @syntactic_keyword, @expression_keyword,
             @variable, @boolean, @character, @character_name, $string,
             @string_element, @number);



my $grammar = Marpa::XS::Grammar->new( {
    start   => "Expression",
    actions => "My_Actions",
    default_action => "first_arg",
    rules   => \@rules } );

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
