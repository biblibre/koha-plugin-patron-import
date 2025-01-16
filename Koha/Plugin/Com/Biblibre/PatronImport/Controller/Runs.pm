package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Info qw(GetImportName);

sub index {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/runs/index.tt' });

    my $import_id = $cgi->param('import_id');

    my $runs = GetFromTable(
        $plugin->{runs_table},
        { import_id => $import_id },
        'ORDER BY end DESC'
    );

    foreach my $run ( @$runs ) {
        $run->{total} = $run->{new} + $run->{updated} + $run->{skipped} + $run->{error};
    }

    $template->param(
        import_id   => $import_id,
        import_name => GetImportName($import_id),
        runs        => $runs
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub details {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/runs/details.tt' });

    my $id = $cgi->param('id');

    my $runs = GetFromTable( $plugin->{runs_table}, { id => $id, } );
    my $rows = GetFromTable( $plugin->{run_stats_table}, { run_id => $id, } );

    my $tmp_stats;
    foreach my $row ( @$rows ) {
        unless ( defined( $tmp_stats->{ $row->{field} } ) ) {
            $tmp_stats->{ $row->{field} } = [];
        }
        push @{ $tmp_stats->{ $row->{field} } }, {
            value => $row->{value},
            count => $row->{count}
        };
    }


    my $stats = [];
    foreach my $field ( keys %$tmp_stats ) {
        push @{ $stats }, {
            field => $field,
            data => $tmp_stats->{ $field }
        };
    }

    $template->param(
        id          => $id,
        stats       => $stats,
        import_id   => $runs->[0]->{import_id},
        import_name => GetImportName( $runs->[0]->{import_id} ),
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub logs {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/runs/logs.tt' });

    my $error_checked = 1;
    my $info_checked = 1;
    my $success_checked = 1;

    my $id = $cgi->param('id');
    my $op = $cgi->param('op') || '';

    my $additional = '';
    if ( $op eq 'filter' ) {
        my $e = $cgi->param('error');
        my $i = $cgi->param('info');
        my $s = $cgi->param('success');

        $error_checked = 0;
        $info_checked = 0;
        $success_checked = 0;

        my @in;
        if ( $e eq 'on' ) {
             $error_checked = 1;
             push @in, "'error'";
        }

        if ( $i eq 'on' ) {
             $info_checked = 1;
             push @in, "'info'";
        }

        if ( $s eq 'on' ) {
             $success_checked = 1;
             push @in, "'success'";
        }

        if ( @in ) {
            $additional = " AND reason IN (" . join(', ', @in) . ")";
        }
    }

    my $runs = GetFromTable( $plugin->{runs_table}, { id => $id, } );
    my $logs = GetFromTable( $plugin->{run_logs_table}, { run_id => $id, },
        "$additional ORDER BY time" );

    $template->param(
        id              => $id,
        import_id       => $runs->[0]->{import_id},
        import_name     => GetImportName( $runs->[0]->{import_id} ),
        logs            => $logs,
        error_checked   => $error_checked,
        info_checked    => $info_checked,
        success_checked => $success_checked
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub delete {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/runs/delete.tt' });

    my $id = $cgi->param('id');
    my $op = $cgi->param('op') || '';

    my $runs = GetFromTable( $plugin->{runs_table}, { id => $id, } );

    if ( $op eq 'delete_confirm' ) {
        Delete( $plugin->{runs_table}, { id => $id } );
        Delete( $plugin->{patrons_history_table}, { run_id => $id } );

        my $import_id = $cgi->param('import_id');
        print $cgi->redirect("/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=showruns&import_id=$import_id");
    }

    $template->param(
        id          => $id,
        import_id   => $runs->[0]->{import_id},
        import_name => GetImportName( $runs->[0]->{import_id} ),
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub batchdelete {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $import_id = $cgi->param('import_id');
    my @ids = $cgi->multi_param('delete');
    foreach my $id ( @ids ) {
        Delete( $plugin->{runs_table}, { id => $id } );
        Delete( $plugin->{patrons_history_table}, { run_id => $id } );
    }

    print $cgi->redirect("/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=showruns&import_id=$import_id");
}

1;
