package Koha::Plugin::Com::Biblibre::PatronImport::Helper::History;

use Modern::Perl;
use DateTime;
use C4::Context;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

sub new {
    my ( $class, $logger ) = @_;

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new( { enable_plugins => 1, } );

    my $self = {
        logger => $logger,
        plugin => $plugin
    };

    return ( bless $self, $class );
}

sub is_created {
    my ( $self, $borrowernumber ) = @_;

    $self->_save( 'created', $borrowernumber );
}

sub is_updated {
    my ( $self, $borrowernumber ) = @_;

    $self->_save( 'updated', $borrowernumber );
}

sub is_deleted {
    my ( $self, $borrowernumber ) = @_;

    $self->_save( 'deleted', $borrowernumber );
}

sub _save {
    my ( $self, $action, $borrowernumber ) = @_;

    #my $patrons_hitory_table = $self->get_qualified_table_name('patrons_history');

    my $now = DateTime->now( time_zone => 'local' );

    InsertInTable(
        $self->{plugin}{patrons_history_table},
        {   run_id         => $self->{logger}{run_id},
            borrowernumber => $borrowernumber,
            action         => $action,
            action_date    => $now->ymd . ' ' . $now->hms,
        }
    );
}

1;
