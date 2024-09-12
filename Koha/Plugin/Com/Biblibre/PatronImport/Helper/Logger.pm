package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Logger;

use Modern::Perl;
use DateTime;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

sub new {
    my ( $class, $import_id, $config ) = @_;

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new({
        enable_plugins  => 1,
    });

    my $self = {
        import_id => $import_id,
        plugin => $plugin,
        info_logs => $config->{info_logs} || 0,
        success_logs => $config->{success_log} || 0,
        dry_run => $config->{dry_run} || 0,
        config => $config,
        stats => {
            new => 0,
            updated => 0,
            deleted => 0,
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
       {   import_id => $self->{import_id},
            start     => $now->ymd . ' ' . $now->hms,
            new       => 0,
            updated   => 0,
            deleted   => 0,
            skipped   => 0,
            error     => 0,
            dry_run   => $self->{dry_run}
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
            deleted => $self->{stats}{deleted} ,
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

    $self->clear;
}

sub clear {
    my ( $self ) = @_;

    my $interval = $self->{config}{clear_logs};
    my $run_table = $self->{plugin}{runs_table};
    my $patrons_history_table = $self->{plugin}{patrons_history_table};

    my $dbh = C4::Context->dbh;

    $dbh->do("DELETE FROM $run_table WHERE DATE(start) < CURDATE() - INTERVAL $interval DAY;");
    $dbh->do("DELETE FROM $patrons_history_table WHERE DATE(action_date) < CURDATE() - INTERVAL $interval DAY;");
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

    if ($reason eq 'info' && $self->{info_logs} == 0) {
        return;
    }

    if ($reason eq 'success' && $self->{success_logs} == 0) {
        return;
    }

    my $now = DateTime->now( time_zone => 'local' );
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
