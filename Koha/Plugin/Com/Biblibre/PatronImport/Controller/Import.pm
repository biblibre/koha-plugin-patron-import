package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import;

use Modern::Perl;

use JSON qw( to_json from_json );

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins;

sub edit {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/import/edit.tt' });

    my $op = $cgi->param('op') || '';

    my  $flow_types = [
        { code => 'file-csv', name => 'CSV file'},
        { code => 'ldap', name => 'LDAP server'},
    ];

    my $available_plugins = Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins::get_candidates();

    $template->param(
        import_types => $flow_types,
        supported_eol => SupportedEOL(),
        supported_quote_char => SupportedQuoteChar(),
        supported_sep_char => SupportedSepChar(),
    );

    if ( $op eq 'cud-save' ) {
        my $id = $cgi->param('id');
        my $name = $cgi->param('name');
        my $type = $cgi->param('type');
        my $createonly = $cgi->param('createonly') ? 1 : 0;
        my $autocardnumber = $cgi->param('autocardnumber');
        my $welcome_message = $cgi->param('welcome_message') ? 1 : 0;
        my $clear_logs = $cgi->param('clear_log_older_than');
        my $flow_settings = _handle_flow_settings($cgi);

        my @plugins_enabled;
        foreach my $plugin_name ( keys %$available_plugins ) {
            my $plugin_class = $available_plugins->{$plugin_name}{class};
            my $enabled = $cgi->param($plugin_class);

            if ($enabled) {
                push @plugins_enabled, $plugin_class;
            }
        }

        my $values = {
            name => $name,
            type => $type,
            createonly => $createonly,
            autocardnumber => $autocardnumber,
            welcome_message => $welcome_message,
            clear_logs => $clear_logs,
            flow_settings => $flow_settings,
            plugins_enabled => join(',', @plugins_enabled)
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

        my @plugin_enabled = split(',', $import->{plugins_enabled});
        foreach my $name ( keys %$available_plugins ) {
            if ( grep $_ eq $available_plugins->{ $name }{class}, @plugin_enabled ) {
                $available_plugins->{ $name }{enabled} = 1;
            }
        }

        my $flow_settings = from_json($import->{flow_settings}) if $import->{flow_settings};
        $template->param(
            id => $import->{id},
            name => $import->{name},
            type => $import->{type},
            createonly => $import->{createonly},
            autocardnumber => $import->{autocardnumber},
            welcome_message => $import->{welcome_message},
            clear_logs => $import->{clear_logs},
            %{ $flow_settings }
        );
    }

    $template->param(
        available_plugins => $available_plugins
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

sub delete {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{'cgi'};

    my $id = $cgi->param('id');
    my $op = $cgi->param('op') || '';

    if ( $op eq 'cud-confirm' ) {
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

    if ($cgi->param('type') eq 'ldap' ) {
        return _handle_ldap($cgi);
    }
}

sub _handle_csv {
    my ( $cgi ) = @_;

    my $settings = {
        file_path           => $cgi->param('file_path') || '',
        binary              => $cgi->param('binary') ? 1 : 0,
        eol                 => $cgi->param('eol') || "",
        sep_char            => $cgi->param('sep_char') || "",
        quote_char          => $cgi->param('quote_char') || "",
        allow_loose_quotes  => $cgi->param('allow_loose_quotes') ? 1 : 0,
    };

    return to_json($settings);
}

sub _handle_ldap {
    my ( $cgi ) = @_;

    my $settings = {
        ldap_host           => $cgi->param('ldap_host') || '',
        anonymous_bind      => $cgi->param('anonymous_bind') ? 1 : 0,
        ldap_user           => $cgi->param('ldap_user') || "",
        ldap_pass           => $cgi->param('ldap_pass') || "",
        search_base         => $cgi->param('search_base') || "",
        search_filter       => $cgi->param('search_filter') || "",
    };

    return to_json($settings);
}

1;
