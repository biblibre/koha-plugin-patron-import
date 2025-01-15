package Koha::Plugin::Com::Biblibre::PatronImport;

use Modern::Perl;

use C4::Context;
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Mojo::JSON qw(decode_json);;

use base qw(Koha::Plugins::Base);


our $VERSION = '3.0';

our $metadata = {
    name => 'Patron import',
    author => 'Alex Arnaud <alex.arnaud@biblibre.com>',
    description => 'A tool for importing patrons into Koha',
    date_authored => '2019-07-02',
    date_updated => '2024-12-24',
    minimum_version => '22.11',
    maximum_version => '',
    version => $VERSION,
};

sub new {
    my ($class, $args) = @_;

    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;

    my $self = $class->SUPER::new($args);

    $self->{import_table}  = $self->get_qualified_table_name('import');
    $self->{runs_table}  = $self->get_qualified_table_name('runs');
    $self->{run_stats_table}  = $self->get_qualified_table_name('run_stats');
    $self->{run_logs_table}  = $self->get_qualified_table_name('run_logs');
    $self->{field_mappings_table}  = $self->get_qualified_table_name('field_mappings');
    $self->{value_mappings_table}  = $self->get_qualified_table_name('value_mappings');
    $self->{value_mappings_default_table}  = $self->get_qualified_table_name('value_mappings_default');
    $self->{transformation_plugins_table}  = $self->get_qualified_table_name('transformation_plugins');
    $self->{matching_points_table}  = $self->get_qualified_table_name('matching_points');
    $self->{protected_table}  = $self->get_qualified_table_name('protected');
    $self->{erasables_table}  = $self->get_qualified_table_name('erasables');
    $self->{default_values_table}  = $self->get_qualified_table_name('default_values');
    $self->{debarments_table} = $self->get_qualified_table_name('debarments');
    $self->{exclusions_rules_table} = $self->get_qualified_table_name('exclusions_rules');
    $self->{exclusions_fields_table} = $self->get_qualified_table_name('exclusions_fields');
    $self->{deletions_rules_table} = $self->get_qualified_table_name('deletions_rules');
    $self->{deletions_fields_table} = $self->get_qualified_table_name('deletions_fields');
    $self->{extended_attributes_table} = $self->get_qualified_table_name('extended_attributes');
    $self->{patrons_history_table} = $self->get_qualified_table_name('patrons_history');

    # Used by PatronImport/cron/run-import.pl
    if ( $args->{import_id} ) {
        use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;
        use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Logger;
        use Koha::Plugin::Com::Biblibre::PatronImport::Source;

        my $import_id = $args->{import_id};
        my $filename = $args->{from};
        Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config::load_conf($import_id);
        my $config = get_conf();
        $config->{info_logs} = $args->{info_logs};
        $config->{success_log} = $args->{success_log};
        $config->{debug} = $args->{debug};
        $config->{dry_run} = $args->{dry_run};

        my $logger = Koha::Plugin::Com::Biblibre::PatronImport::Helper::Logger
            ->new($import_id, $filename, $config);

        my $history = Koha::Plugin::Com::Biblibre::PatronImport::Helper::History
            ->new($logger);
        $self->{id} = $import_id;
        $self->{from} = $args->{from};
        $self->{'dry-run'} = $args->{dry_run};
        $self->{'debug'} = $args->{debug};
        $self->{config} = $config;
        $self->{logger} = $logger;
        $self->{history} = $history;
    }

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Index;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Index::index($self, $args);
}

sub editimport {
    my ( $self, $args ) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import::edit($self, $args);
}

sub deleteimport {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Import::delete($self, $args);
}

sub configexport {
    my ($self, $args) = @_;  

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::ConfigHandler;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::ConfigHandler::configexport($self, $args);
}
sub configapply {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::ConfigHandler;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::ConfigHandler::configapply($self, $args);
}

sub editfieldmappings {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings::edit($self, $args);
}

sub editvaluemappings {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings::editvalues($self, $args);
}

sub edittransformationplugins {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings::edittransformationplugins($self, $args);
}

sub editprotected {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::FieldMappings::editprotected($self, $args);
}

sub editdefault {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::DefaultValues;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::DefaultValues::edit($self, $args);
}

sub showruns {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs::index($self, $args);
}

sub rundetails {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs::details($self, $args);
}

sub runlogs {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs::logs($self, $args);
}

sub rundelete {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs::delete($self, $args);
}

sub rundeletebatch {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Runs::batchdelete($self, $args);
}

sub editdebarments {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Debarments;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Debarments::edit($self, $args);
}

sub editexclusions {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Exclusions;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Exclusions::edit($self, $args);
}

sub editdeletions {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::Deletions;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::Deletions::edit($self, $args);
}

sub extendedattributes {
    my ($self, $args) = @_;

    use Koha::Plugin::Com::Biblibre::PatronImport::Controller::ExtendedAttributes;
    Koha::Plugin::Com::Biblibre::PatronImport::Controller::ExtendedAttributes::edit($self, $args);
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_dir = $self->mbf_dir();

    my $schema = JSON::Validator::Schema::OpenAPIv2->new;
    my $spec = $schema->resolve($spec_dir . '/openapi.yaml');
    return $self->_convert_refs_to_absolute($spec->data->{'paths'}, 'file://' . $spec_dir . '/');
}

sub api_namespace {
    my ( $self ) = @_;
    
    return 'patron-import';
}

sub install {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;

    my $import_table = $self->get_qualified_table_name('import');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $import_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            name varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            type varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            createonly tinyint COLLATE utf8_unicode_ci NULL,
            autocardnumber varchar(20) COLLATE utf8_unicode_ci NULL,
            welcome_message tinyint COLLATE utf8_unicode_ci NULL,
            clear_logs INT(5) COLLATE utf8_unicode_ci NULL,
            flow_settings text COLLATE utf8_unicode_ci NULL,
            plugins_enabled text COLLATE utf8_unicode_ci NULL,
            created_on datetime NOT NULL,
            last_run datetime NOT NULL,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $runs_table = $self->get_qualified_table_name('runs');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $runs_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            import_id int(11) NOT NULL,
            start datetime NOT NULL,
            end datetime NULL,
            new int(11) NOT NULL,
            updated int(11) NOT NULL,
            deleted int(11) NOT NULL,
            skipped int(11) NOT NULL,
            error int(11) NOT NULL,
            dry_run int(1) NOT NULL DEFAULT 0,
            filename varchar(255) NULL,
            PRIMARY KEY (id),
            CONSTRAINT runs_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $run_stats_table = $self->get_qualified_table_name('run_stats');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $run_stats_table (
            run_id int(11) NOT NULL,
            field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            count int(11) NOT NULL,
            PRIMARY KEY (run_id, field, value),
            CONSTRAINT run_stats_fk_1 FOREIGN KEY (run_id) REFERENCES $runs_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $run_logs_table = $self->get_qualified_table_name('run_logs');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $run_logs_table (
            run_id int(11) NOT NULL,
            time datetime NOT NULL,
            reason varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            message varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            borrowernumber int(11) NULL,
            userid varchar(75) NULL,
            cardnumber varchar(32) NULL,
            surname longtext NULL,
            firstname mediumtext NULL,
            CONSTRAINT run_logs_fk_1 FOREIGN KEY (run_id) REFERENCES $runs_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $field_mappings_table = $self->get_qualified_table_name('field_mappings');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $field_mappings_table (
            import_id int(11) NOT NULL,
            source varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, source, destination),
            CONSTRAINT import_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $matching_points_table = $self->get_qualified_table_name('matching_points');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $matching_points_table (
            import_id int(11) NOT NULL,
            field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, field),
            CONSTRAINT import_match_points_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $value_mappings_table = $self->get_qualified_table_name('value_mappings');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $value_mappings_table (
            import_id int(11) NOT NULL,
            destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            input varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            output varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            operator varchar(55) COLLATE utf8_unicode_ci NULL,
            PRIMARY KEY (import_id, destination, input),
            CONSTRAINT field_mapping_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $value_mappings_default_table = $self->get_qualified_table_name('value_mappings_default');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $value_mappings_default_table (
            import_id int(11) NOT NULL,
            destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            default_value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, destination),
            CONSTRAINT field_mapping_default_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $transformation_plugins_table = $self->get_qualified_table_name('transformation_plugins');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $transformation_plugins_table (
            import_id int(11) NOT NULL,
            destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            transformation_plugin varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, destination, transformation_plugin),
            CONSTRAINT transformation_plugins_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $protected_table = $self->get_qualified_table_name('protected');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $protected_table (
            import_id int(11) NOT NULL,
            field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, field),
            CONSTRAINT import_protected_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $erasables_table = $self->get_qualified_table_name('erasables');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $erasables_table (
            import_id int(11) NOT NULL,
            field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, field),
            CONSTRAINT import_erasables_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $default_values_table = $self->get_qualified_table_name('default_values');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $default_values_table (
            import_id int(11) NOT NULL,
            koha_field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, koha_field),
            CONSTRAINT import_default_values_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $exclusions_table = $self->get_qualified_table_name('exclusions_rules');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $exclusions_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            import_id int(11) NOT NULL,
            name varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            origin ENUM('ext', 'koha') COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (id),
            CONSTRAINT import_exclusions_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $exclusions_fields_table = $self->get_qualified_table_name('exclusions_fields');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $exclusions_fields_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            rule_id int(11) NOT NULL,
            koha_field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (id),
            CONSTRAINT import_exclusions_fields_fk_1 FOREIGN KEY (rule_id) REFERENCES $exclusions_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $deletions_table = $self->get_qualified_table_name('deletions_rules');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $deletions_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            import_id int(11) NOT NULL,
            name varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (id),
            CONSTRAINT import_deletions_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $deletions_fields_table = $self->get_qualified_table_name('deletions_fields');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $deletions_fields_table (
            id int(11) NOT NULL AUTO_INCREMENT,
            rule_id int(11) NOT NULL,
            field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (id),
            CONSTRAINT import_deletions_fields_fk_1 FOREIGN KEY (rule_id) REFERENCES $deletions_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $debarments_table = $self->get_qualified_table_name('debarments');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $debarments_table (
            import_id int(11) NOT NULL,
            suspend tinyint COLLATE utf8_unicode_ci NOT NULL,
            comment varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            days int(5) COLLATE utf8_unicode_ci NULL,
            unlimited tinyint COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id),
            CONSTRAINT import_debarments_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $extended_attributes_table = $self->get_qualified_table_name('extended_attributes');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $extended_attributes_table (
            import_id int(11) NOT NULL,
            code varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            behaviour_one_value varchar(55) COLLATE utf8_unicode_ci NOT NULL,
            behaviour_many_values varchar(55) COLLATE utf8_unicode_ci NULL,
            repeatable tinyint COLLATE utf8_unicode_ci NOT NULL,
            CONSTRAINT import_extended_attributes_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    my $patrons_history_table = $self->get_qualified_table_name('patrons_history');
    $dbh->do("
        CREATE TABLE IF NOT EXISTS $patrons_history_table (
            run_id int(11) NULL,
            borrowernumber int(11) NOT NULL,
            action varchar(25) NOT NULL,
            action_date datetime NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $DBversion = $self->retrieve_data('__INSTALLED_VERSION__');    

    my $dbh = C4::Context->dbh;
    my $import_table = $self->get_qualified_table_name('import');
    my $transformation_plugins_table = $self->get_qualified_table_name('transformation_plugins');

    $dbh->do("
        CREATE TABLE IF NOT EXISTS $transformation_plugins_table (
            import_id int(11) NOT NULL,
            destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            transformation_plugin varchar(255) COLLATE utf8_unicode_ci NOT NULL,
            PRIMARY KEY (import_id, destination, transformation_plugin),
            CONSTRAINT transformation_plugins_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    ");

    if ($DBversion < '1.2') {
        my $dbh = C4::Context->dbh;
        $dbh->do("ALTER TABLE $import_table ADD COLUMN clear_logs INT(5) AFTER autocardnumber;");
    }

    if ($DBversion < '1.3') {
        my $exclusions_table = $self->get_qualified_table_name('exclusions_rules');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $exclusions_table (
                id int(11) NOT NULL AUTO_INCREMENT,
                import_id int(11) NOT NULL,
                name varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                PRIMARY KEY (id),
                CONSTRAINT import_exclusions_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");

        my $exclusions_fields_table = $self->get_qualified_table_name('exclusions_fields');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $exclusions_fields_table (
                id int(11) NOT NULL AUTO_INCREMENT,
                rule_id int(11) NOT NULL,
                koha_field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                PRIMARY KEY (id),
                CONSTRAINT import_exclusions_fields_fk_1 FOREIGN KEY (rule_id) REFERENCES $exclusions_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");

    }

    if ($DBversion < '1.4') {
        my $exclusions_table = $self->get_qualified_table_name('exclusions_rules');
        $dbh->do("ALTER TABLE $exclusions_table ADD COLUMN origin ENUM('ext', 'koha') NOT NULL AFTER name;");
    }

    if ($DBversion < '1.5') {
        my $runs_table = $self->get_qualified_table_name('runs');
        my $deletions_table = $self->get_qualified_table_name('deletions_rules');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $deletions_table (
                id int(11) NOT NULL AUTO_INCREMENT,
                import_id int(11) NOT NULL,
                name varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                PRIMARY KEY (id),
                CONSTRAINT import_deletions_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");

        my $deletions_fields_table = $self->get_qualified_table_name('deletions_fields');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $deletions_fields_table (
                id int(11) NOT NULL AUTO_INCREMENT,
                rule_id int(11) NOT NULL,
                field varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                PRIMARY KEY (id),
                CONSTRAINT import_deletions_fields_fk_1 FOREIGN KEY (rule_id) REFERENCES $deletions_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");

        $dbh->do("ALTER TABLE $runs_table ADD COLUMN deleted INT(11) NOT NULL AFTER updated;");
    }

    if ($DBversion < '1.6') {
        $dbh->do("ALTER TABLE $import_table ADD COLUMN plugins_enabled text COLLATE utf8_unicode_ci  NULL AFTER flow_settings;");
    }


    if ($DBversion < '1.7') {
        my $extended_attributes_table = $self->get_qualified_table_name('extended_attributes');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $extended_attributes_table (
                import_id int(11) NOT NULL,
                code varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                behaviour_one_value varchar(55) COLLATE utf8_unicode_ci NOT NULL,
                behaviour_many_values varchar(55) COLLATE utf8_unicode_ci NULL,
                repeatable tinyint COLLATE utf8_unicode_ci NOT NULL,
                CONSTRAINT import_extended_attributes_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");
    }

    if ($DBversion < '1.8') {
        my $value_mappings_table = $self->get_qualified_table_name('value_mappings');
        $dbh->do("ALTER TABLE $value_mappings_table ADD COLUMN operator varchar(55) COLLATE utf8_unicode_ci NULL AFTER output;");
    }

    if ($DBversion < '1.9') {
        my $value_mappings_default_table = $self->get_qualified_table_name('value_mappings_default');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $value_mappings_default_table (
                import_id int(11) NOT NULL,
                destination varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                default_value varchar(255) COLLATE utf8_unicode_ci NOT NULL,
                PRIMARY KEY (import_id, destination),
                CONSTRAINT field_mapping_default_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");
    }
    
    if ( Koha::Plugins::Base::_version_compare($DBversion, '1.91') == -1 ) {
        my $runs_table = $self->get_qualified_table_name('runs');
        $dbh->do("ALTER TABLE $runs_table ADD COLUMN dry_run int(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 0 AFTER error;");
    }

    if ($DBversion < '2.0') {
        my $patrons_history_table = $self->get_qualified_table_name('patrons_history');
        $dbh->do("
            CREATE TABLE IF NOT EXISTS $patrons_history_table (
                run_id int(11) NULL,
                borrowernumber int(11) NOT NULL,
                action varchar(25) NOT NULL,
                action_date datetime NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
        ");
    }

    if ($DBversion < '2.1') {
        my $import_table = $self->get_qualified_table_name('import');
        $dbh->do("ALTER TABLE $import_table ADD COLUMN welcome_message tinyint COLLATE utf8_unicode_ci NULL;");
    }

    if ($DBversion < '2.2') {
        my $runs_table = $self->get_qualified_table_name('runs');
        unless (_column_exists($dbh, $runs_table, 'dry_run')) {
            $dbh->do("ALTER TABLE $runs_table ADD COLUMN dry_run int(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT 0 AFTER error;");
        }
    }
    
    if ($DBversion < '3.0') {
        my $runs_table = $self->get_qualified_table_name('runs');
        $dbh->do("ALTER TABLE $runs_table ADD COLUMN filename varchar(255) COLLATE utf8_unicode_ci NULL;");
    }

    $self->store_data({'__INSTALLED_VERSION__' => $VERSION});

    return 1;
}

sub uninstall {
    my ( $self, $args ) = @_;

    my $dbh = C4::Context->dbh;

    my $import_table = $self->get_qualified_table_name('import');
    C4::Context->dbh->do("DROP TABLE $import_table");

    my $runs_table = $self->get_qualified_table_name('runs');
    C4::Context->dbh->do("DROP TABLE $runs_table");

    my $run_stats_table = $self->get_qualified_table_name('run_stats');
    C4::Context->dbh->do("DROP TABLE $run_stats_table");

    my $run_logs_table = $self->get_qualified_table_name('run_logs');
    C4::Context->dbh->do("DROP TABLE $run_logs_table");

    my $field_mappings_table = $self->get_qualified_table_name('field_mappings');
    C4::Context->dbh->do("DROP TABLE $field_mappings_table");

    my $matching_points_table = $self->get_qualified_table_name('matching_points');
    C4::Context->dbh->do("DROP TABLE $matching_points_table");

    my $value_mappings_table = $self->get_qualified_table_name('value_mappings');
    C4::Context->dbh->do("DROP TABLE $value_mappings_table");

    my $transformation_plugins_table = $self->get_qualified_table_name('transformation_plugins');
    C4::Context->dbh->do("DROP TABLE $transformation_plugins_table");

    my $protected_table = $self->get_qualified_table_name('protected');
    C4::Context->dbh->do("DROP TABLE $protected_table");

    my $erasables_table = $self->get_qualified_table_name('erasables');
    C4::Context->dbh->do("DROP TABLE $erasables_table");

    my $default_values_table = $self->get_qualified_table_name('default_values');
    C4::Context->dbh->do("DROP TABLE $default_values_table");

    my $debarments_table = $self->get_qualified_table_name('debarments');
    C4::Context->dbh->do("DROP TABLE $debarments_table");
}

sub run_import {
    my ( $self ) = @_;

    $self->{logger}->InitRun();

    $self->_disable_borrowers_logs;

    my $source = Koha::Plugin::Com::Biblibre::PatronImport::Source->new( $self );
    if (my $error = $source->{in}{unable_to_run}) {
        $self->{logger}->Add('error', "Unable to run this import: $error");
    }

    while ( my $borrower = $source->next ) {
        $borrower->to_koha($self);

        if ( $self->{debug} ) {
            print "Patron for Koha:\n";
            warn $borrower->as_text;
            print "===========================================\n";
        }

        $self->{logger}->Extractstats( $borrower );
    }

    $self->_enable_borrowers_logs;

    $self->{logger}->Stop;
}

sub _disable_borrowers_logs {
    my ( $self ) = @_;

    $self->{BorrowersLog} = C4::Context->preference('BorrowersLog');

    C4::Context->set_preference( 'BorrowersLog', 0 );
}

sub _enable_borrowers_logs {
    my ( $self ) = @_;

    C4::Context->set_preference( 'BorrowersLog', $self->{BorrowersLog} );
}

sub _convert_refs_to_absolute {
    my ( $self, $hashref, $path_prefix ) = @_;

    foreach my $key (keys %{ $hashref }) {
        if ($key eq '$ref') {
            if ($hashref->{$key} =~ /^(\.\/)?openapi/) {
                $hashref->{$key} = $path_prefix . $hashref->{$key};
            }
        } elsif (ref $hashref->{$key} eq 'HASH' ) {
            $hashref->{$key} = $self->_convert_refs_to_absolute($hashref->{$key}, $path_prefix);
        } elsif (ref($hashref->{$key}) eq 'ARRAY') {
            $hashref->{$key} = $self->_convert_array_refs_to_absolute($hashref->{$key}, $path_prefix);
        }
    }
    return $hashref;
}

sub _convert_array_refs_to_absolute {
    my ( $self, $arrayref, $path_prefix ) = @_;

    my @res;
    foreach my $item (@{ $arrayref }) {
        if (ref($item) eq 'HASH') {
            $item = $self->_convert_refs_to_absolute($item, $path_prefix);
        } elsif (ref($item) eq 'ARRAY') {
            $item = $self->_convert_array_refs_to_absolute($item, $path_prefix);
        }
        push @res, $item;
    }
    return \@res;
}

sub _column_exists {
    my ( $dbh, $table, $column ) = @_;
    my $sth = $dbh->prepare("SHOW COLUMNS FROM $table LIKE ?");
    $sth->execute($column);
    return $sth->fetchrow_arrayref ? 1 : 0;
}

1;