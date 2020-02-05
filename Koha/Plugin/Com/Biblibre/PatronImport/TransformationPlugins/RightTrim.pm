package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::RightTrim;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    $value =~ s/\s+$//;
    return $value;
}

1;
