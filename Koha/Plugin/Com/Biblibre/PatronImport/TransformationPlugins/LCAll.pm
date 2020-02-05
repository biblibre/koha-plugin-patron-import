package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LCAll;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    return lc($value);
}

1;
