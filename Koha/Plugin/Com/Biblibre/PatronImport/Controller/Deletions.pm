package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Deletions;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( PatronFields );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Info qw( GetImportName );

sub edit {
    my ( $plugin, $params ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $import_id = $cgi->param('import_id');
    my $op = $cgi->param('op');

    my $template = $plugin->get_template({ file => 'templates/deletions/edit.tt' });

    if ( $op eq 'delete_field' ) {
        my $field_id = $cgi->param('field_id');
        Delete($plugin->{deletions_fields_table}, { id => $field_id });
    }

    if ( $op eq 'add_field' ) {
        my $rule_id = $cgi->param('rule_id');
        my $koha_field = $cgi->param('koha_field');
        my $field_value = $cgi->param('field_value');

        InsertInTable(
            $plugin->{deletions_fields_table},
            {
                rule_id      => $rule_id,
                field   => $koha_field,
                value        => $field_value
            }
        );
    }

    if ( $op eq 'delete_rule' ) {
        my $rule_id = $cgi->param('rule_id');
        Delete($plugin->{deletions_rules_table}, { id => $rule_id });
    }

    if ( $op eq 'add_rule' ) {
        my $name = $cgi->param('name');

        InsertInTable(
            $plugin->{deletions_rules_table},
            {
                name      => $name,
                import_id => $import_id
            }
        );
    }

    my $rules = GetFromTable($plugin->{deletions_rules_table}, { import_id => $import_id});
    foreach my $rule (@$rules) {
        $rule->{fields} = [];
        my $fields = GetFromTable($plugin->{deletions_fields_table}, { rule_id => $rule->{id}});
        if ($fields) {
            $rule->{fields} = $fields;
        }
    }

    my $columns = PatronFields();

    $template->param(
        import_id   => $import_id,
        import_name => GetImportName($import_id),
        rules       => $rules,
        columns     => $columns,
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

1;
