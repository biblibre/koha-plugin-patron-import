package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;

use Modern::Perl;
use Exporter;
use YAML;
use JSON;
use C4::Context;
use DateTime;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

our @ISA    = qw(Exporter);
our @EXPORT = qw(get_conf set_conf);

my ( $conf, $tables );

sub load_conf {
    my ($import_id) = @_;

    $conf = _load_db_conf($import_id);
}

sub get_conf {
    return $conf;
}

sub _load_db_conf {
    my $import_id = shift;

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new( { enable_plugins => 1, } );

    $tables->{import_table}                 = $plugin->{import_table};
    $tables->{field_mappings_table}         = $plugin->{field_mappings_table};
    $tables->{value_mappings_table}         = $plugin->{value_mappings_table};
    $tables->{value_mappings_default_table} = $plugin->{value_mappings_default_table};
    $tables->{transformation_plugins_table} = $plugin->{transformation_plugins_table};
    $tables->{matching_points_table}        = $plugin->{matching_points_table};
    $tables->{protected_table}              = $plugin->{protected_table};
    $tables->{erasables_table}              = $plugin->{erasables_table};
    $tables->{default_values_table}         = $plugin->{default_values_table};
    $tables->{debarments_table}             = $plugin->{debarments_table};
    $tables->{exclusions_rules_table}       = $plugin->{exclusions_rules_table};
    $tables->{exclusions_fields_table}      = $plugin->{exclusions_fields_table};
    $tables->{deletions_rules_table}        = $plugin->{deletions_rules_table};
    $tables->{deletions_fields_table}       = $plugin->{deletions_fields_table};
    $tables->{extended_attributes_table}    = $plugin->{extended_attributes_table};

    my $conf;
    my ( $setup, $import_settings) = _load_setup($import_id);
    $conf->{setup} = $setup;
    $conf->{createonly} = $import_settings->{createonly} || 0;
    $conf->{autocardnumber} = $import_settings->{autocardnumber} || 'no';
    $conf->{welcome_message} = $import_settings->{welcome_message} || 0;
    $conf->{clear_logs} = $import_settings->{clear_logs} || 5;
    $conf->{plugins_enabled} = $import_settings->{plugins_enabled};

    $conf->{map}                   = _load_field_mappings($import_id);
    $conf->{valuesmapping}         = _load_value_mappings($import_id);
    $conf->{valuesmapping_default} = _load_value_mappings_default($import_id);
    $conf->{transformationplugins} = _load_transformation_plugins($import_id);
    $conf->{matchingpoint}         = _load_matching_points($import_id);
    $conf->{default}               = _load_default($import_id);
    $conf->{protected}             = _load_protected($import_id);
    $conf->{erasable}              = _load_erasables($import_id);
    $conf->{debarments}            = _load_debarments($import_id);
    $conf->{exclusions}            = _load_exclusions($import_id);
    $conf->{deletions}             = _load_deletions($import_id);
    $conf->{extendedattributes}    = _load_extendedattributes($import_id);

    return $conf;
}

sub _load_field_mappings {
    my $import_id = shift;

    my $values = _get_table_values( $tables->{field_mappings_table}, $import_id );
    my $mappings;
    foreach my $m (@$values) {
        my $source = $m->{source};
        my $dest   = $m->{destination};

        if ( defined( $mappings->{$source} ) ) {
            if ( ref( $mappings->{$source} ) eq 'ARRAY' ) {
                push @{ $mappings->{$source} }, $dest;
                next;
            }

            my $old = $mappings->{$source};
            $mappings->{$source} = [];
            push @{ $mappings->{$source} }, $old;
            push @{ $mappings->{$source} }, $dest;
            next;
        }

        $mappings->{$source} = $dest;
    }

    return $mappings;
}

sub _load_value_mappings {
    my $import_id = shift;

    my $values = _get_table_values( $tables->{value_mappings_table}, $import_id );
    my $mappings;
    foreach my $m (@$values) {
        my $dest   = $m->{destination};
        my $input  = $m->{input};
        my $output = $m->{output};

        #$mappings->{$dest}{$input} = $output;
        $mappings->{$dest}{$input} = {
            output   => $output,
            operator => $m->{operator}
        };
    }

    return $mappings;
}

sub _load_value_mappings_default {
    my $import_id = shift;

    my $values = _get_table_values( $tables->{value_mappings_default_table}, $import_id );

    my $default = {};
    foreach my $v (@$values) {
        $default->{ $v->{destination} } = $v->{default_value};
    }

    return $default;
}

sub _load_transformation_plugins {
    my $import_id = shift;

    my $values = _get_table_values( $tables->{transformation_plugins_table}, $import_id );
    my $tr_plugins;
    foreach my $p (@$values) {
        my $dest = $p->{destination};
        my $name = $p->{transformation_plugin};
        push @{ $tr_plugins->{$dest} }, $name;
    }

    return $tr_plugins;
}

sub _load_matching_points {
    my $import_id = shift;

    my $values         = _get_table_values( $tables->{matching_points_table}, $import_id );
    my @matchingpoints = map { $_->{field} } @$values;

    return \@matchingpoints;
}

sub _load_default {
    my $import_id = shift;

    my $default;
    my $values = _get_table_values( $tables->{default_values_table}, $import_id );
    foreach my $v (@$values) {
        $default->{ $v->{koha_field} } = $v->{value};
    }

    return $default;
}

sub _load_setup {
    my $import_id = shift;

    my $setup = {};
    my $table = $tables->{import_table};
    my $dbh   = C4::Context->dbh;
    my $sth   = $dbh->prepare("SELECT * FROM $table WHERE id = ?");
    $sth->execute($import_id);

    my $values = $sth->fetchrow_hashref;

    my $plugins_enabled_value = $values->{plugins_enabled} // '';
    my @plugins_enabled       = split( ',', $plugins_enabled_value );
    $values->{plugins_enabled} = {};
    foreach my $plugin (@plugins_enabled) {
        $values->{plugins_enabled}{$plugin} = 1;
    }

    my $settings = from_json( $values->{flow_settings} );

    if ( $values->{type} eq 'file-csv' ) {
        $settings = Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig::FormatSettings($settings);
    }

    $setup->{ $values->{type} } = $settings;
    $setup->{'flow-type'} = $values->{type};

    return ( $setup, $values );
}

sub _load_protected {
    my $import_id = shift;
    my $table     = $tables->{protected_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT field FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my $protected = [];
    while ( my ($field) = $sth->fetchrow_array() ) {
        push @$protected, $field;
    }

    return $protected;
}

sub _load_erasables {
    my $import_id = shift;
    my $table     = $tables->{erasables_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT field FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my $protected = [];
    while ( my ($field) = $sth->fetchrow_array() ) {
        push @$protected, $field;
    }

    return $protected;
}

sub _load_debarments {
    my $import_id = shift;
    my $table     = $tables->{debarments_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE import_id = ?");
    $sth->execute($import_id);

    my $values = $sth->fetchrow_hashref;

    if ( $values->{unlimited} ) {
        $values->{expiration} = '';
        return $values;
    }

    if ( $values->{days} ) {
        my $today = DateTime->now( time_zone => 'local' );
        $today->add( days => $values->{days} );
        $values->{expiration} = $today->ymd;
    }

    return $values;
}

sub _load_exclusions {
    my $import_id    = shift;
    my $rules_table  = $tables->{exclusions_rules_table};
    my $fields_table = $tables->{exclusions_fields_table};

    my $exclusions_rules;

    my $rules = GetFromTable( $rules_table, { import_id => $import_id } );
    foreach my $rule (@$rules) {
        my $fields = GetFromTable( $fields_table, { rule_id => $rule->{id} } );
        if ($fields) {
            my $mappings = {
                origin    => $rule->{origin},
                rule_name => $rule->{name},
                fields    => {}
            };
            foreach my $field (@$fields) {
                $mappings->{fields}->{ $field->{koha_field} } = $field->{value};
            }
            push( @{$exclusions_rules}, $mappings );
        }
    }
    return $exclusions_rules;
}

sub _load_deletions {
    my $import_id    = shift;
    my $rules_table  = $tables->{deletions_rules_table};
    my $fields_table = $tables->{deletions_fields_table};

    my $deletions_rules;

    my $rules = GetFromTable( $rules_table, { import_id => $import_id } );
    foreach my $rule (@$rules) {
        my $fields = GetFromTable( $fields_table, { rule_id => $rule->{id} } );
        if ($fields) {
            my $mappings = {
                fields    => {},
                rule_name => $rule->{name},
            };
            foreach my $field (@$fields) {
                $mappings->{fields}->{ $field->{field} } = $field->{value};
            }
            push( @{$deletions_rules}, $mappings );
        }
    }
    return $deletions_rules;
}

sub _load_extendedattributes {
    my $import_id                 = shift;
    my $extended_attributes_table = $tables->{extended_attributes_table};
    my $extendedattributes        = GetFromTable( $extended_attributes_table, { import_id => $import_id } );

    my $conf_extendedattributes;
    foreach my $e (@$extendedattributes) {
        $conf_extendedattributes->{ $e->{code} } = $e;
    }

    return $conf_extendedattributes;
}

sub _get_table_values {
    my ( $table, $import_id ) = @_;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my @values;
    while ( my $v = $sth->fetchrow_hashref ) {
        push @values, $v;
    }

    return \@values;
}

sub set_conf {
    my ( $new_conf, $import_id ) = @_;
    my $plugin    = Koha::Plugin::Com::Biblibre::PatronImport->new( { enable_plugins => 1, } );
    my %new_setup = ( 'autocardnumber' => '', 'clear_logs' => '', 'createonly' => '', 'plugins_enabled' => '' );
    my $flow_type;
    my $flow_settings;

    if ( my $existing = GetFirstFromTable( $plugin->{import_table}, { id => $import_id } ) ) {
        _update_setup( $plugin->{import_table}, $new_conf, $import_id );
        _update_field_mappings( $plugin->{field_mappings_table}, $new_conf, $import_id );
        _update_value_mappings( $plugin->{value_mappings_table}, $new_conf, $import_id );
        _update_value_mappings_default( $plugin->{value_mappings_default_table}, $new_conf, $import_id );
        _update_transformation_plugins( $plugin->{transformation_plugins_table}, $new_conf, $import_id );
        _update_matching_points( $plugin->{matching_points_table}, $new_conf, $import_id );
        _update_default_values( $plugin->{default_values_table}, $new_conf, $import_id );
        _update_protected_values( $plugin->{protected_table}, $new_conf, $import_id );
        _update_erasables_values( $plugin->{erasables_table}, $new_conf, $import_id );
        _update_debarments_values( $plugin->{debarments_table}, $new_conf, $import_id );
        _update_exclusions_values( $plugin, $new_conf, $import_id );
        _update_deletions_values( $plugin, $new_conf, $import_id );
        _update_extendedattributes_values( $plugin->{extended_attributes_table}, $new_conf, $import_id );
    }
}

sub _update_setup {
    my ( $datatable, $new_conf, $import_id ) = @_;

    my %new_setup = ( 'autocardnumber' => '', 'clear_logs' => '', 'createonly' => '', 'plugins_enabled' => '' );
    my $flow_type;
    my $flow_settings;

    foreach my $conf_property ( keys %{$new_conf} ) {
        if ( exists $new_setup{$conf_property} ) {
            if ($conf_property eq 'plugins_enabled') {
                $new_setup{$conf_property} = join (',' , keys %{$new_conf->{$conf_property}});
            } else {
                $new_setup{$conf_property} = $new_conf->{$conf_property};
            }
        }
    }
    if ( exists $new_conf->{'setup'}->{'flow-type'} ) {
        $flow_type = $new_conf->{'setup'}->{'flow-type'};
        $new_setup{'type'} = $flow_type;
    }
    if ( exists $new_conf->{'setup'}->{$flow_type} ) {
        if ( $flow_type eq 'file-csv' ) {
            $flow_settings = Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig::UnformatSettings( $new_conf->{'setup'}->{$flow_type} );
        } else {
            $flow_settings = $new_conf->{'setup'}->{$flow_type};
        }
        $new_setup{'flow_settings'} = encode_json($flow_settings);
    }
    UpdateInTable( $datatable, \%new_setup, { id => $import_id } );
}

sub _update_field_mappings {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'map'} && ref( $new_conf->{'map'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $koha_field ( keys %{ $new_conf->{'map'} } ) {
            my %new_field_mappings;
            $new_field_mappings{'import_id'}   = $import_id;
            $new_field_mappings{'source'}      = $koha_field;
            $new_field_mappings{'destination'} = $new_conf->{'map'}->{$koha_field};
            InsertInTable( $datatable, \%new_field_mappings );
        }
    }
}

sub _update_value_mappings {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'valuesmapping'} && ref( $new_conf->{'valuesmapping'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $koha_field ( keys %{ $new_conf->{'valuesmapping'} } ) {
            my %new_value_mappings;
            $new_value_mappings{'import_id'}   = $import_id;
            $new_value_mappings{'destination'} = $koha_field;
            foreach my $input ( keys %{ $new_conf->{'valuesmapping'}->{$koha_field} } ) {
                $new_value_mappings{'input'}    = $input;
                $new_value_mappings{'output'}   = $new_conf->{'valuesmapping'}->{$koha_field}->{$input}->{'output'};
                $new_value_mappings{'operator'} = $new_conf->{'valuesmapping'}->{$koha_field}->{$input}->{'operator'};
                InsertInTable( $datatable, \%new_value_mappings );
            }

        }
    }
}

sub _update_value_mappings_default {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'valuesmapping_default'} && ref( $new_conf->{'valuesmapping_default'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $koha_field ( keys %{ $new_conf->{'valuesmapping_default'} } ) {
            my %new_value_mappings_default;
            $new_value_mappings_default{'import_id'}     = $import_id;
            $new_value_mappings_default{'destination'}   = $koha_field;
            $new_value_mappings_default{'default_value'} = $new_conf->{'valuesmapping_default'}->{$koha_field};
            InsertInTable( $datatable, \%new_value_mappings_default );
        }
    }
}

sub _update_transformation_plugins {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'transformationplugins'} && ref( $new_conf->{'transformationplugins'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $koha_field ( keys %{ $new_conf->{'transformationplugins'} } ) {
            my %new_transformation_plugins;
            $new_transformation_plugins{'import_id'}   = $import_id;
            $new_transformation_plugins{'destination'} = $koha_field;
            foreach my $transformation ( @{ $new_conf->{'transformationplugins'}->{$koha_field} } ) {
                $new_transformation_plugins{'transformation_plugin'} = $transformation;
                InsertInTable( $datatable, \%new_transformation_plugins );
            }

        }
    }
}

sub _update_matching_points {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'matchingpoint'} && ref( $new_conf->{'matchingpoint'} ) eq 'ARRAY' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $matching_point ( @{ $new_conf->{'matchingpoint'} } ) {
            InsertInTable( $datatable, { import_id => $import_id, field => $matching_point } );
        }
    }
}

sub _update_default_values {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'default'} && ref( $new_conf->{'default'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $koha_field ( keys %{ $new_conf->{'default'} } ) {
            my %new_default_values;
            $new_default_values{'import_id'}  = $import_id;
            $new_default_values{'koha_field'} = $koha_field;
            $new_default_values{'value'}      = $new_conf->{'default'}->{$koha_field};
            InsertInTable( $datatable, \%new_default_values );
        }
    }
}

sub _update_protected_values {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'protected'} && ref( $new_conf->{'protected'} ) eq 'ARRAY' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $matching_point ( @{ $new_conf->{'protected'} } ) {
            InsertInTable( $datatable, { import_id => $import_id, field => $matching_point } );
        }
    }
}

sub _update_erasables_values {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'erasable'} && ref( $new_conf->{'erasable'} ) eq 'ARRAY' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $matching_point ( @{ $new_conf->{'erasable'} } ) {
            InsertInTable( $datatable, { import_id => $import_id, field => $matching_point } );
        }
    }
}

sub _update_debarments_values {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'debarments'} && ref( $new_conf->{'debarments'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        delete( $new_conf->{'debarments'}{'expiration'} );
        $new_conf->{'debarments'}{'import_id'} = $import_id;
        InsertInTable( $datatable, $new_conf->{'debarments'} );
    }
}

sub _update_exclusions_values {
    my ( $plugin, $new_conf, $import_id ) = @_;

    my $rules_table   = $plugin->{exclusions_rules_table};
    my $fields_table  = $plugin->{exclusions_fields_table};
    my $rule_existing = GetFirstFromTable( $rules_table, { import_id => $import_id } );

    if ($rule_existing) {
        my $mapping_existing = GetFirstFromTable( $fields_table, { rule_id => $rule_existing->{id} } );
        Delete( $rules_table, { import_id => $import_id } );
        if ($mapping_existing) {
            Delete( $fields_table, { rule_id => $rule_existing->{id} } );
        }
    }
    if ( exists $new_conf->{'exclusions'} && ref( $new_conf->{'exclusions'} ) eq 'ARRAY' ) {
        foreach my $rule ( @{ $new_conf->{'exclusions'} } ) {
            my $id = InsertInTable( $rules_table, { 'name' => $rule->{rule_name}, 'origin' => $rule->{origin}, 'import_id' => $import_id } );
            foreach my $koha_field ( keys %{ $rule->{fields} } ) {
                my $field_params = {
                    'rule_id'    => $id,
                    'koha_field' => $koha_field,
                    'value'      => $rule->{fields}{$koha_field},
                };
                InsertInTable( $fields_table, $field_params );
            }
        }
    }
}

sub _update_deletions_values {
    my ( $plugin, $new_conf, $import_id ) = @_;

    my $rules_table   = $plugin->{deletions_rules_table};
    my $fields_table  = $plugin->{deletions_fields_table};
    my $rule_existing = GetFirstFromTable( $rules_table, { import_id => $import_id } );

    if ($rule_existing) {
        my $mapping_existing = GetFirstFromTable( $fields_table, { rule_id => $rule_existing->{id} } );
        Delete( $rules_table, { import_id => $import_id } );
        if ($mapping_existing) {
            Delete( $fields_table, { rule_id => $rule_existing->{id} } );
        }
    }
    if ( exists $new_conf->{'deletions'} && ref( $new_conf->{'deletions'} ) eq 'ARRAY' ) {
        foreach my $rule ( @{ $new_conf->{'deletions'} } ) {
            my $id = InsertInTable( $rules_table, { 'name' => $rule->{rule_name}, 'import_id' => $import_id } );
            foreach my $koha_field ( keys %{ $rule->{fields} } ) {
                my $field_params = {
                    'rule_id' => $id,
                    'field'   => $koha_field,
                    'value'   => $rule->{fields}{$koha_field},
                };
                InsertInTable( $fields_table, $field_params );
            }
        }
    }
}

sub _update_extendedattributes_values {
    my ( $datatable, $new_conf, $import_id ) = @_;
    my $existing = GetFirstFromTable( $datatable, { import_id => $import_id } );

    if ( exists $new_conf->{'extendedattributes'} && ref( $new_conf->{'extendedattributes'} ) eq 'HASH' ) {
        if ($existing) {
            Delete( $datatable, { import_id => $import_id } );
        }
        foreach my $code ( keys %{ $new_conf->{'extendedattributes'} } ) {
            my $attribute = $new_conf->{'extendedattributes'}{$code};
            $attribute->{'import_id'} = $import_id;

            InsertInTable( $datatable, $attribute );
        }
    }
}

1;
