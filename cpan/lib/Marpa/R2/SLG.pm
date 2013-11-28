# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

package Marpa::R2::Scanless::G;

use 5.010;
use strict;
use warnings;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '2.077_001';
$STRING_VERSION = $VERSION;
## no critic(BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

package Marpa::R2::Inner::Scanless::G;

use Scalar::Util 'blessed';
use English qw( -no_match_vars );

# names of packages for strings
our $PACKAGE = 'Marpa::R2::Scanless::G';
our $TRACE_FILE_HANDLE;

sub Marpa::R2::Internal::Scanless::meta_grammar {

    my $self = bless [], 'Marpa::R2::Scanless::G';
    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = \*STDERR;
    $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] =
        'Marpa::R2::Internal::MetaAST_Nodes';
    state $hashed_metag = Marpa::R2::Internal::MetaG::hashed_grammar();
    $self->_hash_to_runtime($hashed_metag);

    my $thick_g1_grammar =
        $self->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my @mask_by_rule_id;
    $mask_by_rule_id[$_] = $thick_g1_grammar->_rule_mask($_)
        for $thick_g1_grammar->rule_ids();
    $self->[Marpa::R2::Inner::Scanless::G::MASK_BY_RULE_ID] =
        \@mask_by_rule_id;

    return $self;

} ## end sub Marpa::R2::Internal::Scanless::meta_grammar

sub Marpa::R2::Scanless::G::new {
    my ( $class, $args ) = @_;

    my $self = [];
    bless $self, $class;

    $self->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE]       = *STDERR;
    $self->[Marpa::R2::Inner::Scanless::G::CACHE_RULEIDS_BY_LHS_NAME] = {};

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            "$PACKAGE expects args as ref to HASH; arg was non-reference");
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "$PACKAGE expects args as ref to HASH, got ref to $ref_type instead"
        );
    }

    # Other possible grammar options:
    # actions
    # default_empty_action
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

    my $rules_source;
    $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS] = {};
    ARG: for my $arg_name ( keys %{$args} ) {
        my $value = $args->{$arg_name};
        if ( $arg_name eq 'action_object' ) {
            $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS]->{$arg_name} =
                $value;
            next ARG;
        }
        if ( $arg_name eq 'bless_package' ) {
            $self->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE] = $value;
            next ARG;
        }
        if ( $arg_name eq 'default_action' ) {
            $self->[Marpa::R2::Inner::Scanless::G::G1_ARGS]->{$arg_name} =
                $value;
            next ARG;
        }
        if ( $arg_name eq 'source' ) {
            $rules_source = $value;
            next ARG;
        }
        $self->set( { $arg_name => $value });
        next ARG;
    } ## end ARG: for my $arg_name ( keys %{$args} )

    if ( not defined $rules_source ) {
        Marpa::R2::exception(
            'Marpa::R2::Scanless::G::new() called without a "source" argument'
        );
    }

    $ref_type = ref $rules_source;
    if ( $ref_type ne 'SCALAR' ) {
        Marpa::R2::exception(
            qq{Marpa::R2::Scanless::G::new() type of "source" argument is "$ref_type"},
            "  It must be a ref to a string\n"
        );
    } ## end if ( $ref_type ne 'SCALAR' )
    my $ast = Marpa::R2::Internal::MetaAST->new( $rules_source );
    my $hashed_ast = $ast->ast_to_hash();
    $hashed_ast->start_rule_setup();
    $self->_hash_to_runtime($hashed_ast);

    return $self;

} ## end sub Marpa::R2::Scanless::G::new

sub Marpa::R2::Scanless::G::set {
    my ( $slg, $args ) = @_;

    my $ref_type = ref $args;
    if ( not $ref_type ) {
        Carp::croak(
            "\$slg->set() expects args as ref to HASH; arg was non-reference"
        );
    }
    if ( $ref_type ne 'HASH' ) {
        Carp::croak(
            "\$slg->set() expects args as ref to HASH, got ref to $ref_type instead"
        );
    }

    # Other possible grammar options:
    # actions
    # default_rank
    # inaccessible_ok
    # symbols
    # terminals
    # unproductive_ok
    # warnings

    ARG: for my $arg_name ( keys %{$args} ) {
        my $value = $args->{$arg_name};
        if ( $arg_name eq 'trace_file_handle' ) {
            $slg->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] = $value;
            $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR]
                ->set( { $arg_name => $value } );
            $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR]
                ->set( { $arg_name => $value } );
            next ARG;
        } ## end if ( $arg_name eq 'trace_file_handle' )
        Carp::croak(
            '$slg->set does not know one of the options given to it:',
            qq{\n   The options not recognized was "$arg_name"\n}
        );
    } ## end ARG: for my $arg_name ( keys %{$args} )

    return $slg;

} ## end sub Marpa::R2::Scanless::G::set

sub Marpa::R2::Scanless::G::_hash_to_runtime {
    my ( $slg, $hashed_source ) = @_;

    $slg->[Marpa::R2::Inner::Scanless::G::DEFAULT_G1_START_ACTION] =
        $hashed_source->{'default_g1_start_action'};


    # The G1 grammar
    my $g1_args = $slg->[Marpa::R2::Inner::Scanless::G::G1_ARGS];
    $g1_args->{trace_file_handle} =
        $slg->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $g1_args->{bless_package} =
        $slg->[Marpa::R2::Inner::Scanless::G::BLESS_PACKAGE];
    $g1_args->{rules}   = $hashed_source->{rules}->{G1};
    $g1_args->{symbols} = $hashed_source->{symbols}->{G1};
    state $g1_target_symbol = '[:start]';
    $g1_args->{start} = $g1_target_symbol;
    $g1_args->{'_internal_'} = 1;
    my $thick_g1_grammar = Marpa::R2::Grammar->new($g1_args);
    my $g1_tracer        = $thick_g1_grammar->tracer();
    my $g1_thin          = $g1_tracer->grammar();

    my $symbol_ids_by_event_name_and_type = {};
    $slg->[Marpa::R2::Inner::Scanless::G::SYMBOL_IDS_BY_EVENT_NAME_AND_TYPE]
        = $symbol_ids_by_event_name_and_type;

    my $completion_events_by_name = $hashed_source->{completion_events};
    my $completion_events_by_id =
        $slg->[Marpa::R2::Inner::Scanless::G::COMPLETION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        my $event_name = $completion_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "Completion event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_completion_event_set( $symbol_id, 1 );
        $slg->[Marpa::R2::Inner::Scanless::G::COMPLETION_EVENT_BY_ID]
            ->[$symbol_id] = $completion_events_by_name->{$symbol_name};
        push
            @{ $symbol_ids_by_event_name_and_type->{$event_name}->{completion}
            }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})

    my $nulled_events_by_name = $hashed_source->{nulled_events};
    my $nulled_events_by_id =
        $slg->[Marpa::R2::Inner::Scanless::G::NULLED_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        my $event_name = $nulled_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "nulled event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_nulled_event_set( $symbol_id, 1 );
        $slg->[Marpa::R2::Inner::Scanless::G::NULLED_EVENT_BY_ID]
            ->[$symbol_id] = $nulled_events_by_name->{$symbol_name};
        push @{ $symbol_ids_by_event_name_and_type->{$event_name}->{nulled} },
            $symbol_id;
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    my $prediction_events_by_name = $hashed_source->{prediction_events};
    my $prediction_events_by_id =
        $slg->[Marpa::R2::Inner::Scanless::G::PREDICTION_EVENT_BY_ID] = [];
    for my $symbol_name ( keys %{$prediction_events_by_name} ) {
        my $event_name = $prediction_events_by_name->{$symbol_name};
        my $symbol_id  = $g1_tracer->symbol_by_name($symbol_name);
        if ( not defined $symbol_id ) {
            Marpa::R2::exception(
                "prediction event defined for non-existent symbol: $symbol_name\n"
            );
        }

        # Must be done before precomputation
        $g1_thin->symbol_is_prediction_event_set( $symbol_id, 1 );
        $slg->[Marpa::R2::Inner::Scanless::G::PREDICTION_EVENT_BY_ID]
            ->[$symbol_id] = $prediction_events_by_name->{$symbol_name};
        push
            @{ $symbol_ids_by_event_name_and_type->{$event_name}->{prediction}
            }, $symbol_id;
    } ## end for my $symbol_name ( keys %{$prediction_events_by_name...})

    my $lexeme_events_by_id =
        $slg->[Marpa::R2::Inner::Scanless::G::LEXEME_EVENT_BY_ID] = [];

    if (defined(
            my $precompute_error =
                Marpa::R2::Internal::Grammar::slif_precompute(
                $thick_g1_grammar)
        )
        )
    {
        if ( $precompute_error == $Marpa::R2::Error::UNPRODUCTIVE_START ) {

            # Maybe someday improve this by finding the start rule and showing
            # its RHS -- for now it is clear enough
            Marpa::R2::exception(qq{Unproductive start symbol});
        } ## end if ( $precompute_error == ...)
        Marpa::R2::exception(
            'Internal errror: unnkown precompute error code ',
            $precompute_error );
    } ## end if ( defined( my $precompute_error = ...))

    # Lexers

    state $lex_target_symbol = '[:start_lex]';

    # The only one, for now
    my $lexer_name = 'G0';
    my $lexer      = 0;

    my $g0_lexeme_by_name = $hashed_source->{is_lexeme};
    my @g0_lexeme_names   = keys %{$g0_lexeme_by_name};
    Marpa::R2::exception( "There are no lexemes\n",
        "  An SLIF grammar must have at least one lexeme\n" )
        if not scalar @g0_lexeme_names;

    my %lex_args = ();
    $lex_args{trace_file_handle} =
        $slg->[Marpa::R2::Inner::Scanless::G::TRACE_FILE_HANDLE] // \*STDERR;
    $lex_args{rules}        = $hashed_source->{rules}->{$lexer_name};
    $lex_args{symbols}      = $hashed_source->{symbols}->{$lexer_name};
    $lex_args{start}        = $lex_target_symbol;
    $lex_args{'_internal_'} = 1;
    my $lex_grammar = Marpa::R2::Grammar->new( \%lex_args );
    Marpa::R2::Internal::Grammar::slif_precompute($lex_grammar);
    my $lex_tracer = $lex_grammar->tracer();
    my $g0_thin    = $lex_tracer->grammar();
    $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR] = $lex_grammar;
    my $character_class_hash =
        $hashed_source->{character_classes}->{$lexer_name};
    my @class_table = ();

    for my $class_symbol ( sort keys %{$character_class_hash} ) {
        my $cc_components = $character_class_hash->{$class_symbol};
        my ( $compiled_re, $error ) =
            Marpa::R2::Internal::MetaAST::char_class_to_re($cc_components);
        if ( not $compiled_re ) {
            $error =~ s/^/  /gxms;    #indent all lines
            Marpa::R2::exception(
                "Failed belatedly to evaluate character class\n", $error );
        }
        push @class_table,
            [ $lex_tracer->symbol_by_name($class_symbol), $compiled_re ];
    } ## end for my $class_symbol ( sort keys %{$character_class_hash...})
    $slg->[Marpa::R2::Inner::Scanless::G::CHARACTER_CLASS_TABLES]->[$lexer] =
        \@class_table;


    my @g0_lexeme_to_g1_symbol;
    my @g1_symbol_to_g0_lexeme;
    $g0_lexeme_to_g1_symbol[$_] = -1 for 0 .. $g1_thin->highest_symbol_id();
    state $discard_symbol_name = '[:discard]';
    my $g0_discard_symbol_id =
        $lex_tracer->symbol_by_name($discard_symbol_name) // -1;

    LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names) {
        next LEXEME_NAME if $lexeme_name eq $discard_symbol_name;
        my $g1_symbol_id = $g1_tracer->symbol_by_name($lexeme_name);
        if (   not defined $g1_symbol_id
            or not $g1_thin->symbol_is_accessible($g1_symbol_id) )
        {
            Marpa::R2::exception(
                "A lexeme in lexer $lexer_name is not accessible from the G1 start symbol: $lexeme_name"
            );
        } ## end if ( not defined $g1_symbol_id or not $g1_thin->...)
        my $lex_symbol_id = $lex_tracer->symbol_by_name($lexeme_name);
        $g0_lexeme_to_g1_symbol[$lex_symbol_id] = $g1_symbol_id;
        $g1_symbol_to_g0_lexeme[$g1_symbol_id]  = $lex_symbol_id;
    } ## end LEXEME_NAME: for my $lexeme_name (@g0_lexeme_names)

    SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id() ) {
        if ( $g1_thin->symbol_is_terminal($symbol_id)
            and not defined $g1_symbol_to_g0_lexeme[$symbol_id] )
        {
            my $internal_symbol_name = $g1_tracer->symbol_name($symbol_id);
            my $symbol_in_display_form =
                $thick_g1_grammar->symbol_in_display_form($symbol_id);
            if ( $lex_tracer->symbol_by_name($internal_symbol_name) ) {
                Marpa::R2::exception(
                    "Symbol $symbol_in_display_form is a lexeme in G1, but not in lexer $lexer_name.\n",
                    qq{  The internal name for this symbol is $internal_symbol_name\n},
                    "  This may be because $symbol_in_display_form was used on a RHS in lexer $lexer_name.\n",
                    "  A lexeme cannot be used on the RHS of a lexer rule.\n"
                );
            } ## end if ( $lex_tracer->symbol_by_name($internal_symbol_name...))
            Marpa::R2::exception(
                "Unproductive symbol: $symbol_in_display_form\n",
                qq{\n  The internal name for this symbol is $internal_symbol_name\n},
            );
        } ## end if ( $g1_thin->symbol_is_terminal($symbol_id) and not...)
    } ## end SYMBOL_ID: for my $symbol_id ( 0 .. $g1_thin->highest_symbol_id(...))

    my $thin_slg = $slg->[Marpa::R2::Inner::Scanless::G::C] =
        Marpa::R2::Thin::SLG->new( $lex_tracer->grammar(),
        $g1_tracer->grammar() );
    $slg->[Marpa::R2::Inner::Scanless::G::LEXER_NAMES]->[0] = 'G0';

    my $lexeme_declarations = $hashed_source->{lexeme_declarations};
    for my $lexeme_name ( keys %{$lexeme_declarations} ) {
        Marpa::R2::exception(
            "Symbol <$lexeme_name> is declared as a lexeme, but it is not used as one.\n"
        ) if not $g0_lexeme_by_name->{$lexeme_name};

        my $declarations = $lexeme_declarations->{$lexeme_name};
        my $g1_lexeme_id = $g1_tracer->symbol_by_name($lexeme_name);

        if ( defined( my $value = $declarations->{priority} ) ) {
            $thin_slg->g1_lexeme_priority_set( $g1_lexeme_id, $value );
        }
        my $pause_value = $declarations->{pause};
        if ( defined $pause_value ) {
            $thin_slg->g1_lexeme_pause_set( $g1_lexeme_id, $pause_value );

            if ( defined( my $event_name = $declarations->{'event'} ) ) {
                $lexeme_events_by_id->[$g1_lexeme_id] = $event_name;
                push @{ $symbol_ids_by_event_name_and_type->{$event_name}
                        ->{lexeme} }, $g1_lexeme_id;
            }
        } ## end if ( defined $pause_value )

    } ## end for my $lexeme_name ( keys %{$lexeme_declarations} )

    # Now that we know the lexemes, check attempts to defined a
    # completion or a nulled event for one
    for my $symbol_name ( keys %{$completion_events_by_name} ) {
        Marpa::R2::exception(
            "A completion event is declared for <$symbol_name>, but it is a G1 lexeme.\n",
            "  Completion events are only valid for symbols on the LHS of G1 rules.\n"
        ) if $g0_lexeme_by_name->{$symbol_name};
    } ## end for my $symbol_name ( keys %{$completion_events_by_name...})
    for my $symbol_name ( keys %{$nulled_events_by_name} ) {
        Marpa::R2::exception(
            "A nulled event is declared for <$symbol_name>, but it is a G1 lexeme.\n",
            "  nulled events are only valid for symbols on the LHS of G1 rules.\n"
        ) if $g0_lexeme_by_name->{$symbol_name};
    } ## end for my $symbol_name ( keys %{$nulled_events_by_name} )

    my @g0_rule_to_g1_lexeme;
    RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() ) {
        my $lhs_id = $g0_thin->rule_lhs($rule_id);
        my $lexeme_id =
            $lhs_id == $g0_discard_symbol_id
            ? -2
            : ( $g0_lexeme_to_g1_symbol[$lhs_id] // -1 );
        $g0_rule_to_g1_lexeme[$rule_id] = $lexeme_id;
        $thin_slg->lexer_rule_to_g1_lexeme_set( 0, $rule_id, $lexeme_id );
    } ## end RULE_ID: for my $rule_id ( 0 .. $g0_thin->highest_rule_id() )

    $thin_slg->precompute();
    $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR] =
        $thick_g1_grammar;

    return 1;

} ## end sub Marpa::R2::Scanless::G::_hash_to_runtime

sub thick_subgrammar_by_name {
    my ( $slg, $subgrammar ) = @_;
    $subgrammar //= 'G1';
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR]
        if $subgrammar eq 'G1';
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR]
        if $subgrammar eq 'G0';
    Marpa::R2::exception(qq{Bad subgrammar in Marpa"$subgrammar"});
} ## end sub thick_subgrammar_by_name

sub Marpa::R2::Scanless::G::rule_expand {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->tracer()
        ->rule_expand($rule_id);
}

sub Marpa::R2::Scanless::G::symbol_name {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->tracer()
        ->symbol_name($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_display_form {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )
        ->symbol_in_display_form($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_dsl_form {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name( $slg, $subgrammar )
        ->symbol_dsl_form($symbol_id);
}

sub Marpa::R2::Scanless::G::symbol_description {
    my ( $slg, $symbol_id, $subgrammar ) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)
        ->symbol_description($symbol_id);
}

sub Marpa::R2::Scanless::G::rule_show
{
    my ( $slg, $rule_id, $subgrammar) = @_;
    return slg_rule_show($slg, $rule_id, thick_subgrammar_by_name($slg, $subgrammar));
}

sub slg_rule_show {
    my ( $slg, $rule_id, $subgrammar ) = @_;
    my $tracer       = $subgrammar->tracer();
    my $subgrammar_c = $subgrammar->[Marpa::R2::Internal::Grammar::C];
    my @symbol_ids   = $tracer->rule_expand($rule_id);
    return if not scalar @symbol_ids;
    my ( $lhs, @rhs ) =
        map { $subgrammar->symbol_in_display_form($_) } @symbol_ids;
    my $minimum    = $subgrammar_c->sequence_min($rule_id);
    my @quantifier = ();

    if ( defined $minimum ) {
        @quantifier = ( $minimum <= 0 ? q{*} : q{+} );
    }
    return join q{ }, $lhs, q{::=}, @rhs, @quantifier;
} ## end sub slg_rule_show

sub Marpa::R2::Scanless::G::show_rules {
    my ( $slg, $verbose, $subgrammar ) = @_;
    my $text     = q{};
    $verbose    //= 0;
    $subgrammar //= 'G1';

    my $thick_grammar = thick_subgrammar_by_name($slg, $subgrammar);

    my $rules     = $thick_grammar->[Marpa::R2::Internal::Grammar::RULES];
    my $grammar_c = $thick_grammar->[Marpa::R2::Internal::Grammar::C];

    for my $rule ( @{$rules} ) {
        my $rule_id = $rule->[Marpa::R2::Internal::Rule::ID];

        my $minimum = $grammar_c->sequence_min($rule_id);
        my @quantifier =
            defined $minimum ? $minimum <= 0 ? (q{*}) : (q{+}) : ();
        my $lhs_id      = $grammar_c->rule_lhs($rule_id);
        my $rule_length = $grammar_c->rule_length($rule_id);
        my @rhs_ids =
            map { $grammar_c->rule_rhs( $rule_id, $_ ) }
            ( 0 .. $rule_length - 1 );
        $text .= join q{ }, $subgrammar, "R$rule_id",
            $thick_grammar->symbol_in_display_form($lhs_id),
            '::=',
            ( map { $thick_grammar->symbol_in_display_form($_) } @rhs_ids ),
            @quantifier;
        $text .= "\n";

        if ( $verbose >= 2 ) {

            my $description = $rule->[Marpa::R2::Internal::Rule::DESCRIPTION];
            $text .= "  $description\n" if $description;
            my @comment = ();
            $grammar_c->rule_length($rule_id) == 0
                and push @comment, 'empty';
            $thick_grammar->rule_is_used($rule_id)
                or push @comment, '!used';
            $grammar_c->rule_is_productive($rule_id)
                or push @comment, 'unproductive';
            $grammar_c->rule_is_accessible($rule_id)
                or push @comment, 'inaccessible';
            $rule->[Marpa::R2::Internal::Rule::DISCARD_SEPARATION]
                and push @comment, 'discard_sep';

            if (@comment) {
                $text .= q{  } . ( join q{ }, q{/*}, @comment, q{*/} ) . "\n";
            }

            $text .= "  Symbol IDs: <$lhs_id> ::= "
                . ( join q{ }, map {"<$_>"} @rhs_ids ) . "\n";

        } ## end if ( $verbose >= 2 )

        if ( $verbose >= 3 ) {

            my $tracer = $thick_grammar->tracer();

            $text
                .= "  Internal symbols: <"
                . $tracer->symbol_name($lhs_id)
                . q{> ::= }
                . (
                join q{ },
                map { '<' . $tracer->symbol_name($_) . '>' } @rhs_ids
                ) . "\n";

        } ## end if ( $verbose >= 3 )

    } ## end for my $rule ( @{$rules} )

    return $text;
} ## end sub Marpa::R2::Scanless::G::show_rules

sub Marpa::R2::Scanless::G::show_symbols {
    my ( $slg, $verbose, $subgrammar ) = @_;
    my $text = q{};
    $verbose    //= 0;
    $subgrammar //= 'G1';

    my $thick_grammar = thick_subgrammar_by_name($slg, $subgrammar);

    my $symbols   = $thick_grammar->[Marpa::R2::Internal::Grammar::SYMBOLS];
    my $grammar_c = $thick_grammar->[Marpa::R2::Internal::Grammar::C];

    for my $symbol ( @{$symbols} ) {
        my $symbol_id = $symbol->[Marpa::R2::Internal::Symbol::ID];

        $text .= join q{ }, $subgrammar, "S$symbol_id",
            $thick_grammar->symbol_in_display_form($symbol_id);

        my $description = $symbol->[Marpa::R2::Internal::Symbol::DESCRIPTION];
        if ($description) {
            $text .= " -- $description";
        }
        $text .= "\n";

        if ( $verbose >= 2 ) {

            my @tag_list = ();
            $grammar_c->symbol_is_productive($symbol_id)
                or push @tag_list, 'unproductive';
            $grammar_c->symbol_is_accessible($symbol_id)
                or push @tag_list, 'inaccessible';
            $grammar_c->symbol_is_nulling($symbol_id)
                and push @tag_list, 'nulling';
            $grammar_c->symbol_is_terminal($symbol_id)
                and push @tag_list, 'terminal';

            if (@tag_list) {
                $text
                    .= q{  } . ( join q{ }, q{/*}, @tag_list, q{*/} ) . "\n";
            }

            my $tracer = $thick_grammar->tracer();
            $text .= "  Internal name: <"
                . $tracer->symbol_name($symbol_id) . qq{>\n};

        } ## end if ( $verbose >= 2 )

        if ( $verbose >= 3 ) {

            my $dsl_form = $symbol->[Marpa::R2::Internal::Symbol::DSL_FORM];
            if ($dsl_form) { $text .= qq{  SLIF name: $dsl_form\n}; }

        } ## end if ( $verbose >= 3 )

    } ## end for my $symbol ( @{$symbols} )

    return $text;
} ## end sub Marpa::R2::Scanless::G::show_symbols

sub Marpa::R2::Scanless::G::show_dotted_rule {
    my ( $slg, $rule_id, $dot_position ) = @_;
    my $grammar =  $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
    my $tracer  = $grammar->tracer();
    my $grammar_c = $grammar->[Marpa::R2::Internal::Grammar::C];
    my ( $lhs, @rhs ) =
    map { $grammar->symbol_in_display_form($_) } $tracer->rule_expand($rule_id);
    my $rhs_length = scalar @rhs;

    my $minimum = $grammar_c->sequence_min($rule_id);
    my @quantifier = ();
    if (defined $minimum) {
        @quantifier = ($minimum <= 0 ? q{*} : q{+} );
    }
    $dot_position = 0 if $dot_position < 0;
    if ($dot_position < $rhs_length) {
        splice @rhs, $dot_position, 0, q{.};
        return join q{ }, $lhs, q{->}, @rhs, @quantifier;
    } else {
        return join q{ }, $lhs, q{->}, @rhs, @quantifier, q{.};
    }
} ## end sub Marpa::R2::Grammar::show_dotted_rule

sub Marpa::R2::Scanless::G::rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR]
        ->rule(@args);
}

sub Marpa::R2::Scanless::G::rule_ids {
    my ($slg, $subgrammar) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->rule_ids();
}

sub Marpa::R2::Scanless::G::symbol_ids {
    my ($slg, $subgrammar) = @_;
    return thick_subgrammar_by_name($slg, $subgrammar)->symbol_ids();
}

sub Marpa::R2::Scanless::G::g1_rule_ids {
    my ($slg) = @_;
    return $slg->rule_ids();
}

sub Marpa::R2::Scanless::G::g0_rule_ids {
    my ($slg) = @_;
    return $slg->rule_ids('G0');
}

sub Marpa::R2::Scanless::G::g0_rule {
    my ( $slg, @args ) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_LEX_GRAMMAR]
        ->rule(@args);
}

# Internal methods, not to be documented

sub Marpa::R2::Scanless::G::thick_g1_grammar {
    my ($slg) = @_;
    return $slg->[Marpa::R2::Inner::Scanless::G::THICK_G1_GRAMMAR];
}

1;

# vim: expandtab shiftwidth=4: