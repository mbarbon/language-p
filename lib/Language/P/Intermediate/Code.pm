package Language::P::Intermediate::Code;

use strict;
use warnings;
use parent qw(Language::P::Object);

use Scalar::Util; # weaken
use Language::P::Intermediate::LexicalState;

__PACKAGE__->mk_ro_accessors( qw(type name basic_blocks outer inner
                                 lexicals prototype scopes lexical_states
                                 regex_string) );

sub set_outer { $_[0]->{outer} = $_[1] }

use Exporter 'import';

our @EXPORT_OK = qw(SCOPE_SUB SCOPE_EVAL SCOPE_MAIN SCOPE_LEX_STATE SCOPE_REGEX
                    SCOPE_VALUE CODE_MAIN CODE_SUB CODE_REGEX CODE_EVAL);
our %EXPORT_TAGS =
  ( all => \@EXPORT_OK,
    );

use constant +
  { SCOPE_SUB        => 1, # top subroutine scope
    SCOPE_EVAL       => 2, # eval block/eval string
    SCOPE_MAIN       => 4, # eval string, file or subroutine top scope
    SCOPE_LEX_STATE  => 8, # there is a lexical state change inside the scope
    SCOPE_REGEX      => 16,# there is a regex match inside the scope
    SCOPE_VALUE      => 32,# the scope returns a value (do BLOCK, eval, ...)

    CODE_MAIN        => 1,
    CODE_SUB         => 2,
    CODE_REGEX       => 3,
    CODE_EVAL        => 4,
    };

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( $args );

    $self->{inner} = [];
    $self->{scopes} ||= [];
    $self->{lexical_states} ||=
        [ Language::P::Intermediate::LexicalState->new
              ( { scope    => 0,
                  package  => 'main',
                  hints    => 0,
                  warnings => undef,
                  } ) ];
    $self->{regex_string} ||= undef;

    return $self;
}

sub is_main  { $_[0]->{type} == CODE_MAIN || $_[0]->{type} == CODE_EVAL }
sub is_sub   { $_[0]->{type} == CODE_SUB }
sub is_regex { $_[0]->{type} == CODE_REGEX }
sub is_eval  { $_[0]->{type} == CODE_EVAL }

sub weaken   { $_->weaken, Scalar::Util::weaken( $_ ) foreach @{$_[0]->inner} }

sub find_alive_blocks {
    my( $self ) = @_;
    my @queue = ( $self->basic_blocks->[0],
                  grep defined, map $_->exception, @{$self->scopes} );
    $_->{dead} = 0 foreach @queue;

    while( @queue ) {
        my $block = shift @queue;

        foreach my $successor ( @{$block->successors} ) {
            next unless $successor->dead;
            $successor->{dead} = 0;
            push @queue, $successor;
        }
    }
}

1;
