package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::LeftTrim;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    $value =~ s/^\s+//;
    return $value;
}

1;
