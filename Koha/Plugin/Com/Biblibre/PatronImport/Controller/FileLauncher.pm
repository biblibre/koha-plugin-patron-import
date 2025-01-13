package Koha::Plugin::Com::Biblibre::PatronImport::Controller::FileLauncher;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

sub run_import {
    my $c = shift->openapi->valid_input or return;

    my $import_id = $c->validation->param('import_id');
    my $body      = $c->req->json;

    my $logs_options = $body->{logs_options} || [];
    my $dry_run      = $body->{run_as_test};
    my $file         = $body->{file};

    my $info_logs    = grep { $_ eq 'info' } @$logs_options;
    my $success_logs = grep { $_ eq 'success' } @$logs_options;
    my $debug_logs   = grep { $_ eq 'debug' } @$logs_options;

    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new(
        {
            enable_plugins => 1,
            import_id      => $import_id,
            from           => $file,
            dry_run        => $dry_run,
            info_logs      => $info_logs    ? 1 : 0,
            success_log    => $success_logs ? 1 : 0,
            debug          => $debug_logs   ? 1 : 0,
        }
    );

    $plugin->run_import();

    return $c->render(
        status  => 201,
        openapi => { message => "Import launched successfully" }
    );
}

return 1;
