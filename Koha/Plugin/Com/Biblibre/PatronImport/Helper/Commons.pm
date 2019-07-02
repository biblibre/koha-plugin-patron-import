package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    PatronFields
    in_array
    valid_field
    is_set
    is_empty
);

use Modern::Perl;

use C4::Context;
use C4::Members::AttributeTypes;

use Koha::Patrons;
use Koha::Patron::Attribute::Types;

my $borrowers_fields;

BEGIN {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->column_info(undef, undef, 'borrowers', '%');
    $sth->execute;
    $borrowers_fields = $sth->fetchall_hashref('COLUMN_NAME');
}

sub PatronFields {
    my ( $want_extended_attr ) = @_;

    my @fields;

    my @columns = map { { code => $_, description => $_} } Koha::Patrons->columns;

    return \@columns unless $want_extended_attr;

    my @attribute_types = map { { code => $_->code, description => $_->description } } Koha::Patron::Attribute::Types->search();
    push @columns, @attribute_types;

    return \@columns;
}

# Return 1 if the field is a column of borrowers table,
# return 2 if it is an extended attributes,
# else return 0.
sub valid_field {
    my ($field) = @_;

    return 1 if defined($borrowers_fields->{$field});

    my @attributes = map $_->{"code"}, C4::Members::AttributeTypes::GetAttributeTypes;
    return 2 if in_array(\@attributes, $field);
    return 0;
}

sub in_array {
    my ($arr, $search_for) = @_;

    my %items = map {$_ => 1} @$arr;

    return exists $items{$search_for};
}

sub is_empty {
    my ($value) = @_;

    if (!defined($value)) {
        return 1;
    }

    if ($value eq '') {
        return 1;
    }

    return 0;
}

sub is_set {
    my ($value) = @_;

    if (!defined($value)) {
        return 0;
    }

    if ($value eq '') {
        return 0;
    }

    return 1;
}

1;
