package Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Commons qw( PatronFields );

sub edit {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{cgi};

    my $template = $plugin->get_template({ file => 'templates/fieldMappings/edit.tt' });

    my $import_id = $cgi->param('import_id');
    my $op = $cgi->param('op') || '';

    if ( $op eq 'save' ) {
        # Save mappings
        my @source_fields = $cgi->param('source_field');
        my @koha_fields = $cgi->param('koha_field');
        my $is_error = 0;
        eval {
            Delete($plugin->{field_mappings_table}, { import_id => $import_id });

            for my $i ( 0 .. scalar(@source_fields) - 1 ) {
                my $source_field = $source_fields[$i];
                my $koha_field = $koha_fields[$i];

                InsertInTable(
                    $plugin->{field_mappings_table},
                    {
                        import_id => $import_id,
                        source => $source_field,
                        destination => $koha_field
                    }
                );

            }
        };
        if ( $@ ) {
            $template->param( error => $@ );
            $is_error = 1;
        }

        # Save matching points
        my @matching_points = $cgi->param('matching_points');
        eval {
            Delete($plugin->{matching_points_table}, { import_id => $import_id });

            foreach my $point ( @matching_points ) {
                InsertInTable(
                    $plugin->{matching_points_table},
                    {
                        import_id => $import_id,
                        field => $point
                    }
                );
            }
        };
        if ( $@ ) {
            $template->param( error => $@ );
            $is_error = 1;
        }

        unless ( $is_error ) {
            print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
            return;
        }
    }

    my $mappings = GetFromTable($plugin->{field_mappings_table}, { import_id => $import_id});

    foreach my $m ( @$mappings ) {
        $m->{count} = Count($plugin->{value_mappings_table},
            { import_id => $import_id, destination => $m->{destination} });
    }

    my $matching_points = GetFromTable($plugin->{matching_points_table},
        { import_id => $import_id});

    my $columns = PatronFields(1);

    $template->param(
        import_id => $import_id,
        mappings => $mappings,
        matching_points => $matching_points,
        columns => $columns
    );

    print $cgi->header();
    print $template->output();
}

sub editvalues {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{cgi};

    my $template = $plugin->get_template({ file => 'templates/fieldMappings/editvalues.tt' });

    my $import_id = $cgi->param('import_id');
    my $destination = $cgi->param('destination');
    my $op = $cgi->param('op') || '';

    if ( $op eq 'save' ) {
        my @input_values = $cgi->param('input');
        my @output_values = $cgi->param('output');
        my $is_error = 0;
        eval {
            Delete($plugin->{value_mappings_table},
                { import_id => $import_id, destination => $destination });
            for my $i ( 0 .. scalar(@input_values) - 1 ) {
                my $input_value = $input_values[$i];
                my $output_value = $output_values[$i];

                InsertInTable(
                    $plugin->{value_mappings_table},
                    {
                        import_id => $import_id,
                        destination => $destination,
                        input => $input_value,
                        output => $output_value
                    }
                );
            }
        };
        if ( $@ ) {
            $template->param( error => $@ );
            $is_error = 1;
        }

        unless ( $is_error ) {
            print $cgi->redirect("/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=editfieldmappings&import_id=$import_id");
            return;
        }
    }

    my $mappings = GetFromTable($plugin->{value_mappings_table},
        { import_id => $import_id, destination => $destination });

    $template->param(
        import_id => $import_id,
        mappings => $mappings,
        destination => $destination
    );

    print $cgi->header();
    print $template->output();
}

sub editprotected {
    my ($plugin, $params) = @_;
    my $cgi = $plugin->{cgi};

    my $template = $plugin->get_template({ file => 'templates/fieldMappings/editprotected.tt' });

    my $import_id = $cgi->param('import_id');
    my $op = $cgi->param('op') || '';

    if ( $op eq 'save' ) {
        # Save protected fields.
        my @protected = $cgi->multi_param('protected');
        my $is_error = 0;
        eval {
            Delete($plugin->{protected_table}, { import_id => $import_id });

            foreach my $p ( @protected ) {
                InsertInTable(
                    $plugin->{protected_table},
                    {
                        import_id => $import_id,
                        field => $p
                    }
                );
            }
        };
        if ( $@ ) {
            $template->param( error => $@ );
            $is_error = 1;
        }

        # Save erasable fields.
        my @erasables = $cgi->multi_param('erasable');
        eval {
            Delete($plugin->{erasables_table},
                { import_id => $import_id });

            foreach my $e ( @erasables ) {
                InsertInTable(
                    $plugin->{erasables_table},
                    {
                        import_id => $import_id,
                        field => $e
                    }
                );
            }
        };
        if ( $@ ) {
            $template->param( error => $@ );
            $is_error = 1;
        }

        unless ( $is_error ) {
            print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
            return;
        }
    }

    my $protectables = PatronFields(1);
    my $erasables = PatronFields(0);
    my $protected = GetFromTable($plugin->{protected_table},
        { import_id => $import_id});
    my $erased = GetFromTable($plugin->{erasables_table},
        { import_id => $import_id});

    $template->param(
        import_id => $import_id,
        protectables => $protectables,
        erasables => $erasables,
        protected => $protected,
        erased => $erased
    );

    print $cgi->header();
    print $template->output();
}

1;
