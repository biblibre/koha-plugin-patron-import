package Koha::Plugin::Com::Biblibre::PatronImport::Controller::Index;

use Modern::Perl;

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

sub index {
    my ( $plugin, $args ) = @_;
    my $cgi = $plugin->{'cgi'};

    my $template = $plugin->get_template({ file => 'templates/index/index.tt' });

    my $imports = GetFromTable($plugin->{import_table});
    foreach my $i (@$imports) {
        my $dbh = C4::Context->dbh;

        my $query = "SELECT id, start, end FROM $plugin->{runs_table}
            WHERE import_id = ?
            AND end = (SELECT MAX(end) FROM $plugin->{runs_table} WHERE import_id = ?)";
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

    print $cgi->header(-type => 'text/html', -charset => 'UTF-8', -encoding => 'UTF-8');
    print $template->output();
}

1;
