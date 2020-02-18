package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::UCFirst;

use Modern::Perl;

sub transform {
    my ($value) = @_;

    $value =~ s/([\w']+)/\u\L$1/g;

    return $value;
}

1;
