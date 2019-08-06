package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Logger;

use Modern::Perl;
use DateTime;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

sub new {
    my ( $class, $import_id ) = @_;

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new({
        enable_plugins  => 1,
    });

    my $self = {
        import_id => $import_id,
        plugin => $plugin,
        stats => {
            new => 0,
            updated => 0,
            skipped => 0,
            error => 0,
            fields => {}
        }
    };

    return( bless $self, $class );
}

sub InitRun {
    my ( $self ) = @_;

    my $now = DateTime->now( time_zone => 'local' );
    my $run_id = InsertInTable(
        $self->{plugin}{runs_table},
        {
            import_id   => $self->{import_id},
            start       => $now->ymd . ' ' . $now->hms,
            new         => 0,
            updated     => 0,
            skipped     => 0,
            error       => 0
        }
    );

    $self->{run_id} = $run_id;

    return $self;
}

sub Stop {
    my ( $self ) = @_;

    my $now = DateTime->now( time_zone => 'local' );
    UpdateInTable(
        $self->{plugin}{runs_table},
        {
            end     => $now->ymd . ' ' . $now->hms,
            new     => $self->{stats}{new},
            updated => $self->{stats}{updated} ,
            skipped => $self->{stats}{skipped},
            error   => $self->{stats}{error}
        },
        {
            id => $self->{run_id}
        }
    );

    my $field_stats = $self->{stats}{fields};
    foreach my $field ( qw/ branchcodes categorycodes / ) {
        foreach my $value ( keys %{ $field_stats->{ $field } } ) {
            InsertInTable(
                $self->{plugin}{run_stats_table},
                {
                    run_id  => $self->{run_id},
                    field   => $field,
                    value   => $value,
                    count   => $field_stats->{ $field }{ $value }
                }
            );
        }
    }
}

sub Extractstats {
    my ( $self, $borrower ) = @_;

    $self->{stats}{ $borrower->{status} }++;

    # The rest of statistics is only for non-skipped patrons.
    return if $borrower->{status} eq 'skipped';

    $self->{stats}{fields}{branchcodes}{ $borrower->{branchcode} || '_UNDEF_' }++;
    $self->{stats}{fields}{categorycodes}{ $borrower->{categorycode} || '_UNDEF_' }++;

    return $self;
}

sub Add {
    my ( $self, $reason, $message, $borrowernumber, $patron ) = @_;

    my $now = DateTime->now;
    my $userid = $patron->{userid} || 'Unknown';
    my $cardnumber = $patron->{cardnumber} || 'Unknown';
    my $surname = $patron->{surname} || '';
    my $firstname = $patron->{firstname} || '';

    InsertInTable(
        $self->{plugin}{run_logs_table},
        {
            run_id          => $self->{run_id},
            time            => $now->ymd . ' ' . $now->hms,
            reason          => $reason,
            message         => $message,
            borrowernumber  => $borrowernumber,
            userid          => $userid,
            cardnumber      => $cardnumber,
            surname         => $surname,
            firstname       => $firstname
        }
    );
}

1;
