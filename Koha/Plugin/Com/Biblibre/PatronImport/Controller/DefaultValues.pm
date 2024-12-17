package Koha::Plugin::Com::Biblibre::PatronImport::Controller::DefaultValues;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( PatronFields );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Info qw( GetImportName );

sub edit {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{cgi};

    my $template = $plugin->get_template({ file => 'templates/defaultValues/edit.tt' });

    my $import_id = $cgi->param('import_id');
    my $op = $cgi->param('op');

    if ( $op eq 'save' ) {
        my $value = $cgi->param('value');
        my $is_error = 0;
        if ( $value ) {
            my $koha_field = $cgi->param('koha_field');
            eval {
                InsertInTable(
                    $plugin->{default_values_table},
                    {
                        import_id => $import_id,
                        koha_field => $koha_field,
                        value => $value
                    }
                );
            };
            if ( $@ ) {
                $template->param( error => $@ );
            }
        } else {
            $template->param( error => 'Value cannot be empty' );
        }
    }

    if ( $op eq 'delete' ) {
        my $koha_field = $cgi->param('koha_field');
        eval {
            Delete($plugin->{default_values_table},
                {
                    import_id => $import_id,
                    koha_field => $koha_field
                });
        };
        if ( $@ ) {
            $template->param( error => $@ );
        }
    }

    my $columns = PatronFields(0);
    my $defaults = GetFromTable($plugin->{default_values_table}, { import_id => $import_id});

    $template->param(
        import_id   => $import_id,
        import_name => GetImportName($import_id),
        columns     => $columns,
        defaults    => $defaults
    );

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

1;
