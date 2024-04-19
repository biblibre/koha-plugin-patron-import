package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::Date;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    # Ymd
    if ($value =~ /^(\d{4})(\d{2})(\d{2})$/ ) {
        return "$1-$2-$3";
    }

    # Y/m/d
    if ($value =~ /^(\d{4})\/(\d{2})\/(\d{2})$/ ) {
        return "$1-$2-$3";
    }

    # d/m/Y
    if ($value =~ /^(\d{2})\/(\d{2})\/(\d{4})$/ ) {
        return "$3-$2-$1";
    }
}

1;
