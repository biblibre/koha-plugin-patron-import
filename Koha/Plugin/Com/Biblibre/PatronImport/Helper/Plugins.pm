package Koha::Plugin::Com::Biblibre::PatronImport::Helper::Plugins;

use Modern::Perl;
use Koha::Plugins;

sub callPlugins {
    my ($method, $args) = @_;

    my @args = ();
    if (ref($args) ne 'ARRAY') {
        push @args, $args;
    }
    else {
        @args = @{ $args };
    }

    my @plugins = Koha::Plugins->new()->GetPlugins({
        method => $method,
    });

    foreach my $plugin ( @plugins ) {
        $plugin->$method(@args);
    }
}

1;
