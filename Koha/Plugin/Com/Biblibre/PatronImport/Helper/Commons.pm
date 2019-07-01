package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    PatronFields
);

use Modern::Perl;

use C4::Context;

use Koha::Patrons;
use Koha::Patron::Attribute::Types;

sub PatronFields {
    my ( $want_extended_attr ) = @_;

    my @fields;

    my @columns = map { { code => $_, description => $_} } Koha::Patrons->columns;

    return \@columns unless $want_extended_attr;

    my @attribute_types = map { { code => $_->code, description => $_->description } } Koha::Patron::Attribute::Types->search();
    push @columns, @attribute_types;

    return \@columns;
}

1;
