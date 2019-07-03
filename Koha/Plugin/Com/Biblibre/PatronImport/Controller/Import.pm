package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import;

use Modern::Perl;

use JSON qw( to_json from_json );

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig qw( :DEFAULT );

sub edit {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/import/edit.tt' });

    my $op = $cgi->param('op') || '';

    my  $flow_types = [
        { code => 'file-csv', name => 'CSV file'},
        { code => 'ldap', name => 'LDAP connection'},
    ];

    $template->param(
        import_types => $flow_types,
        supported_eol => SupportedEOL(),
        supported_quote_char => SupportedQuoteChar(),
        supported_sep_char => SupportedSepChar(),
    );

    if ( $op eq 'save' ) {
        my $id = $cgi->param('id');
        my $name = $cgi->param('name');
        my $type = $cgi->param('type');
        my $createonly = $cgi->param('createonly') ? 1 : 0;
        my $autocardnumber = $cgi->param('autocardnumber');
        my $flow_settings = _handle_flow_settings($cgi);
        my $values = {
            name => $name,
            type => $type,
            createonly => $createonly,
            autocardnumber => $autocardnumber,
            flow_settings => $flow_settings
        };

        if (my $existing = GetFirstFromTable( $plugin->{import_table}, { id => $id } )) {
            UpdateInTable($plugin->{import_table}, $values, { id => $existing->{id} });
            print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
            return;
        }

        my $now = DateTime->now();
        $values->{created_on} = $now->ymd() . ' ' . $now->hms;
        InsertInTable($plugin->{import_table}, $values);

        print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
    }

    my $id = $cgi->param('id');
    if ( $id ) {
        my $import = GetFirstFromTable($plugin->{import_table}, { id => $id });

        my $flow_settings = from_json($import->{flow_settings}) if $import->{flow_settings};
        $template->param(
            id => $import->{id},
            name => $import->{name},
            type => $import->{type},
            createonly => $import->{createonly},
            autocardnumber => $import->{autocardnumber},
            %{ $flow_settings }
        );
    }

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub delete {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{'cgi'};

    my $id = $cgi->param('id');
    my $op = $cgi->param('op') || '';

    if ( $op eq 'confirm' ) {
        if (my $existing = GetFirstFromTable( $plugin->{import_table}, { id => $id } )) {
            Delete( $plugin->{import_table}, { id => $existing->{id} });
        }
        print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
    }

    my $template = $plugin->get_template({ file => 'templates/import/delete.tt' });

    my $existing = GetFirstFromTable( $plugin->{import_table}, { id => $id } );

    $template->param(
        todelete => $existing,
        id => $id
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub _handle_flow_settings {
    my ( $cgi ) = @_;

    if ( $cgi->param('type') eq 'file-csv' ) {
        return _handle_csv($cgi);
    }
}

sub _handle_csv {
    my ( $cgi ) = @_;

    my $settings = {
        binary              => $cgi->param('binary') ? 1 : 0,
        eol                 => $cgi->param('eol') || "",
        sep_char            => $cgi->param('sep_char') || "",
        quote_char          => $cgi->param('quote_char') || "",
        empty_is_undef      => $cgi->param('empty_is_undef') ? 1 : 0,
        allow_loose_quotes  => $cgi->param('allow_loose_quotes') ? 1 : 0,
    };

    return to_json($settings);
}

1;
