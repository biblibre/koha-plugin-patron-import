package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::UCFirst;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    return ucfirst($value);
}

1;
