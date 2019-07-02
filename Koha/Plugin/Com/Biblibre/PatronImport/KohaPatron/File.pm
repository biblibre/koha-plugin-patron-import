package Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron::File;

use Modern::Perl;
use Koha::Plugin::Com::Biblibre::PatronImport::KohaPatron;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Mapping;
use YAML;
use LWP::UserAgent;

sub in {
    my ( $class, $import ) = @_;

    my $fh;
    my $flow = $import->{setup}{'flow-type'};
    my $from = $import->{from};

    # Open a local file.
    open $fh, "<:encoding(utf8)", "$from" or die "Can't open $from";

    my $this = {
        fh          => $fh,
        import      => $import,
        header      => 0,
    };

    return( bless $this, $class );

}

sub next {
    my $this = shift;
    $this->{patronnum}++;
    my $patron = $this->_next() or return;
    return process_mapping($patron);
}

1;
