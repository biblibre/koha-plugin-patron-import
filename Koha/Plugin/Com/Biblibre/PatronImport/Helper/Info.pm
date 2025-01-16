package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Info;

use Modern::Perl;
use C4::Context;
use Exporter;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( GetFirstFromTable );

our @ISA    = qw(Exporter);
our @EXPORT = qw(GetImportName);

sub GetImportName {
    my ($import_id) = @_;
    my $plugin    = Koha::Plugin::Com::Biblibre::PatronImport->new( { enable_plugins => 1, } );
    my $import = GetFirstFromTable($plugin->{import_table}, { id => $import_id });

    return $import->{name} || '';
}

1;