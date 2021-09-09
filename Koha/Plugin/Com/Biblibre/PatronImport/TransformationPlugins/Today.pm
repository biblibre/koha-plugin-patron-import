package Koha::Plugin::Com::Biblibre::PatronImport::TransformationPlugins::Today;

use Modern::Perl;
use DateTime qw();

sub transform {
    my ($value) = @_;

    return DateTime->now->strftime('%Y-%m-%d');
}

1;
