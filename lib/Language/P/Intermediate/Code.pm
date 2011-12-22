package Language::P::Intermediate::Code;

use strict;
use warnings;
use parent qw(Language::P::Object);

use Language::P::Intermediate::LexicalState;
use Language::P::Constants qw(:all);

__PACKAGE__->mk_ro_accessors( qw(name basic_blocks outer inner
                                 lexicals prototype scopes lexical_states
                                 regex_string flags) );

sub set_outer { $_[0]->{outer} = $_[1] }

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

sub is_main     { $_[0]->{flags} == CODE_MAIN || $_[0]->{flags} == CODE_EVAL }
sub is_sub      { ( $_[0]->{flags} & CODE_SUB ) ? 1 : 0 }
sub is_regex    { $_[0]->{flags} == CODE_REGEX }
sub is_eval     { $_[0]->{flags} == CODE_EVAL }
sub is_constant { ( $_[0]->{flags} & CODE_CONSTANT ) ? 1 : 0 }
sub is_constant_prototype { ( $_[0]->{flags} & CODE_CONSTANT_PROTOTYPE ) ? 1 : 0 }

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
