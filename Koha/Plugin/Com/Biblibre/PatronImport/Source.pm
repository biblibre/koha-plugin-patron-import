package Koha::Plugin::Com::Biblibre::PatronImport::Source;

use Modern::Perl;

sub new {
    my ($class, $plugin) = @_;

    my $origin = $plugin->{config}{setup}{'flow-type'};

    my $in;
    if ( $origin eq 'file-csv' ) {
        use Koha::Plugin::Com::Biblibre::PatronImport::Source::File::CSV;
        $in = Koha::Plugin::Com::Biblibre::PatronImport::Source::File::CSV->in($plugin);
    }
    elsif ( $origin eq 'file-xml' ) {
        use Koha::Plugin::Com::Biblibre::PatronImport::Source::File::XML;
        $in = Koha::Plugin::Com::Biblibre::PatronImport::Source::File::XML->in($plugin);
    }
    elsif ( $origin eq 'ldap' ) {
        use Koha::Plugin::Com::Biblibre::PatronImport::Source::Ldap;
        $in = Koha::Plugin::Com::Biblibre::PatronImport::Source::Ldap->in($plugin);
    }
    else {
        die "Unknown source type \"$origin\"";
    }


    my $this = {
        origin  => $origin,
        in      => $in
    };

    return bless $this, $class;
}

sub next {
    my $self = shift;

    return $self->{in}->next;
}

1;
