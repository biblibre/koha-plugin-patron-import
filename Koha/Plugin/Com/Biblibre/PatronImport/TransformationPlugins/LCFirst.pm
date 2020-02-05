package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LCFirst;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    return lcfirst($value);
}

1;
