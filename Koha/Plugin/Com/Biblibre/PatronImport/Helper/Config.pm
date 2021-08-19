package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;

use Modern::Perl;
use Exporter;
use YAML;
use JSON;
use C4::Context;
use DateTime;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

our @ISA = qw(Exporter);
our @EXPORT = qw(get_conf);

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

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new({
        enable_plugins  => 1,
    });

    $tables->{import_table} = $plugin->{import_table};
    $tables->{field_mappings_table} = $plugin->{field_mappings_table};
    $tables->{value_mappings_table} = $plugin->{value_mappings_table};
    $tables->{transformation_plugins_table} = $plugin->{transformation_plugins_table};
    $tables->{matching_points_table} = $plugin->{matching_points_table};
    $tables->{protected_table} = $plugin->{protected_table};
    $tables->{erasables_table} = $plugin->{erasables_table};
    $tables->{default_values_table} = $plugin->{default_values_table};
    $tables->{debarments_table} = $plugin->{debarments_table};
    $tables->{exclusions_rules_table} = $plugin->{exclusions_rules_table};
    $tables->{exclusions_fields_table} = $plugin->{exclusions_fields_table};
    $tables->{deletions_rules_table} = $plugin->{deletions_rules_table};
    $tables->{deletions_fields_table} = $plugin->{deletions_fields_table};

    my $conf;
    my ( $setup, $import_settings) = _load_setup($import_id);
    $conf->{setup} = $setup;
    $conf->{createonly} = $import_settings->{createonly} || 0;
    $conf->{autocardnumber} = $import_settings->{autocardnumber} || 'no';
    $conf->{clear_logs} = $import_settings->{clear_logs} || 5;

    $conf->{map} = _load_field_mappings($import_id);
    $conf->{valuesmapping} = _load_value_mappings($import_id);
    $conf->{transformationplugins} = _load_transformation_plugins($import_id);
    $conf->{matchingpoint} = _load_matching_points($import_id);
    $conf->{default} = _load_default($import_id);
    $conf->{protected} = _load_protected($import_id);
    $conf->{erasable} = _load_erasables($import_id);
    $conf->{debarments} = _load_debarments($import_id);
    $conf->{exclusions} = _load_exclusions($import_id);
    $conf->{deletions} = _load_deletions($import_id);

    return $conf;
}

sub _load_field_mappings {
    my $import_id = shift;

    my $values = _get_table_values($tables->{field_mappings_table}, $import_id);
    my $mappings;
    foreach my $m ( @$values ) {
        my $source = $m->{source};
        my $dest = $m->{destination};

        if ( defined( $mappings->{$source} ) ) {
            if ( ref($mappings->{$source}) eq 'ARRAY' ) {
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

    my $values = _get_table_values($tables->{value_mappings_table}, $import_id);
    my $mappings;
    foreach my $m ( @$values ) {
        my $dest = $m->{destination};
        my $input = $m->{input};
        my $output = $m->{output};

        $mappings->{$dest}{$input} = $output;
    }

    return $mappings;
}

sub _load_transformation_plugins {
    my $import_id = shift;

    my $values = _get_table_values($tables->{transformation_plugins_table}, $import_id);
    my $tr_plugins;
    foreach my $p ( @$values ) {
        my $dest = $p->{destination};
        my $name = $p->{transformation_plugin};
        push @{ $tr_plugins->{$dest} }, $name;
    }

    return $tr_plugins;
}

sub _load_matching_points {
    my $import_id = shift;

    my $values = _get_table_values($tables->{matching_points_table}, $import_id);
    my @matchingpoints = map { $_->{field} } @$values;

    return \@matchingpoints;
}

sub _load_default {
    my $import_id = shift;

    my $default;
    my $values = _get_table_values($tables->{default_values_table}, $import_id);
    foreach my $v ( @$values ) {
        $default->{ $v->{koha_field} } = $v->{value};
    }

    return $default;
}

sub _load_setup {
    my $import_id = shift;

    my $setup = {};
    my $table = $tables->{import_table};
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE id = ?");
    $sth->execute($import_id);

    my $values = $sth->fetchrow_hashref;
    my $settings = from_json($values->{flow_settings});

    if ( $values->{type} eq 'file-csv' ) {
        $settings = Koha::Plugin::Com::Biblibre::PatronImport::Helper::CSVConfig::FormatSettings($settings);
    }

    $setup->{ $values->{type} } = $settings;
    $setup->{'flow-type'} = $values->{type};

    return ($setup, $values);
}

sub  _load_protected {
    my $import_id = shift;
    my $table = $tables->{protected_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT field FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my $protected = [];
    while (my ($field) = $sth->fetchrow_array()) {
        push @$protected, $field;
    }

    return $protected;
}

sub  _load_erasables {
    my $import_id = shift;
    my $table = $tables->{erasables_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT field FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my $protected = [];
    while (my ($field) = $sth->fetchrow_array()) {
        push @$protected, $field;
    }

    return $protected;
}

sub _load_debarments {
    my $import_id = shift;
    my $table = $tables->{debarments_table};

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE import_id = ?");
    $sth->execute($import_id);

    my $values = $sth->fetchrow_hashref;

    if ( $values->{unlimited} ) {
        $values->{expiration} = '9999-12-01';
        return $values;
    }

    if ( $values->{days} ) {
        my $today = DateTime->now(time_zone=>'local');
        $today->add( days => $values->{days} );
        $values->{expiration} = $today->ymd;
    }

    return $values;
}

sub _load_exclusions {
    my $import_id = shift;
    my $rules_table = $tables->{exclusions_rules_table};
    my $fields_table = $tables->{exclusions_fields_table};

    my $exclusions_rules;

    my $rules = GetFromTable($rules_table, { import_id => $import_id});
    foreach my $rule (@$rules) {
        my $fields = GetFromTable($fields_table, { rule_id => $rule->{id}});
        if ($fields) {
            my $mappings = {
                origin => $rule->{origin},
                fields => {}
            };
            $mappings->{origin} = $rule->{origin};
            foreach my $field ( @$fields ) {
                $mappings->{fields}->{$field->{koha_field}} = $field->{value};
            }
            push(@{ $exclusions_rules }, $mappings);
        }
    }
    return $exclusions_rules;
}

sub _load_deletions {
    my $import_id = shift;
    my $rules_table = $tables->{deletions_rules_table};
    my $fields_table = $tables->{deletions_fields_table};

    my $deletions_rules;

    my $rules = GetFromTable($rules_table, { import_id => $import_id});
    foreach my $rule (@$rules) {
        my $fields = GetFromTable($fields_table, { rule_id => $rule->{id}});
        if ($fields) {
            my $mappings = {
                fields => {}
            };
            foreach my $field ( @$fields ) {
                $mappings->{fields}->{$field->{field}} = $field->{value};
            }
            push(@{ $deletions_rules }, $mappings);
        }
    }
    return $deletions_rules;
}

sub _get_table_values {
    my ($table, $import_id) = @_;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE import_id = ?");
    $sth->execute($import_id);
    my @values;
    while ( my $v = $sth->fetchrow_hashref ) {
        push @values, $v
    }

    return \@values;
}


1;
