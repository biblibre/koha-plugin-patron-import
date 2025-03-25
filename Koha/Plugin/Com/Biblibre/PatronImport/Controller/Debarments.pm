package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Debarments;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Info qw(GetImportName);

sub edit {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/debarments/edit.tt' });

    my $op = $cgi->param('op') || '';

    my $import_id = $cgi->param('import_id');
    $template->param(
        import_id   => $import_id,
        import_name => GetImportName($import_id)
    );

    if ( $op eq 'cud-save' ) {
        my $values;
        $values->{suspend} = $cgi->param('suspend') ? 1 : 0;
        $values->{comment} = $cgi->param('comment');
        $values->{days} = $cgi->param('duration') || 0;
        $values->{unlimited} = $cgi->param('unlimited') ? 1 : 0;

        if (my $existing = GetFirstFromTable(
                $plugin->{debarments_table},
                { import_id => $import_id } )) {
            UpdateInTable($plugin->{debarments_table},
                $values,
                { import_id => $existing->{import_id} });
            print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
            return;
        }

        $values->{import_id} = $import_id;
        InsertInTable($plugin->{debarments_table}, $values);
        print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
        return;
    }

    my $debarment = GetFirstFromTable($plugin->{debarments_table}, { import_id => $import_id });
    $template->param(
        suspend     => $debarment->{suspend},
        comment     => $debarment->{comment},
        days        => $debarment->{days},
        unlimited   => $debarment->{unlimited}
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

1;
