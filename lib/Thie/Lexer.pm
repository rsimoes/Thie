package Thie::Lexer;

use v5.10;
use strict;
use warnings;
use charnames ();
use Data::Dump;
use Marpa::XS;

sub name_of {
    my ($char) = @_;
    my $name = lc charnames::viacode( ord $char );
    $name =~ s/[[:space:]-]/_/g;
    return $name }

sub proc_atom { print "atom"; dd \@_; \@_ }
#sub proc_list { dd \@_; \@_  }
#sub char { print "char: "; dd \@_; \@_ }

my $l_paren = name_of("(");
my $r_paren = name_of(")");

my $grammar = Marpa::XS::Grammar->new(
    { start         => "sexp",
#      trace_rules   => 1,
      actions       => __PACKAGE__,
      rules         => [
          [ sexp  => ["atom"] ],
          [ sexp  => ["list"] ],
          [ list  => [$l_paren, "sexp", name_of("."), "sexp", $r_paren] ],
          { lhs   => "atom", rhs => ["char"], min => 1, action => "proc_atom" },
          ( map { [ char => [name_of($_)] ] } 0..9, "a".."z", "A".."Z" ) ] } );

$grammar->precompute;
my $reczr = Marpa::XS::Recognizer->new(
    { grammar => $grammar, trace_actions => 0 } );
my $program = "(a . (b . (c . (d . nil))";
my @chars = grep { !/[[:space:]]/ } split //, $program;
#dd \@chars;
#$reczr->read(name_of($_), $_) for @chars;
$reczr->read("char", name_of("a"));
$reczr->read("char", "b");
my $result = $reczr->value;
dd $result;

__END__;

my $recce = Marpa::XS::Recognizer->new(
    { grammar => $grammar, trace_actions => 1 });

my $res;
if ($repeat) {
    $res = "A$repeat(" . ('A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))' x $repeat) . ')';
} else {
    $res = 'A2(A2(S3(Hey)S13(Hello, World!))S5(Ciao!))';
}

my $string_length = 0;
my $position = 0;
my $input_length = length $res;

INPUT: while ($position < $input_length) {
pos $res = $position;
if ($res =~ m/\G S (\d+) [(]/xms) {
            my $string_length = $1;
            $recce->read( 'Schar');
               $recce->read( 'Scount' );
               $recce->read( 'lparen' );
               $position += 2 + (length $string_length);
               $recce->read( 'text', substr( $res, $position, $string_length ));
               $position += $string_length;
            next INPUT;
        }
if ($res =~ m/\G A (\d+) [(]/xms) {
            my $count = $1;
            $recce->read( 'Achar');
               $recce->read( 'Acount' );
               $recce->read( 'lparen' );
               $position += 2 + length $count;
            next INPUT;
        }
        if ( $res =~ m{\G [)] }xms ) {
            $recce->read( 'rparen' );
               $position += 1;
            next INPUT;
        }
        die "Error reading input: ", substr( $res, $position, 100 );
} ## end for ( ;; )

my $result = $recce->value();
die "No parse" if not defined $result;
my $received = Dumper(${$result});

my $expected = <<'EXPECTED_OUTPUT';
$VAR1 = [
          [
            'Hey',
            'Hello, World!'
          ],
          'Ciao!'
        ];
EXPECTED_OUTPUT
if ($received eq $expected )
{
    say "Output matches";
} else {
    say "Output differs: $received";
}
