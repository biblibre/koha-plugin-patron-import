package Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron::ExtendedAttributes;

use Modern::Perl;
use Exporter;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons;

our @ISA = qw( Exporter );

our $VERSION = 2.0;

our @EXPORT = qw(
    is_xattr
    xattr_to_protect
);

my @attributes;

sub is_xattr {
    my $xattr = shift;

    unless (@attributes) {
        @attributes = map $_->{"code"}, C4::Members::AttributeTypes::GetAttributeTypes;
    }

    return 1 if in_array(\@attributes, $xattr);

    return 0;
}

sub xattr_to_protect {
    my ( $borrowernumber, $attr_code ) = @_;

    my $dbh = C4::Context->dbh;
    my $query = "SELECT attribute FROM borrower_attributes WHERE borrowernumber=? AND code=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($borrowernumber, $attr_code);
    my $result = $sth->fetchrow_array;

    return 1 if is_set($result);
    return 0;
}

1;
