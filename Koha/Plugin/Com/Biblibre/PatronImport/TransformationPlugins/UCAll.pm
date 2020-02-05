package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::UCAll;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    return uc($value);
}

1;
