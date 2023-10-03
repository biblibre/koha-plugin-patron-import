package Koha::Plugin::Com::Biblibre::PatronImport::Controller::ConfigHandler;

use Modern::Perl;
use YAML::XS qw(Dump LoadFile);

use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config;

sub configexport {
    my ( $plugin, $params ) = @_;
    my $cgi         = $plugin->{'cgi'};
    my $import_id   = $cgi->param('import_id');
    my $export_name = $cgi->param('export_name');

    Koha::Plugin::Com::Biblibre::PatronImport::Helper::Config::load_conf($import_id);
    my $config = get_conf();

    print $cgi->header(
        -type       => 'application/x-yaml',
        -attachment => "$export_name.yaml"
    );

    print Dump($config);
}

sub configapply {
    my ( $plugin, $params ) = @_;
    my $cgi          = $plugin->{'cgi'};
    my $op           = $cgi->param('op');
    my $import_id    = $cgi->param('import_id');
    my $export_name  = $cgi->param('import_name');
    my $file_handle  = $cgi->upload('configuration_file');
    my $tmp_filename = $cgi->tmpFileName($file_handle);
    my $new_conf     = LoadFile($tmp_filename);

    if ( defined($op) ) {
        my $now        = DateTime->now();
        my $created_on = $now->ymd() . ' ' . $now->hms;
        $import_id = InsertInTable( $plugin->{import_table}, { name => $export_name, created_on => $created_on } );
    }

    set_conf( $new_conf, $import_id );

    print $cgi->redirect('/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ACom%3A%3ABiblibre%3A%3APatronImport&method=configure');
    return;

}

1;
