package App::finquote;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

sub _get_q {
    require Finance::Quote;
    my $q = Finance::Quote->new;
    $q->timeout(60);
    $q;
}

$SPEC{finquote} = {
    v => 1.1,
    summary => 'Get stock and mutual fund quotes from various exchanges',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'fetch'. Other actions include:

* 'list_sources' - List available sources.

_
            default => 'fetch',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action list_sources', code => sub { $_[0]{action} = 'list_sources' }},
            },
        },
        symbols => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'symbol',
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
        },
        sources => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'source',
            schema => ['array*', of=>'str*'],
            #elem_completion => sub {
            #    my %args = @_;
            #},
            cmdline_aliases => {
                s => {},
            },
        },
    },
    examples => [
        {
            summary => 'List available sources',
            argv => [qw/-l/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quote for a few NASDAQ stocks',
            argv => [qw/-s nasdaq AAPL AMZN MSFT/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quote for a few Indonesian stocks',
            argv => [qw/-s asia BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub finquote {
    my %args = @_;
    my $action = $args{action} // 'fetch';

    if ($action eq 'list_sources') {
        my $q = _get_q();
        return [200, "OK", [sort $q->sources]];
    } elsif ($action eq 'fetch') {
        my $q = _get_q();
        my $symbols = $args{symbols};
        return [400, "Please specify at least one symbol to fetch quotes of"]
            unless $symbols && @$symbols;
        my $sources = $args{sources};
        return [400, "Please specify at least one source to fetch quotes from"]
            unless $symbols && @$sources;
        my $num_success = 0;
        my @rows;
        for my $source (@$sources) {
            my $info = $q->fetch($source, @$symbols);
            if (!$info || !keys(%$info)) {
                log_warn "Couldn't fetch quotes %s from %s", $symbols, $source;
                next;
            }
            $info->{source} = $source;
            push @rows, $info;
            $num_success++;
        }
        if ($num_success) {
            return [200, "OK", \@rows];
        } else {
            return [500, "Couldn't fetch any quote"];
        }
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See L<finquote> script.

=cut
