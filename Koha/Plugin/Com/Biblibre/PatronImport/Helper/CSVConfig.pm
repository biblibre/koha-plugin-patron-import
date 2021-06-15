package Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    SupportedEOL
    SupportedQuoteChar
    SupportedSepChar
);

use Modern::Perl;

sub SupportedEOL {
    return [
        { code => 'line_feed', name => 'Line Feed (\n)' },
        { code => 'carriage_return', name => 'Carriage Return (\r)' },
        { code => 'carriage_return_line_feed', name => 'Carriage Return and Line Feed (\r\n)' }
    ];
}

sub SupportedQuoteChar {
    return [
        { code => 'none', name => 'None' },
        { code => 'simple', name => "Simple quote (')" },
        { code => 'double', name => 'Double quote (")' }
    ];
}

sub SupportedSepChar {
    return [
        { code => 'semicolon', name => "Semicolon (;)" },
        { code => 'comma', name => "Comma (,)" },
        { code => 'pipe', name => "Pipe (|)" },
        { code => 'tab', name => "Tabulation (\\t)" },
        { code => 'sharp', name => "Sharp (#)" }
    ];
}

sub FormatSettings {
    my ( $settings ) = @_;

    $settings->{eol} = _formatEOL($settings->{eol});
    $settings->{quote_char} = _formatQuoteChar($settings->{quote_char});
    $settings->{sep_char} = _formatSepChar($settings->{sep_char});

    if ($settings->{quote_char} eq '') {
	delete $settings->{quote_char};
    }
    return $settings;
}

sub _formatEOL {
    my ( $eol ) = @_;

    if ( $eol eq 'line_feed' ) {
        return "\n";
    }

    if ( $eol eq 'carriage_return' ) {
        return "\r";
    }

    if ( $eol eq 'carriage_return_line_feed' ) {
        return "\r\n";
    }

    die "Unsupported line end: $eol"
}

sub _formatQuoteChar {
    my ( $quote_char ) = @_;

    if ( $quote_char eq 'simple' ) {
        return "'";
    }

    if ( $quote_char eq 'double' ) {
        return "\"";
    }

    return '';
}

sub _formatSepChar {
    my ( $sep_char ) = @_;

    if ( $sep_char eq 'semicolon' ) {
        return ";";
    }

    if ( $sep_char eq 'comma' ) {
        return ",";
    }

    if ( $sep_char eq 'pipe' ) {
        return "|";
    }

    if ( $sep_char eq 'tab' ) {
        return "\t";
    }

    if ( $sep_char eq 'sharp' ) {
        return "#";
    }

    die "Unsupported char separator: $sep_char";
}

1;
