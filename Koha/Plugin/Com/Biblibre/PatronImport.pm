package Koha::Plugin::Com::Biblibre::PatronImport;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

use base qw(Koha::Plugins::Base);


our $VERSION = '1.0';

our $metadata = {
    name => 'Patron import',
    author => 'Alex Arnaud <alex.arnaud@biblibre.com>',
    description => 'A tool for importing patrons into Koha',
    date_authored => '2019-01-26',
    date_updated => '2019-01-26',
    minimum_version => '18.05.00.000',
    maximum_version => undef,
    version => $VERSION,
};

sub new {
    my ($class, $args) = @_;

    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;

    my $self = $class->SUPER::new($args);

    $self->{import_table}  = $self->get_qualified_table_name('import');
    $self->{runs_table}  = $self->get_qualified_table_name('runs');

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template({ file => 'templates/index/index.tt' });

    my $imports = GetFromTable($self->{import_table});
    foreach my $i (@$imports) {
        my $dbh = C4::Context->dbh;

        my $query = "SELECT id, start, end FROM $self->{runs_table}
            WHERE import_id = ?
            AND end = (SELECT MAX(end) FROM $self->{runs_table} WHERE import_id = ?)";
        my $sth = $dbh->prepare($query);
        $sth->execute($i->{id}, $i->{id}) or die $sth->errstr;

        my $run = $sth->fetchrow_hashref;

        $i->{last_run} = 'No run yet';
        if ( $run->{end} ) {
            $i->{last_run} = $run->{start};
            $i->{last_run_id} = $run->{id};
        }
    }
    $template->param(imports => $imports);

    print $cgi->header();
    print $template->output();

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
            flow_settings text COLLATE utf8_unicode_ci NULL,
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
            skipped int(11) NOT NULL,
            error int(11) NOT NULL,
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
            PRIMARY KEY (import_id, destination, input),
            CONSTRAINT field_mapping_fk_1 FOREIGN KEY (import_id) REFERENCES $import_table (id) ON DELETE CASCADE ON UPDATE CASCADE
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
}

1;
