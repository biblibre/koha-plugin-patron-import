package Koha::Plugin::Com::Biblibre::PatronImport::Helper::MessagePreferences;

use Modern::Perl;
use Exporter;

use C4::Members::Messaging;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_conf);

sub set {
    my ($borrowernumber, $patron) = @_;

    unless ($patron->{categorycode}) {
        return;
    }

    unless ($borrowernumber) {
        return;
    }

    my $messaging_options = C4::Members::Messaging::GetMessagingOptions();

    foreach my $option ( @$messaging_options ) {
        my $pref = C4::Members::Messaging::GetMessagingPreferences( { ( categorycode => $patron->{categorycode} ), message_name => $option->{'message_name'} } );

        my @transports = keys %{ $pref->{transports} };

        my $params = {
            borrowernumber => $borrowernumber,
            message_attribute_id => $option->{message_attribute_id},
            message_transport_types => \@transports,
            days_in_advance => $pref->{days_in_advance},
            wants_digest => $pref->{wants_digest} ? 1 : 0,
        };

        C4::Members::Messaging::SetMessagingPreference($params);
    }
}
1;
