package Koha::Plugin::Com::Biblibre::PatronImport::Controller::History;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';
use Koha::Plugin::Com::Biblibre::PatronImport::Helper::SQL qw( :DEFAULT );

sub by_run {
    my $c = shift->openapi->valid_input or return;

    my $run_id = $c->validation->param('run_id');
    my $plugin = Koha::Plugin::Com::Biblibre::PatronImport->new();

    my $history = GetFromTable( $plugin->{patrons_history_table}, { run_id => $run_id } );

    unless ($history) {
        return $c->render( status => 404, openapi => { error => "History not found." } );
    }

    return $c->render( status => 200, openapi => $history );
}

return 1;
